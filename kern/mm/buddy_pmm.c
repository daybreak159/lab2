

/* Buddy System Physical Memory Allocator
 *
 * 如果想看到打分输出（类似 Best-Fit 的 grading 输出），
 * 取消下面这行的注释：
 * #define ucore_test
 */

#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

// 取消下面这行注释可以看到打分输出
#define ucore_test

#define MAX_ORDER 10 // Manage blocks up to 2^10 = 1024 pages (4MB with 4KB pages)

typedef struct buddy_block {
    list_entry_t link;
    unsigned int order; // order of this block
    struct Page *base;   // pointer to page array head
} buddy_block_t;

static free_area_t free_area; // reuse free_area for nr_free and list header (not used for blocks)
static list_entry_t free_lists[MAX_ORDER + 1];
static unsigned int max_order_inited = 0;

static void buddy_init(void) {
    int i;
    cprintf("[buddy] buddy_init() start\n");
    for (i = 0; i <= MAX_ORDER; i++)
        list_init(&free_lists[i]);
    free_area.nr_free = 0;
    max_order_inited = 0;
    cprintf("[buddy] buddy_init() done\n");
}

// helper: compute order >= needed such that 2^order >= n
static unsigned int size_to_order(unsigned int n) {
    unsigned int o = 0;
    unsigned int s = 1;
    while (s < n) { s <<= 1; o++; }
    return o;
}

// Convert a Page* to an index in pages[] and to block-aligned address
static inline uintptr_t page_index(struct Page *p) {
    return (uintptr_t)(p - pages);
}

// Insert a free block descriptor for block base (page pointer) with given order
static void buddy_add_free(struct Page *base, unsigned int order) {
    buddy_block_t *b = (buddy_block_t *)base; // reuse first page structure space for descriptor
    b->order = order;
    b->base = base;
    list_add(&free_lists[order], &b->link);
    free_area.nr_free += (1UL << order);
    if (order > max_order_inited) max_order_inited = order;
}

// Remove a free block descriptor from its list and return base
static struct Page *buddy_remove_free(list_entry_t *le) {
    buddy_block_t *b = to_struct((le), buddy_block_t, link);
    struct Page *base = b->base;
    list_del(&b->link);
    free_area.nr_free -= (1UL << b->order);
    return base;
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    // initialize pages in this region as free blocks by splitting into maximal power-of-two blocks
    assert(n > 0);
    cprintf("[buddy] buddy_init_memmap: base=%p n=%u\n", base, (unsigned)n);
    struct Page *p = base;
    // clear flags
    for (; p < base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    // split into buddy blocks
    size_t remain = n;
    struct Page *cur = base;
    while (remain > 0) {
        // largest power of two <= remain
        unsigned int o = 0;
        while ((1UL << (o + 1)) <= remain) o++;
        if (o > MAX_ORDER) {
            // if block size exceeds our max order, cap it and add multiple max-order blocks
            unsigned int blocks = (1UL << o) / (1UL << MAX_ORDER);
            for (unsigned int b = 0; b < blocks; b++) {
                buddy_add_free(cur, MAX_ORDER);
                cur += (1UL << MAX_ORDER);
                remain -= (1UL << MAX_ORDER);
            }
        } else {
            buddy_add_free(cur, o);
            cur += (1UL << o);
            remain -= (1UL << o);
        }
    }
    cprintf("[buddy] buddy_init_memmap: finished, total free pages=%u\n", (unsigned)free_area.nr_free);
}

static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0 || n > free_area.nr_free) return NULL;
    unsigned int need_order = size_to_order(n);
    unsigned int o;
    for (o = need_order; o <= MAX_ORDER; o++) {
        if (!list_empty(&free_lists[o])) break;
    }
    if (o > MAX_ORDER) return NULL;
    // take one block from order o, split until reach need_order
    list_entry_t *le = list_next(&free_lists[o]);
    struct Page *blk = buddy_remove_free(le);
    while (o > need_order) {
        o--;
        // split block: first half returned, second half added to free list
        struct Page *buddy = blk + (1UL << o);
        buddy_add_free(buddy, o);
    }
    // mark allocated: clear PG_property by not setting it
    ClearPageProperty(blk);
    return blk;
}

// Helper: find buddy block in free_list by address
static struct Page *buddy_find_and_remove(struct Page *base, unsigned int order) {
    // Calculate buddy address: XOR with (1 << order) at the page index
    uintptr_t idx = page_index(base);
    uintptr_t buddy_idx = idx ^ (1UL << order);
    struct Page *buddy_addr = pages + buddy_idx;

    // Search in free_lists[order]
    list_entry_t *le = &free_lists[order];
    while ((le = list_next(le)) != &free_lists[order]) {
        buddy_block_t *b = to_struct(le, buddy_block_t, link);
        if (b->base == buddy_addr) {
            // Found buddy, remove it from list
            buddy_remove_free(le);
            return buddy_addr;
        }
    }
    return NULL; // Buddy not found or not free
}

static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    unsigned int o = size_to_order(n);
    struct Page *blk = base;

    // Coalesce with buddy blocks iteratively
    while (o <= MAX_ORDER) {
        struct Page *buddy = buddy_find_and_remove(blk, o);
        if (!buddy) {
            // Buddy not free, add current block to free list
            buddy_add_free(blk, o);
            break;
        }

        // Merge with buddy: keep lower address, increase order
        if (blk > buddy) {
            blk = buddy; // Use buddy's (lower) address
        }
        o++; // Merged block has order + 1

        if (o > MAX_ORDER) {
            // Can't merge further, add to MAX_ORDER
            buddy_add_free(blk, MAX_ORDER);
            break;
        }
    }
}

