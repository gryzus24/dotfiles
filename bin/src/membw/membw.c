#define _GNU_SOURCE
#include <errno.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#include <immintrin.h>

typedef uint8_t u8;
typedef uint32_t u32;
typedef uint64_t u64;

#define _str(x) #x
#define _xstr(x) _str(x)

#ifdef NOINLINE_DO_FUNCS
# define __maybe_noinline __attribute__((noinline))
#else
# define __maybe_noinline
#endif

#define __aligned(x) __attribute__((aligned(x)))
#define __cold       __attribute__((cold))
#define __unused     __attribute__((unused))

#define countof(a) (sizeof (a) / sizeof *(a))

#define min(a, b) \
	({ auto _a = a; auto _b = b; _a < _b ? _a : _b; })
#define max(a, b) \
	({ auto _a = a; auto _b = b; _a > _b ? _a : _b; })

#define to_bit(x) (1ULL << (x))

constexpr u32 F_SHIFT = 16;
constexpr u32 F_FRAC_MASK = to_bit(F_SHIFT) - 1;
static u64 f_int(u64 n) { return n >> F_SHIFT; }
static u64 f_frac(u64 n) { return ((n & F_FRAC_MASK) * 1000) >> F_SHIFT; };

enum mode {
	MODE_READ,
	MODE_READ_NT,
	MODE_WRITE,
	MODE_WRITE_NT,
	MODE_MEMZERO,
	MODE_COPY,
	MODE_COPY_NT,
	MODE_COPY_BYTE,
	MODE_COPY_REPSB,
	MODE_MEMCPY,
	MODE_MAX,
};

constexpr u64 MODE_READ_ONLY_MASK =
	to_bit(MODE_READ) |
	to_bit(MODE_READ_NT);

constexpr u64 MODE_WRITE_ONLY_MASK =
	to_bit(MODE_WRITE) |
	to_bit(MODE_WRITE_NT) |
	to_bit(MODE_MEMZERO);

constexpr u64 MODE_COPY_MASK =
	to_bit(MODE_COPY) |
	to_bit(MODE_COPY_NT) |
	to_bit(MODE_COPY_BYTE) |
	to_bit(MODE_COPY_REPSB) |
	to_bit(MODE_MEMCPY);

constexpr u64 MODE_READ_ARRAY_MASK = MODE_READ_ONLY_MASK | MODE_COPY_MASK;
constexpr u64 MODE_WRITE_ARRAY_MASK = MODE_WRITE_ONLY_MASK | MODE_COPY_MASK;

static const char *mode_str(enum mode mode)
{
	switch (mode) {
	case MODE_READ:       return "READ";
	case MODE_READ_NT:    return "READ_NT";
	case MODE_WRITE:      return "WRITE";
	case MODE_WRITE_NT:   return "WRITE_NT";
	case MODE_COPY:       return "COPY";
	case MODE_COPY_NT:    return "COPY_NT";
	case MODE_COPY_BYTE:  return "COPY_BYTE";
	case MODE_COPY_REPSB: return "COPY_REPSB";
	case MODE_MEMCPY:     return "MEMCPY";
	case MODE_MEMZERO:    return "MEMZERO";
	case MODE_MAX:        return "MAX";
	}
	__builtin_unreachable();
}

#define LOOPS_PER_MODE_DEFAULT 8
#define ARRAY_SIZE_MIB_DEFAULT 256
#define PRINT_INTERVAL_MS_DEFAULT 200

struct opts {
	u64 loops_per_mode;
	u64 nr_bytes;
} g_opts = {
	.loops_per_mode = LOOPS_PER_MODE_DEFAULT,
	.nr_bytes = ARRAY_SIZE_MIB_DEFAULT << 20,
};

struct desc {
	u32 first;
	u32 last;
	u32 run;
	enum mode mode;
};

struct mode_result {
	u64 ms;
	u64 mbs;
	u64 mbs_min;
	u64 mbs_max;
};
#define MODE_RESULT_CLEAR \
	(struct mode_result){ .mbs_min = ~0ULL }

enum bw_state {
	BW_RUNNING,
	BW_EXITED,
	BW_EARLY_FAIL,
};

