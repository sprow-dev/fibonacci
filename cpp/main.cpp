#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <vector>
#include <fstream>
#include <chrono>
#include <atomic>
#include <gmpxx.h>
#include <iomanip>

using namespace std;

/*
 * This struct is the write queue struct.
 * It tells the consumer what data to write to disk.
 * While the producer just tells it to add data.
 */
struct WriteQueue {
  // the queue itself
  queue<vector<unsigned char>> q;
  // the key to the lock
  mutex mtx;
  // the notifier
  condition_variable cv;

  vector<unsigned char> chunk;
  vector<unsigned char> exp_buf;

  void push(vector<unsigned char>&& data) {
      // make a lock for our key
      lock_guard<mutex> lock(mtx);
      // push data to queue
      q.push(std::move(data));
      // say "new data available!"
      cv.notify_one();
  }

  bool pop(vector<unsigned char>& out_data, atomic<bool>& stop) {
      // make a lock to the key that can be unlocked with a bool
      unique_lock<mutex> lock(mtx);

      // wait for data
      cv.wait(lock,[this,&stop] {
          return !q.empty() || stop.load();
      });

      // if there is no more reason to live
      if (q.empty() && stop.load()) {
          // give up and die
          return false;
      }

      // update queue with relevant data
      out_data = std::move(q.front());
      // do the operation we made a full function for
      q.pop();
      // tell the consumer thread(s) to keep going
      return true;
  }

  // This function looks menacing but it makes the producer func manageable.
  void push_bigint(mpz_class& val) {
      if (exp_buf.capacity() < 1024*1024) exp_buf.resize(1024*1024);
      size_t count;
      size_t size = mpz_size(val.get_mpz_t());
      const void* data = mpz_limbs_read(val.get_mpz_t());
      const unsigned char* cast_data = static_cast<const unsigned char*>(data);
      chunk.insert(chunk.end(),
                   cast_data,
                   cast_data+(size * sizeof(mp_limb_t)));

      if (chunk.empty()) chunk.reserve(1024*1024);
      chunk.insert(chunk.end(),exp_buf.data(),exp_buf.data()+count);
      chunk.push_back(',');
      if(chunk.size() >= 1024*1024) {
        {
            lock_guard<mutex> lock(mtx);
            q.push(std::move(chunk));

            // if the queue is too big, the disk needs to finish writing
            if (q.size() > 1000) {
                this_thread::sleep_for(chrono::milliseconds(1));
            }
            cv.notify_one();

            chunk = vector<unsigned char>();
            chunk.reserve(1024*1024);
        }
      }
  }

  void flush_chunk() {
      if (!chunk.empty()) {
        {
          lock_guard<mutex> lock(mtx);
          q.push(std::move(chunk));
          cv.notify_one();
        }
      }
  }
};

// make a new instance of our struct
WriteQueue wq;
atomic<bool> stop_flag(false);

/*
 * Thread worker classes
 * These are designed to be fast, not readable.
 * If you have any questions, then give up
 * and find something better to do than reading this code.
 */

// especially do not bother with this mess
void t_producer() {
    mpz_class a = 0, b = 1, next;
    vector<unsigned char> chunk;
    chunk.reserve(1024*1024);

    while (!stop_flag.load()) {
        // fib math
        next = a+b;
        a = b;
        b = next;

        // push fib int
        wq.push_bigint(b);
    }
}

void t_consumer() {
    // open file in bin mode for speed because str mode is slow
    ofstream file("fib.txt",ios::binary);

    if (!file.is_open()) {
        cerr << "Errror: Could not create file handle." << endl;
        return;
    }

    vector<unsigned char> chunk;

    // write data until there is no data to write.
    while (wq.pop(chunk,stop_flag)) {
        file.write(reinterpret_cast<const char*>(chunk.data()),
                   chunk.size());
    }

    // close file handle gracefully or we can't open it again
    file.close();
}

/*
 * Finally, getting to the point,
 * our benchmarking logic.
 * Immaculately terrible code, I know.
 */
int main() {
    int bench_time_ms = 5000;

    cout << "Benchmarking fibonacci calculation performance" << endl;
    cout << "Test language: C++" << endl;

    thread producer(t_producer);
    thread consumer(t_consumer);

    this_thread::sleep_for(chrono::milliseconds(bench_time_ms));
    stop_flag.store(true);

    wq.cv.notify_all();

    producer.join();
    wq.flush_chunk();
    consumer.join();

    ifstream file("fib.txt",ios::binary|ios::ate);
    streamsize final_size = file.tellg();

    double written_mb = static_cast<double>(final_size) / (1024.0*1024.0);
    double mb_per_sec = written_mb / (bench_time_ms/1000.0);

    cout << "Benchmark completed in " << bench_time_ms << "ms." << endl;
    cout << fixed << setprecision(2);
    cout << "Wrote " << written_mb << "mb" << endl;
    cout << "That's " << mb_per_sec << " MB/s" << endl;

    return 0;
}
