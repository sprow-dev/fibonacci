#include <stdio.h>
#include <stdlib.h>

#define MAX_CHANGES 2048

typedef struct {
    int offset;
    int delta;
} Change;

void commit_walk(FILE *out, int *v_ptr, Change *changes, int *num_changes) {
    for (int i = 0; i < *num_changes; i++) {
        if (changes[i].delta != 0) {
            fprintf(out, "o%04x%04x", (unsigned short)changes[i].offset, (unsigned short)changes[i].delta);
        }
    }
    if (*v_ptr != 0) {
        char cmd = (*v_ptr > 0) ? '>' : '<';
        fprintf(out, "%c%04x", cmd, abs(*v_ptr));
    }
    *v_ptr = 0;
    *num_changes = 0;
}

void optimize(FILE *in, FILE *out) {
    int c;
    int v_ptr = 0;
    Change changes[MAX_CHANGES];
    int num_changes = 0;
    int walking = 0;

    while ((c = fgetc(in)) != EOF) {
        if (c == '+' || c == '-' || c == '>' || c == '<') {
            walking = 1;
            if (c == '>') v_ptr++;
            else if (c == '<') v_ptr--;
            else {
                int d = (c == '+') ? 1 : -1;
                int found = 0;
                for (int i = 0; i < num_changes; i++) {
                    if (changes[i].offset == v_ptr) {
                        changes[i].delta += d;
                        found = 1; break;
                    }
                }
                if (!found && num_changes < MAX_CHANGES) {
                    changes[num_changes].offset = v_ptr;
                    changes[num_changes].delta = d;
                    num_changes++;
                }
            }
        }
        else if (c == '[' || c == ']' || c == '.' || c == ',') {
            if (walking) {
                commit_walk(out, &v_ptr, changes, &num_changes);
                walking = 0;
            }

            if (c == '[') {
                long pos = ftell(in);
                if (fgetc(in) == '-' && fgetc(in) == ']') {
                    fprintf(out, "z0000");
                } else {
                    fseek(in, pos, SEEK_SET);
                    fputc('[', out);
                }
            } else {
                fputc(c, out);
            }
        }
    }
    if (walking) commit_walk(out, &v_ptr, changes, &num_changes);
}

int main(int argc, char **argv) {
    if (argc < 3) return 1;
    FILE *in = fopen(argv[1], "r"), *out = fopen(argv[2], "w");
    if (!in || !out) return 1;
    optimize(in, out);
    fclose(in); fclose(out);
    return 0;
}
