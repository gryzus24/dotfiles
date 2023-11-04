/*
 * cgb - quickly! show me my /CURRENT GIT BRANCH/
 */

#include <asm-generic/fcntl.h> /* O_{RDONLY,O_NOATIME} */
#include <asm/unistd_64.h>
#include <stdbool.h>

#define arr_count(a) (sizeof(a) / sizeof((a)[0]))
#define likely(x) __builtin_expect(!!(x), 1)
#define unlikely(x) __builtin_expect(!!(x), 0)
#define noreturn __attribute__((noreturn))

noreturn void exit(int code)
{
    asm volatile (
        "syscall"
        :
        : "a"(__NR_exit), "D"(code)
        :
    );
    __builtin_unreachable();
}

long syscall_check(unsigned long r)
{
    if (r > -4096UL)
        return -1;
    return r;
}

unsigned long syscall3(long nr, long a, long b, long c)
{
    unsigned long ret;

    asm volatile (
        "syscall"
        : "=a"(ret)
        : "a"(nr), "D"(a), "S"(b), "d"(c)
        : "rcx", "r11", "memory"
    );
    return ret;
}

long read(int fd, char *buf, unsigned long n)
{
    return syscall_check(syscall3(__NR_read, fd, (long)buf, n));
}

long write(int fd, const char *buf, unsigned long n)
{
    return syscall_check(syscall3(__NR_write, fd, (long)buf, n));
}

long open_rdonly(const char *path)
{
    unsigned long ret;

    asm volatile (
        "syscall"
        : "=a"(ret)
        : "a"(__NR_open), "D"(path), "S"(O_RDONLY | O_NOATIME)
        : "rcx", "r11", "memory"
    );
    return syscall_check(ret);
}

long getcwd(char *buf, unsigned long size)
{
    unsigned long ret;

    asm volatile (
        "syscall"
        : "=a"(ret)
        : "a"(__NR_getcwd), "D"(buf), "S"(size)
        : "rcx", "r11", "memory"
    );
    return syscall_check(ret);
}

#define GITHEAD ".git/HEAD"
#define GITHEAD_SIZE 10

#define BRANCH_FOUND 0
#define BRANCH_NOT_FOUND 1
#define GETCWD_ROOT_OR_FAILED 2
#define GITHEAD_READ_FAILED 3

void write_branch_name(char *buf256, int githead_fd)
{
    char *ptr;
    char *const start255 = buf256 + 1;

    /* read into buf:  [0 A A A A A \n 0 0 ...]
     * overwrite with: [( A A A A A  )   0 ...] */
    const long nread = read(githead_fd, start255, 255 - 1);
    if (unlikely(nread < 2 || start255[nread - 1] != '\n'))
        exit(GITHEAD_READ_FAILED);

    ptr = start255 + nread;

    *ptr-- = ' ';
    *ptr-- = ')';
    while (ptr >= start255 && *ptr != '/')
        --ptr;
    *ptr = '(';

    write(1, ptr, start255 + nread - ptr + 1);
}

bool should_check_dir(const char *s, int i)
{
    /* is at root? */
    if (i <= 1)
        return false;

    if (i == 6) {
        return !(
               s[i - 2] == 'e'
            && s[i - 3] == 'm'
            && s[i - 4] == 'o'
            && s[i - 5] == 'h'
        );
    }
    return true;
}

noreturn void _start(void)
{
    char buf[256];
    int i;
    int j;
    long fd;

    /* i stores the index of a path separator + 1 */
    i = getcwd(buf, arr_count(buf) - GITHEAD_SIZE);
    if (unlikely(i < 3 || buf[0] != '/'))
        exit(GETCWD_ROOT_OR_FAILED);

    /* replace '\0' with '/' */
    buf[i - 1] = '/';

    do {
        for (j = 0; j < GITHEAD_SIZE; ++j)
            *(buf + i + j) = GITHEAD[j];

        fd = open_rdonly(buf);
        if (fd != -1) {
            write_branch_name(buf, fd);
            exit(BRANCH_FOUND);
        }

        /* we know that buf[0] == '/' */
        while (buf[--i - 1] != '/')
            ;

    } while (should_check_dir(buf, i));

    /* reached / or /home,
     * assume there is no /.git nor /home/.git directory and terminate */
    exit(BRANCH_NOT_FOUND);
}