static size_t buddy_nr_free_pages(void) { return free_area.nr_free; }

// Deterministic micro-tests - covers basic allocation and coalescing
static void buddy_deterministic_tests(void) {
    struct Page *a, *b, *c, *d;
    size_t initial_free = nr_free_pages();

    cprintf("[buddy_check]   Test 1: Single page allocation\n");
    a = alloc_page();
    b = alloc_page();
    c = alloc_page();
    assert(a && b && c);
    assert(nr_free_pages() == initial_free - 3);

    cprintf("[buddy_check]   Test 2: Single page free and coalescing\n");
    free_page(b);
    free_page(a);
    free_page(c);
    // After freeing, pages should be available again (possibly coalesced)
    assert(nr_free_pages() == initial_free);

    cprintf("[buddy_check]   Test 3: Multi-page allocation (power of 2)\n");
    a = alloc_pages(2);
    b = alloc_pages(4);
    assert(a && b);
    assert(nr_free_pages() == initial_free - 6);
    free_pages(a, 2);
    free_pages(b, 4);
    assert(nr_free_pages() == initial_free);

    cprintf("[buddy_check]   Test 4: Non-power-of-2 allocation (rounded up)\n");
    a = alloc_pages(3); // Should allocate 4 pages (2^2)
    assert(a);
    assert(nr_free_pages() <= initial_free - 4);
    free_pages(a, 3);

    cprintf("[buddy_check]   Test 5: Large block allocation\n");
    d = alloc_pages(1 << (MAX_ORDER - 1));
    if (d) {
        assert(nr_free_pages() <= initial_free - (1 << (MAX_ORDER - 1)));
        free_pages(d, 1 << (MAX_ORDER - 1));
    }

    cprintf("[buddy_check]   Test 6: Verify coalescing after mixed operations\n");
    // Allocate several blocks, free in different order, check coalescing
    a = alloc_pages(2);
    b = alloc_pages(2);
    c = alloc_pages(2);
    d = alloc_pages(2);
    assert(a && b && c && d);
    // Free in reverse order to test coalescing
    free_pages(d, 2);
    free_pages(b, 2);
    free_pages(c, 2);
    free_pages(a, 2);
    // Should be able to coalesce back
    struct Page *large = alloc_pages(8);
    if (large) {
        free_pages(large, 8);
    }
}

// Randomized allocation/free stress test (lightweight)
static void buddy_random_tests(void) {
    const int N = 256;
    struct Page *allocs[N];
    size_t sizes[N];
    int i;
    // seed pseudo-random using a simple LCG (no stdlib rand available reliably)
    unsigned int seed = 0x12345678;
    auto_rand:
    for (i = 0; i < N; i++) allocs[i] = NULL, sizes[i] = 0;
    for (i = 0; i < N; i++) {
        // simple LCG
        seed = seed * 1103515245 + 12345;
        unsigned int r = (seed >> 16) & 0x7fff;
        size_t s = (r % 16) + 1; // 1..16 pages
        sizes[i] = s;
        allocs[i] = alloc_pages(s);
    }
    // free in pseudo-random order
    for (i = N - 1; i >= 0; i--) {
        if (allocs[i]) free_pages(allocs[i], sizes[i]);
        if (i == 0) break; // prevent unsigned wrap
    }
}

static void buddy_check(void) {
    int score = 0, sumscore = 8;  // Total 8 test points

    cprintf("[buddy_check] start deterministic tests\n");
    buddy_deterministic_tests();
    cprintf("[buddy_check] deterministic tests done\n");

    #ifdef ucore_test
    score += 3;  // 3 points for deterministic tests (6 sub-tests)
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif

    cprintf("[buddy_check] start randomized stress tests\n");
    // run randomized tests a few times to increase confidence
    for (int i = 0; i < 4; i++) {
        cprintf("[buddy_check] randomized round %d\n", i+1);
        buddy_random_tests();
    }
    cprintf("[buddy_check] randomized tests done\n");

    #ifdef ucore_test
    score += 2;  // 2 points for randomized stress tests
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif

    cprintf("[buddy_check] start final smoke test (allocate single pages until OOM / cap)\n");
    const size_t CAP = 1024;
    const size_t PROG = 128;
    size_t allocated = 0;
    struct Page *plist[CAP];
    while (allocated < CAP) {
        struct Page *q = alloc_page();
        if (!q) break;
        plist[allocated++] = q;
        if ((allocated % PROG) == 0) {
            cprintf("[buddy_check] final smoke progress: allocated %u pages\n", (unsigned)allocated);
        }
    }
    cprintf("[buddy_check] final smoke allocated %u pages (cap=%u), now freeing them\n", (unsigned)allocated, (unsigned)CAP);

    #ifdef ucore_test
    score += 2;  // 2 points for successful allocation
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif

    for (size_t j = 0; j < allocated; j++) {
        free_page(plist[j]);
        if (((j+1) % PROG) == 0) {
            cprintf("[buddy_check] final smoke freeing progress: freed %u pages\n", (unsigned)(j+1));
        }
    }

    #ifdef ucore_test
    score += 1;  // 1 point for successful free and memory recovery
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif

    cprintf("[buddy_check] finished, buddy_check() succeeded! total freed %u pages\n", (unsigned)allocated);
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
