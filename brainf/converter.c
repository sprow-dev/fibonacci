#include <stdio.h>
#include <stdlib.h>

void convert(FILE *in, FILE *out) {
    fprintf(out, "#include <stdio.h>\n#include <stdbool.h>\n\n");
    fprintf(out, "void brainf_logic(volatile char *stop, FILE *f) {\n");
    fprintf(out, "    static unsigned char tape[1048576] = {0};\n");
    fprintf(out, "    static unsigned char write_buf[1048576];\n");
    fprintf(out, "    int buf_idx = 0;\n");
    fprintf(out, "    unsigned char *ptr = tape + 524288;\n\n");

    int c;
    while ((c = fgetc(in)) != EOF) {
        int val, delta;
        switch (c) {
            case 'o':
                if (fscanf(in, "%04x%04x", &val, &delta) == 2)
                    fprintf(out, "    ptr[%d] += %d;\n", (short)val, (short)delta);
            break;
            case '>': fscanf(in, "%04x", &val); fprintf(out, "    ptr += %d;\n", val); break;
            case '<': fscanf(in, "%04x", &val); fprintf(out, "    ptr -= %d;\n", val); break;
            case 'z': fscanf(in, "%04x", &val); fprintf(out, "    *ptr = 0;\n"); break;
            case '.':
                fprintf(out, "    write_buf[buf_idx++] = *ptr;\n");
                fprintf(out, "    if (buf_idx >= 1048576) { fwrite(write_buf, 1, 1048576, f); buf_idx = 0; }\n");
                break;
            case '[': fprintf(out, "    while (*ptr && !*stop) {\n"); break;
            case ']': fprintf(out, "    }\n"); break;
        }
    }
    fprintf(out, "    if (buf_idx > 0) fwrite(write_buf, 1, buf_idx, f);\n");
    fprintf(out, "}\n");
}

int main(int argc, char **argv) {
    FILE *in = fopen(argv[1], "r"), *out = fopen(argv[2], "w");
    if (!in || !out) return 1;
    convert(in, out);
    fclose(in); fclose(out);
    return 0;
}