struct bw_local {
	struct {
		pthread_barrier_t *barrier;
		enum bw_state state;
	} thread;
	struct {
		enum mode mode;
		bool mode_locked;
		bool print;
		bool wait_on_barrier;
	} config;
	struct {
		struct mode_result f;
		int cpu;
		atomic_uint seq;
	} result;

	#define seq_atomic(s0, s1) \
		(!((s0) & 1) && (s0) == (s1))

} __aligned(64);
static_assert(sizeof(struct bw_local) == 64);

#define ASM_READ_256(instr, src) \
	asm volatile                  \
	( #instr " (%0),%%ymm0\n"     \
	  #instr " 0x20(%1),%%ymm1\n" \
	  #instr " 0x40(%2),%%ymm2\n" \
	  #instr " 0x60(%3),%%ymm3\n" \
	  #instr " 0x80(%4),%%ymm4\n" \
	  #instr " 0xa0(%5),%%ymm5\n" \
	  #instr " 0xc0(%6),%%ymm6\n" \
	  #instr " 0xe0(%7),%%ymm7\n" \
	:                             \
	: "r"(src), "r"(src),         \
	  "r"(src), "r"(src),         \
	  "r"(src), "r"(src),         \
	  "r"(src), "r"(src)          \
	:)

__maybe_noinline
static void do_read(u8 *restrict w __unused, u8 *restrict r, u64 nr_bytes)
{
	for (u64 i = 0; i < nr_bytes; i += 256)
		ASM_READ_256(vmovdqa, r + i);
}
__maybe_noinline
static void do_read_nt(u8 *restrict w __unused, u8 *restrict r, u64 nr_bytes)
{
	for (u64 i = 0; i < nr_bytes; i += 256)
		ASM_READ_256(vmovntdqa, r + i);
}
__maybe_noinline
static void do_write(u8 *restrict w, u8 *restrict r __unused, u64 nr_bytes)
{
	__m256i zero = {0};
	for (u64 i = 0; i < nr_bytes; i += 512) {
		u8 *dst = w + i;
		#pragma GCC unroll 16
		for (u64 j = 0; j < 512; j += 32)
			_mm256_store_si256((__m256i *)(dst + j), zero);
	}
}
__maybe_noinline
static void do_write_nt(u8 *restrict w, u8 *restrict r __unused, u64 nr_bytes)
{
	__m256i zero = {0};
	for (u64 i = 0; i < nr_bytes; i += 512) {
		u8 *dst = w + i;
		#pragma GCC unroll 16
		for (u64 j = 0; j < 512; j += 32)
			_mm256_stream_si256((__m256i *)(dst + j), zero);
	}
}
__maybe_noinline
static void do_copy(u8 *restrict w, u8 *restrict r, u64 nr_bytes)
{
	for (u64 i = 0; i < nr_bytes; i += 512) {
		u8 *dst = w + i, *src = r + i;
		#pragma GCC unroll 16
		for (u64 j = 0; j < 512; j += 32)
			_mm256_store_si256((__m256i *)(dst + j),
				_mm256_load_si256((__m256i *)(src + j)));
	}
}
__maybe_noinline
static void do_copy_nt(u8 *restrict w, u8 *restrict r, u64 nr_bytes)
{
	for (u64 i = 0; i < nr_bytes; i += 512) {
		u8 *dst = w + i, *src = r + i;
		#pragma GCC unroll 16
		for (u64 j = 0; j < 512; j += 32)
			_mm256_stream_si256((__m256i *)(dst + j),
				_mm256_load_si256((__m256i *)(src + j)));
	}
}
__maybe_noinline
static void do_copy_byte(u8 *restrict w, u8 *restrict r, u64 nr_bytes)
{
	for (u64 i = 0; i < nr_bytes; i++) {
		w[i] = r[i];
		asm volatile ("" : : : "memory");
	}
}
__maybe_noinline
static void do_copy_repsb(u8 *restrict w, u8 *restrict r, u64 nr_bytes)
{
	asm volatile
	( "rep movsb"
	: "=&c"(nr_bytes), "=&D"(w), "=&S"(r)
	: "0"(nr_bytes), "1"(w), "2"(r)
	: "memory");
}

