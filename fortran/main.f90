module compat_bindings
    use iso_c_binding
    implicit none

    interface
        subroutine init() bind(c)
        end subroutine

        function step(out_len) bind(c) result(ptr)
            import :: c_ptr, c_size_t
            integer(c_size_t) :: out_len
            type(c_ptr) :: ptr
        end function

        subroutine deinit() bind(c)
        end subroutine

        subroutine memcpy(dest, src, n) bind(c, name="memcpy")
            import :: c_ptr, c_size_t
            type(c_ptr), value :: dest, src
            integer(c_size_t), value :: n
        end subroutine
    end interface
end module

program fib
    use compat_bindings
    use iso_c_binding
    use omp_lib
    implicit none

    ! Init values
    integer(c_size_t) :: limbs_len
    type(c_ptr) :: limbs_ptr

    ! triple 128m bufs for max i/o throughput
    integer, parameter :: BUF_SIZE = 128 * 1024 * 1024
    character(kind=c_char), allocatable, target :: buffers(:,:)
    integer(c_int), target :: ready_flags(0:2)
    integer :: active_buf_idx = 0, current_fill_ptr = 1

    ! benchmarking info
    integer :: i = 0
    integer(8) :: start_tick, end_tick, rate
    real(8) :: elapsed = 0.0
    character(len=1), parameter :: comma = ','
    logical(1), volatile :: t_stop = .false.

    ! final calculations
    ! needed so that the compiler doesn't nag us about type
    integer(8) :: final_size
    real(8) :: size_mb

    print *, "Benchmarking fibonacci calculation performance"
    print *, "Test language: Fortran"

    ! segfault if you don't do this
    allocate(buffers(BUF_SIZE, 0:2))

    ! init zig
    call init()
    ! zero flags
    ready_flags = 0

    !$omp parallel sections num_threads(2)
        ! consumer: writes to disk
        !$omp section
        block
            integer :: consumer_idx = 0
            ! DO NOT CHANGE NAME FROM FD
            ! it looks ugly when not named fd and makes code readability plummet
            integer :: fd
            open(newunit=fd,file='fib.txt',access='stream', status='replace')

            do
                !$omp flush(ready_flags)
                if (ready_flags(consumer_idx) > 0) then
                    ! write the iobuf
                    write(fd) buffers(1:ready_flags(consumer_idx), consumer_idx)

                    !$omp atomic write
                    ready_flags(consumer_idx) = 0

                    ! why did the chicken cross the road?
                    ! to get to the other buffer
                    ! that's the worst joke i have written in years, love it!
                    consumer_idx = mod(consumer_idx + 1, 3)
                else
                    !$omp flush(t_stop)
                    if (t_stop) exit
                end if
            end do
            close(fd)
        end block

        ! producer: does math and writes to buffers
        !$omp section
        block
            call system_clock(start_tick,rate)
            do while (.not. t_stop)
                ! do the math itself
                limbs_ptr = step(limbs_len)

                if (current_fill_ptr + int(limbs_len) + 1 >= BUF_SIZE) then
                    ! atomic for thread safety
                    !$omp atomic write
                    ready_flags(active_buf_idx) = current_fill_ptr - 1
                    !$omp flush(ready_flags)

                    active_buf_idx = mod(active_buf_idx + 1, 3)

                    do while (ready_flags(active_buf_idx) > 0)
                        ! make sure to commit to memory instead of writing to cpu cache
                        ! that way we can actually write stuff
                        !$omp flush(ready_flags)
                    end do
                    current_fill_ptr = 1
                end if

                call memcpy(c_loc(buffers(current_fill_ptr, active_buf_idx)), &
                            limbs_ptr, limbs_len)

                current_fill_ptr = current_fill_ptr + int(limbs_len)
                buffers(current_fill_ptr, active_buf_idx) = comma
                current_fill_ptr = current_fill_ptr + 1

                ! i know this is bad practice but when i tried to make it its own
                ! thread, it refused to work
                i = i + 1
                if (mod(i,1000) == 0) then
                    call system_clock(end_tick)
                    elapsed = real(end_tick-start_tick) / real(rate)
                    if (elapsed >= 5.0) then
                        t_stop = .true.
                        ! more thread-proofing
                        !$omp atomic write
                        ready_flags(active_buf_idx) = current_fill_ptr-1
                        !$omp flush(ready_flags, t_stop)
                    end if
                end if
            end do
        end block
    !$omp end parallel sections

    inquire(file='fib.txt', size=final_size)
    size_mb = real(final_size, 8) / (1024.0 * 1024.0)

    print *, "Test completed in 5s."
    print "(A, F0.2, A)", "Wrote ", size_mb, " MB"
    print "(A, F0.2, A)", "That's ", size_mb / 5.0, "MB/s"

    ! tell zig code to pack up
    call deinit()
end program
