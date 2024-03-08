/*
 * cgb - quickly! show me my /CURRENT GIT BRANCH/
 */

#include <asm-generic/fcntl.h> /* O_{RDONLY,NOATIME} */
#include <asm/unistd_64.h>
#ifdef PATH_PREFIXES
# include <limits.h>
#endif
#include <stdbool.h>
#include <stdint.h>

#define arr_count(a) (sizeof(a) / sizeof((a)[0]))
#define noreturn __attribute__((noreturn))
#define unlikely(x) __builtin_expect(!!(x), 0)

typedef uint64_t u64;
typedef uint32_t u32;
typedef int64_t i64;

static i64 syscall_check(u64 r)
{
    return r > -4096UL ? -1 : (i64)r;
}

static u64 syscall3(i64 nr, i64 a, i64 b, i64 c)
{
    u64 ret;

    __asm__ volatile (
        "syscall"
        : "=a"(ret)
        : "a"(nr), "D"(a), "S"(b), "d"(c)
        : "rcx", "r11", "memory"
    );
    return ret;
}

static i64 read(u32 fd, char *buf, u64 n)
{
    return syscall_check(syscall3(__NR_read, fd, (i64)buf, (i64)n));
}

static i64 write(u32 fd, const char *buf, u64 n)
{
    return syscall_check(syscall3(__NR_write, fd, (i64)buf, (i64)n));
}

static i64 open_rdonly(const char *path)
{
    u64 ret;

    __asm__ volatile (
        "syscall"
        : "=a"(ret)
        : "a"(__NR_open), "D"(path), "S"(O_RDONLY | O_NOATIME)
        : "rcx", "r11", "memory"
    );
    return syscall_check(ret);
}

static i64 getcwd(char *buf, u64 size)
{
    u64 ret;

    __asm__ volatile (
        "syscall"
        : "=a"(ret)
        : "a"(__NR_getcwd), "D"(buf), "S"(size)
        : "rcx", "r11", "memory"
    );
    return syscall_check(ret);
}

#define GITHEAD ".git/HEAD"
#define GITHEAD_SIZE 10

#define BRANCH_WRITTEN        0
#define PATH_AT_ROOT          1
#define PATH_BEFORE_PREFIX    2
#define PATH_UNWANTED_PREFIX  3
#define GITHEAD_BAD           253
#define GETCWD_BAD            254
#define ARGC_BAD              255

static int write_branch_name(char *buf256, u32 githead_fd)
{
    char *const start255 = buf256 + 1;
    char *ptr;

    /* read into buf:  [0 A A A A A \n 0 0 ...]
     * overwrite with: [( A A A A A  )   0 ...] */
    const i64 nread = read(githead_fd, start255, 255 - 1);
    if (unlikely(nread < 2 || start255[nread - 1] != '\n'))
        return GITHEAD_BAD;

    ptr = start255 + nread;

    *ptr-- = ' ';
    *ptr-- = ')';
    while (ptr >= start255 && *ptr != '/')
        --ptr;
    *ptr = '(';

    write(1, ptr, (u64)(start255 + nread) - (u64)(ptr - 1));

    return BRANCH_WRITTEN;
}

#ifdef PATH_PREFIXES
static u64 strlen(const char *s)
{
    const char *p = s;
    for (; *p; ++p)
        ;
    return (u64)(p - s);
}

static bool hasprefix(const char *s, const char *p)
{
    for (; *p; ++s, ++p)
        if (*s != *p)
            return false;

    return true;
}

int _main(i64 *const rsp)
{
    char buf[256];
    i64 ret;
    u64 diri;

    const char **argv;
    u64 argc;
    u64 prefixlen_min = UINT64_MAX;

    if (unlikely(*rsp <= 0))
        return ARGC_BAD;

    /* skip first argument */
    argc = (u64)(*rsp - 1);
    argv = (void *)(rsp + 2);

    /* diri stores the index of a path separator + 1 */
    ret = getcwd(buf, arr_count(buf) - GITHEAD_SIZE - 1);
    if (unlikely(ret < 3 || buf[0] != '/'))
        return GETCWD_BAD;
    diri = (u64)ret;

    /* replace '\0' with '/' */
    buf[diri - 1] = '/';
    buf[diri] = '\0';

    if (argc > 0) {
        bool prefix_ok = false;
        for (u64 i = 0; i < argc; ++i) {
            if (hasprefix(buf, argv[i])) {
                u64 len = strlen(argv[i]);
                if (len < prefixlen_min)
                    prefixlen_min = len;
                prefix_ok = true;
            }
        }
        if (!prefix_ok)
            return PATH_UNWANTED_PREFIX;
    }

    do {
        i64 fd;

        for (u64 i = 0; i < GITHEAD_SIZE; ++i)
            buf[diri + i] = GITHEAD[i];

        fd = open_rdonly(buf);
        if (fd != -1)
            return write_branch_name(buf, (u32)fd);

        /* lookahead is safe, we know that buf[0] == '/' */
        while (buf[--diri - 1] != '/')
            ;

        if (prefixlen_min != UINT64_MAX && prefixlen_min > diri)
            return PATH_BEFORE_PREFIX;

    } while (diri > 1);

    /* reached /, assume there is no /.git directory and exit */
    return PATH_AT_ROOT;
}

noreturn void _start(void)
{
    /* obey the SysV ABI reluctantly */
    __asm__ (
        "xor %ebp,%ebp\n"  /* zero the stack frame */
        "mov %rsp,%rdi\n"  /* (%rsp) holds the argc */
        "and $-16,%rsp\n"  /* %rsp must be 16-byte aligned */
        "call _main\n"
        "mov %eax,%edi\n"
        "mov $60,%eax\n"   /* sys_exit, exit code in %edi */
        "syscall\n"
    );
    __builtin_unreachable();
}
#else
static bool is_dir_home(const char *s, u64 diri)
{
    if (diri == 6) {
        u32 t;
        __builtin_memcpy(&t, s + 1, 4);
        return t == 0x656d6f68;
    }
    return false;
}

static int _main(void)
{
    char buf[256];
    i64 ret;
    u64 diri;

    /* diri stores the index of a path separator + 1 */
    ret = getcwd(buf, arr_count(buf) - GITHEAD_SIZE - 1);
    if (unlikely(ret < 3 || buf[0] != '/'))
        return GETCWD_BAD;
    diri = (u64)ret;

    /* replace '\0' with '/' */
    buf[diri - 1] = '/';
    buf[diri] = '\0';

    do {
        i64 fd;

        for (u64 i = 0; i < GITHEAD_SIZE; ++i)
            buf[diri + i] = GITHEAD[i];

        fd = open_rdonly(buf);
        if (fd != -1)
            return write_branch_name(buf, (u32)fd);

        /* lookahead is safe, we know that buf[0] == '/' */
        while (buf[--diri - 1] != '/')
            ;

    } while (diri > 1 && !is_dir_home(buf, diri));

    /* reached / or /home,
     * assume there is no /.git nor /home/.git directory and exit */
    return PATH_AT_ROOT;
}

noreturn void _start(void)
{
    __asm__ volatile ("syscall" : /* */ : "a"(__NR_exit), "D"(_main()));
    __builtin_unreachable();
}
#endif /* PATH_PREFIXES */