static void fprint_header(FILE *fp, u8 *w, u8 *r, u64 nr_bytes)
{
	fprintf(fp, "TEST\n");
	if (r) fprintf(fp, " [%p] read array\n", r);
	if (w) fprintf(fp, " [%p] write array\n", w);
	fprintf(fp, " %zu MiB, %zu 4k-pages, %zu bytes\n",
		nr_bytes >> 20, nr_bytes >> 12, nr_bytes);
}

static u64 run_mode(u8 *restrict w, u8 *restrict r, u64 nr_bytes, enum mode mode)
{
	struct timespec ts0, ts1;

	clock_gettime(CLOCK_MONOTONIC, &ts0);
	switch (mode) {
	case MODE_READ:       do_read       (w, r, nr_bytes); break;
	case MODE_READ_NT:    do_read_nt    (w, r, nr_bytes); break;
	case MODE_WRITE:      do_write      (w, r, nr_bytes); break;
	case MODE_WRITE_NT:   do_write_nt   (w, r, nr_bytes); break;
	case MODE_MEMZERO:    memset        (w, 0, nr_bytes); break;
	case MODE_COPY:       do_copy       (w, r, nr_bytes); break;
	case MODE_COPY_NT:    do_copy_nt    (w, r, nr_bytes); break;
	case MODE_COPY_BYTE:  do_copy_byte  (w, r, nr_bytes); break;
	case MODE_COPY_REPSB: do_copy_repsb (w, r, nr_bytes); break;
	case MODE_MEMCPY:     memcpy        (w, r, nr_bytes); break;
	case MODE_MAX: __builtin_unreachable();
	}
	clock_gettime(CLOCK_MONOTONIC, &ts1);

	u64 t0 = (u64)(ts0.tv_sec * 1'000'000'000 + ts0.tv_nsec);
	u64 t1 = (u64)(ts1.tv_sec * 1'000'000'000 + ts1.tv_nsec);
	return t1 - t0;
}

static u8 *mmap_fault_in(u64 nr_bytes, int prot)
{
	// Passing the MAP_POPULATE flag hides page fault statistics
	// from `perf stat`, so let's not do that. To populate the mapping
	// simply jump over every page and write a single byte to each one.
	u8 *ptr = mmap(NULL, nr_bytes,
		PROT_READ | PROT_WRITE,
		MAP_PRIVATE | MAP_ANON, -1, 0);
	if (ptr == (void *)-1)
		return perror("mmap"), NULL;

	for (u64 i = 0; i < nr_bytes; i += 0x1000)
		ptr[i] = 0xaa;

	if (mprotect(ptr, nr_bytes, prot) == -1)
		return perror("mprotect"), NULL;

	return ptr;
}

static void *bw_thread(void *bw_local)
{
	struct bw_local *bwl = bw_local;

	const u64 nr_bytes     = g_opts.nr_bytes;
	u64 loops              = g_opts.loops_per_mode;
	u64 loops_per_mode     = g_opts.loops_per_mode;

	enum mode mode         = bwl->config.mode;
	const bool mode_locked = bwl->config.mode_locked;
	const bool print       = bwl->config.print;
	bool waited_on_barrier = !bwl->config.wait_on_barrier;

	u8 *r = NULL, *w = NULL;
	if (!mode_locked || (to_bit(mode) & MODE_READ_ARRAY_MASK)) {
		r = mmap_fault_in(nr_bytes, PROT_READ);
		if (!r) goto mmap_fail;
	}
	if (!mode_locked || (to_bit(mode) & MODE_WRITE_ARRAY_MASK)) {
		w = mmap_fault_in(nr_bytes, PROT_WRITE);
		if (!w) goto mmap_fail;
	}
	if (loops) {
		if (!mode_locked)
			loops *= MODE_MAX;
	} else {
		loops = --loops_per_mode;
	}
	u64 mode_iter = loops_per_mode;

	if (!bwl->result.f.mbs_min)
		bwl->result.f.mbs_min--;

	struct mode_result per_mode_f = MODE_RESULT_CLEAR;

	if (print)
		fprint_header(stderr, w, r, nr_bytes);

	for (; loops; loops--) {
		if (print && mode_iter == loops_per_mode)
			printf("%s\n", mode_str(mode));

		u64 delta_ns = run_mode(w, r, nr_bytes, mode);
		u64 delta_ms_f = (delta_ns << F_SHIFT) / 1'000'000;

		u64 ops_f = (1'000'000'000ULL << F_SHIFT) / delta_ns;
		u64 mbs_f = (nr_bytes * ops_f) >> 20;

		int cpu = sched_getcpu();

		per_mode_f.ms += delta_ms_f;
		per_mode_f.mbs += mbs_f;
		per_mode_f.mbs_min = min(per_mode_f.mbs_min, mbs_f);
		per_mode_f.mbs_max = max(per_mode_f.mbs_max, mbs_f);

		atomic_fetch_add_explicit(&bwl->result.seq, 1, memory_order_release);
		bwl->result.f.ms = delta_ms_f;
		bwl->result.f.mbs = mbs_f;
		bwl->result.f.mbs_min = min(bwl->result.f.mbs_min, mbs_f);
		bwl->result.f.mbs_max = max(bwl->result.f.mbs_max, mbs_f);
		bwl->result.cpu = cpu;
		atomic_fetch_add_explicit(&bwl->result.seq, 1, memory_order_release);

		if (!waited_on_barrier) {
			pthread_barrier_wait(bwl->thread.barrier);
			waited_on_barrier = true;
		}
		if (print) printf(" %3zu.%03zu ms %5lu.%03zu MiB/s\n",
			f_int(delta_ms_f), f_frac(delta_ms_f),
			f_int(mbs_f),      f_frac(mbs_f));

		if (print && --mode_iter == 0) {
			if (loops_per_mode > 1) {
				u64 ms_avg_f = per_mode_f.ms / loops_per_mode;
				u64 mbs_avg_f = per_mode_f.mbs / loops_per_mode;

				printf("=%3zu.%03zu ms %5zu.%03zu MiB/s [%zu.%03zu, %zu.%03zu]\n",
					f_int(ms_avg_f),           f_frac(ms_avg_f),
					f_int(mbs_avg_f),          f_frac(mbs_avg_f),
					f_int(per_mode_f.mbs_min), f_frac(per_mode_f.mbs_min),
					f_int(per_mode_f.mbs_max), f_frac(per_mode_f.mbs_max));
				per_mode_f = MODE_RESULT_CLEAR;
			}
			mode_iter = loops_per_mode;
			if (!mode_locked)
				mode = (mode + 1) % MODE_MAX;
		}
	}
	bwl->thread.state = BW_EXITED;
	if (r) munmap(r, nr_bytes);
	if (w) munmap(w, nr_bytes);
	return NULL;
mmap_fail:
	bwl->thread.state = BW_EARLY_FAIL;
	if (r) munmap(r, nr_bytes);
	if (w) munmap(w, nr_bytes);
	if (!waited_on_barrier)
		pthread_barrier_wait(bwl->thread.barrier);
	return NULL;
}

__cold
static void logerr(const char *fmt, ...)
{
	va_list args;
	va_start(args);
	vfprintf(stderr, fmt, args);
	va_end(args);
}

enum parse_u64_mode { PARSE_RAW, PARSE_SIZE };
static bool parse_u64(char *s, u64 *out, enum parse_u64_mode mode)
{
	char *endp = s;
	u64 r = strtoull(s, &endp, 10);
	if (endp == s)
		return true;
	if (*endp == '\0')
		goto ok;
	if (mode == PARSE_RAW)
		return true;
	if (endp[1] == '\0') {
		switch (*endp | 0x20) {
		case 'b': r <<=  0; break;
		case 'k': r <<= 10; break;
		case 'm': r <<= 20; break;
		case 'g': r <<= 30; break;
		case 't': r <<= 40; break;
		default: return true;
		}
	}
ok:
	return *out = r, false;
}

static enum mode parse_mode(const char *s)
{
	enum mode x;
	if (x = MODE_READ,       !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_READ_NT,    !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_WRITE,      !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_WRITE_NT,   !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_MEMZERO,    !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_COPY,       !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_COPY_NT,    !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_COPY_BYTE,  !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_COPY_REPSB, !strcasecmp(s, mode_str(x))) return x;
	if (x = MODE_MEMCPY,     !strcasecmp(s, mode_str(x))) return x;
	return MODE_MAX;
}

static u32 parse_program(char *c, struct desc *descs, const u32 descs_max)
{
	#define swap(a, b) \
		do { auto _t = a; a = b; b = _t; } while (0)
	#define isws(x) ((x) == ' ' || (x) == '\t' || (x) == '\n')
	#define isdig(x) ('0' <= (x) && (x) <= '9')
	#define isalp(x) ('a' <= ((x)|0x20) && ((x)|0x20) <= 'z')

	u32 desc_idx = 0;
next_desc:
	union { struct desc d; u32 work[3]; } u = {0};
	u32 w = 0;
	do {
		while (isws(*c)) c++;
		if (*c == '\0')
			goto end;
		if (w == countof(u.work))
			break;
		if (*c == '-') {
			c++;
			if (!w)
				return logerr("r: stray '-' (start)\n"), 0;
			u.work[w] = u.work[w - 1];
		} else if (isdig(*c)) {
			do u.work[w] = u.work[w] * 10 + (*c++ & 0x0f);
			while (isdig(*c));
		} else if (isalp(*c)) {
			break;
		} else
			return logerr("r: '%c'?\n", *c), 0;
	} while (w++, 1);

	char *e = c;
	while (*e != '\0' && !isws(*e)) e++;
	char saved = *e;

	*e = '\0';
	if ((u.d.mode = parse_mode(c)) == MODE_MAX)
		return logerr("r: invalid mode: '%s'\n", c), 0;
	*e = saved;
	c = e;

	if (!u.d.last)
		u.d.last = u.d.first;
	if (u.d.first > u.d.last)
		swap(u.d.first, u.d.last);
	if (!u.d.run)
		u.d.run = u.d.last - u.d.first + 1;

	if (desc_idx == descs_max)
		return logerr("r: description too long\n"), 0;

	descs[desc_idx++] = u.d;
	goto next_desc;
end:
	if (!desc_idx || w)
		return logerr("r: description incomplete\n"), 0;
	return desc_idx;
}

static void usage(void)
{
	logerr(
"usage: membw [-m <mode>] [-n <loops per mode>] [-r <file>] [-i <interval>]\n"
"             [<array size>[bkmgt]]\n"
"\n"
" -m <mode>  One of:\n"
"             read,  read_nt,\n"
"             write, write_nt, memzero\n"
"             copy,  copy_nt,  copy_byte, copy_repsb, memcpy\n"
"\n"
"            'nt' stands for Non-Temporal - avoids polluting CPU caches.\n"
"            'copy_byte' copies byte at a time in a loop.\n"
"            'copy_repsb' copies using the 'rep movsb' instruction.\n"
"            DEFAULT: cycle through all modes <loops per mode> times\n"
"\n"
" -n <loops per mode>\n"
"            Positive number, or 0 to loop for a long time.\n"
"            DEFAULT: " _xstr(LOOPS_PER_MODE_DEFAULT) "\n"
"\n"
" -r <file>  Enables multi-threaded operation. Reads a description in a\n"
"            <[first][last|-][nr_threads|-]<mode> >... format, where:\n"
"             * [first], first CPU in the affinity mask, 0 if unspecified,\n"
"             * [last], last CPU in the affinity mask, [first] if unspecified,\n"
"             * [nr_threads], number of threads to spawn with the [first]-[last]\n"
"               CPU affinity mask, \"fills\" the affinity mask if unspecified,\n"
"               i.e. the result of the [last]-[first]+1 calculation.\n"
"             * <mode>, mode of spawned threads, required.\n"
"            A '-' might be used to copy the previous value, for example:\n"
"\n"
"             0 2 - copy_nt 7-4 copy_byte\n"
"\n"
"            spawns 2 'copy_nt' threads with the 0-2 affinity mask,\n"
"            and 4 'copy_byte' threads with the 7-7 affinity mask\n"
"            (pinned to the CPU 7).\n"
"\n"
"            If <file> is '-', the description is read from stdin.\n"
"\n"
" -i <interval>\n"
"            Positive number, the minimum printout interval time in\n"
"            milliseconds. Applies only to multi-threaded operation.\n"
"            DEFAULT: " _xstr(PRINT_INTERVAL_MS_DEFAULT) "\n"
"\n"
" <array size>[bkmgt]\n"
"            Positive number, size of read and write arrays in bytes;\n"
"            one of B, K, M, G, T may be specified as a power-of-two suffix.\n"
"            Allocates two arrays <array size> each, unless only one of them\n"
"            is required by <mode> to perform the task.\n"
"            DEFAULT: " _xstr(ARRAY_SIZE_MIB_DEFAULT) "M\n"
	);
}

int main(int argc, char *argv[])
{
	enum mode mode = MODE_READ;
	bool mode_locked = false;
	long print_interval_ms = PRINT_INTERVAL_MS_DEFAULT;

	char r_str[1 << 11];
	struct desc descs[63];
	u32 nr_descs = 0;

	int opt;
	while ((opt = getopt(argc, argv, "m:n:r:i:h")) != -1) {
		switch (opt) {
		case 'm':
			if ((mode = parse_mode(optarg)) == MODE_MAX)
				return logerr("invalid mode: '%s'\n", optarg), usage(), 2;
			mode_locked = true;
			break;
		case 'n':
			if (parse_u64(optarg, &g_opts.loops_per_mode, PARSE_RAW))
				return logerr("invalid loops per mode: '%s'\n", optarg),
					usage(), 2;
			break;
		case 'r':
			FILE *fp = stdin;
			if (*optarg != '-' && !(fp = fopen(optarg, "r")))
				return perror("r: fopen"), 2;

			u64 n = fread(r_str, 1, sizeof r_str, fp);
			if (n >= sizeof r_str)
				return logerr("r: too big\n"), 2;
			r_str[n] = '\0';

			nr_descs = parse_program(r_str, descs, countof(descs));
			if (!nr_descs)
				return 2;
			break;
		case 'i':
			u64 t;
			if (parse_u64(optarg, &t, PARSE_RAW))
				return logerr("invalid interval: '%s'\n", optarg),
					usage(), 2;
			if (!t)
				t++;
			if (t > (~0UL >> 1))
				t = ~0UL >> 1;
			print_interval_ms = (long)t;
			break;
		case 'h':
		default:
			return usage(), (opt != 'h') * 2;
		}
	}
	if (optind < argc && parse_u64(argv[optind], &g_opts.nr_bytes, PARSE_SIZE))
		return logerr("invalid array size: '%s'\n", argv[optind]), usage(), 2;

	const u64 align_mask = 0x1000 - 1;
	g_opts.nr_bytes = (g_opts.nr_bytes + align_mask) & ~align_mask;

	if (!nr_descs) {
		// No affinity descriptions provided, run directly.
		struct bw_local bwl = {
			.config = {
				.mode = mode,
				.mode_locked = mode_locked,
				.print = true,
			},
		};
		bw_thread(&bwl);
		return bwl.thread.state != BW_EXITED;
	}

	u32 t_total = 0;
	for (u32 i = 0; i < nr_descs; i++)
		t_total += descs[i].run;

	struct bw_local *t_bwls = aligned_alloc(64, sizeof *t_bwls * t_total);
	if (!t_bwls)
		return perror("alloc"), 1;

	pthread_barrier_t barrier;
	if ((errno = pthread_barrier_init(&barrier, NULL, t_total + 1)))
		return perror("pthread_barrier_init"), 1;

	u64 t_idx = 0;
	for (u32 i = 0; i < nr_descs; i++) {
		struct desc desc = descs[i];

		pthread_attr_t attr;
		cpu_set_t cset;
		int err;

		if (desc.last >= CPU_SETSIZE)
			return logerr("affinity mask too big\n"), 1;

		CPU_ZERO(&cset);
		for (u32 cpu = desc.first; cpu <= desc.last; cpu++)
			CPU_SET(cpu, &cset);

		err = 0;
		err |= pthread_attr_init(&attr);
		err |= pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
		err |= pthread_attr_setstacksize(&attr, (size_t)PTHREAD_STACK_MIN);
		err |= pthread_attr_setaffinity_np(&attr, sizeof cset, &cset);
		if (err)
			return logerr("pthread attr-related failure\n"), 1;

		fprintf(stderr, "== SPAWNING %u thread(s) on CPU", desc.run);
		if (desc.first == desc.last)
			fprintf(stderr, " %u\n", desc.first);
		else
			fprintf(stderr, "s %u-%u\n", desc.first, desc.last);

		for (u32 _ = 0; _ < desc.run; _++) {
			struct bw_local *bwl = &t_bwls[t_idx++];

			*bwl = (struct bw_local){
				.thread = {
					.barrier = &barrier,
				},
				.config = {
					.mode = desc.mode,
					.mode_locked = true,
					.wait_on_barrier = true,
				},
			};
			pthread_t tid;
			if ((errno = pthread_create(&tid, &attr, &bw_thread, bwl)))
				return perror("pthread_create"), 1;
		}
		pthread_attr_destroy(&attr);
	}
	fprintf(stderr, "== WAITING for all threads to run the first loop\n");
	pthread_barrier_wait(&barrier);

	fprint_header(stderr, NULL, NULL, g_opts.nr_bytes);

	// The "\n" for lines that might have unstable
	// formatting and change width from run to run.
	#define DESIGNER_LF "     \n"
again:
	u32 nr_lines = 0;
	u32 t_running = 0;
	u64 t_ms_total = 0;
	t_idx = 0;
	for (u32 i = 0; i < nr_descs; i++) {
		struct desc desc = descs[i];

		bool header_printed = false;
		for (u32 _ = 0; _ < desc.run; _++) {
			struct bw_local *bwl = &t_bwls[t_idx++];

			switch (bwl->thread.state) {
			case BW_RUNNING:
				t_running++; [[fallthrough]];
			case BW_EXITED:
				if (!header_printed) {
					printf("%s, Affinity %u-%u\n",
						mode_str(desc.mode), desc.first, desc.last);
					header_printed = true;
					nr_lines++;
				}
				uint s0, s1;
				struct mode_result f;
				int cpu;

				s0 = atomic_load_explicit(&bwl->result.seq, memory_order_acquire);
				f = bwl->result.f;
				cpu = bwl->result.cpu;
				s1 = atomic_load_explicit(&bwl->result.seq, memory_order_acquire);

				if (seq_atomic(s0, s1)) {
					t_ms_total += f_int(f.ms);

					printf(" CPU%3u %3zu.%03zu ms %5zu.%03zu MiB/s"
						" %5zu.%03zu Min %5zu.%03zu Max",
						cpu,
						f_int(f.ms),      f_frac(f.ms),
						f_int(f.mbs),     f_frac(f.mbs),
						f_int(f.mbs_min), f_frac(f.mbs_min),
						f_int(f.mbs_max), f_frac(f.mbs_max));
					if (bwl->thread.state == BW_EXITED)
						printf(" -- exited");
					printf(DESIGNER_LF);
				} else { /* We avoid this problem by ignoring it. */
					printf("\n");
				}
				nr_lines++;
				break;
			case BW_EARLY_FAIL:
				printf("%s, Affinity %u-%u -- thread failed to initialize!\n",
					mode_str(desc.mode), desc.first, desc.last);
				nr_lines++;
				break;
			}
		}
	}
	if (!t_running)
		return 0;

	printf("\033[%uA", nr_lines);

	long t_ms_avg = max((long)(t_ms_total / t_running), print_interval_ms);
	struct timespec req = {
		.tv_sec = t_ms_avg / 1000,
		.tv_nsec = t_ms_avg % 1000 * 1'000'000,
	};
	while (nanosleep(&req, &req) && errno == EINTR)
		;
	goto again;
}

// vim: set sw=6 ts=6 noet:
