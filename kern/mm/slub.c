/* Simple SLUB-like allocator for ucore lab
 * Two-layer design:
 *  - Layer 1: uses page allocator (alloc_page/alloc_pages) as backing.
 *  - Layer 2: per-size caches (power-of-two size classes) that maintain free lists of objects inside pages.
 * This is a simplified educational implementation.
 */

#include <slub.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#define SLUB_MIN_SHIFT 3    // 8 bytes
#define SLUB_MAX_SHIFT 12   // 4096 bytes (one page)
#define SLUB_NCACHE (SLUB_MAX_SHIFT - SLUB_MIN_SHIFT + 1)

typedef struct obj_head {
    struct obj_head *next;
} obj_head_t;

typedef struct slab_page {
    struct slab_page *next; // next slab in cache
    obj_head_t *free_list;  // free objects in this slab
    unsigned used;          // number of used objects
    unsigned obj_per_page;  // number of objects in this page
    unsigned cache_idx;     // which cache this slab belongs to (for kfree)
} slab_page_t;

typedef struct slub_cache {
    size_t obj_size;
    slab_page_t *pages; // list of slab_page
} slub_cache_t;

static slub_cache_t caches[SLUB_NCACHE];

static inline int size_to_index(size_t size) {
    size_t s = 1 << SLUB_MIN_SHIFT;
    int i = 0;
    while (s < size && i < SLUB_NCACHE - 1) { s <<= 1; i++; }
    return i;
}

static void cache_init(slub_cache_t *c, size_t size) {
    c->obj_size = size;
    c->pages = NULL;
}

static void slab_page_init(slab_page_t *sp, size_t obj_size, unsigned cache_idx) {
    sp->next = NULL;
    sp->used = 0;
    sp->free_list = NULL;
    sp->obj_per_page = (PGSIZE - sizeof(slab_page_t)) / obj_size;
    sp->cache_idx = cache_idx;
    // build free list within the page memory area after slab_page header
    uintptr_t base = (uintptr_t)sp + sizeof(slab_page_t);
    // align base to obj_size
    uintptr_t aligned = (base + obj_size - 1) & ~(obj_size - 1);
    obj_head_t *prev = NULL;
    for (unsigned i = 0; i < sp->obj_per_page; i++) {
        obj_head_t *o = (obj_head_t *)(aligned + i * obj_size);
        o->next = prev;
        prev = o;
    }
    sp->free_list = prev;
}

void slub_init(void) {
    for (int i = 0; i < SLUB_NCACHE; i++) {
        caches[i].obj_size = (1 << (SLUB_MIN_SHIFT + i));
        caches[i].pages = NULL;
    }
    cprintf("[slub] init: %d caches from %u to %u bytes\n", SLUB_NCACHE,
            (unsigned)caches[0].obj_size, (unsigned)caches[SLUB_NCACHE - 1].obj_size);
}

static slab_page_t *alloc_slab_page(slub_cache_t *c, unsigned cache_idx) {
    // allocate one page via pmm
    struct Page *pg = alloc_page();
    if (!pg) return NULL;
    void *va = (void *)page2pa(pg); // use physical-to-virtual mapping? in ucore pages are mapped at KERNBASE+pa
    // For simplicity in this educational environment, assume KERNBASE + pa maps to VA
    void *kva = (void *)((uintptr_t)va + va_pa_offset);
    slab_page_t *sp = (slab_page_t *)kva;
    memset(sp, 0, PGSIZE);
    slab_page_init(sp, c->obj_size, cache_idx);
    sp->next = c->pages;
    c->pages = sp;
    return sp;
}

void *kmalloc(size_t size) {
    if (size == 0) return NULL;
    if (size > (1U << SLUB_MAX_SHIFT)) {
        // large allocation: allocate whole pages
        size_t np = (size + PGSIZE - 1) / PGSIZE;
        struct Page *pg = alloc_pages(np);
        if (!pg) return NULL;
        void *pa = (void *)page2pa(pg);
        return (void *)((uintptr_t)pa + va_pa_offset);
    }
    int idx = size_to_index(size);
    slub_cache_t *c = &caches[idx];
    slab_page_t *sp = c->pages;
    while (sp) {
        if (sp->free_list) break;
        sp = sp->next;
    }
    if (!sp) {
        sp = alloc_slab_page(c, idx);
        if (!sp) return NULL;
    }
    obj_head_t *obj = sp->free_list;
    sp->free_list = obj->next;
    sp->used++;
    return (void *)obj;
}

void kfree(void *ptr) {
    if (!ptr) return;

    // Find which slab page this object belongs to
    // Align down to page boundary to get slab_page header
    uintptr_t page_addr = (uintptr_t)ptr & ~(PGSIZE - 1);
    slab_page_t *sp = (slab_page_t *)page_addr;

    // Validate that this is a slab page (cache_idx should be valid)
    if (sp->cache_idx >= SLUB_NCACHE) {
        // This might be a large allocation, try to free as pages
        // For simplicity, we cannot reliably free large allocations without metadata
        // In production, would need to track large allocations separately
        return; // Leak large allocations in this simplified implementation
    }

    // Return object to the slab's free list
    obj_head_t *o = (obj_head_t *)ptr;
    o->next = sp->free_list;
    sp->free_list = o;
    sp->used--;

    // Optional: if slab is completely empty, consider returning page to pmm
    // (Not implemented here to keep it simple)
}

// Comprehensive SLUB test suite
void slub_check(void) {
    cprintf("[slub] slub_check start\n");

    // Test 1: Basic allocation and free for each size class
    cprintf("[slub]   Test 1: All size classes (8, 16, 32, ..., 4096 bytes)\n");
    void *ptrs[SLUB_NCACHE];
    for (int i = 0; i < SLUB_NCACHE; i++) {
        size_t size = 1 << (SLUB_MIN_SHIFT + i);
        ptrs[i] = kmalloc(size);
        assert(ptrs[i] != NULL);
        // Write pattern to verify no corruption
        if (size >= 4) {
            *(unsigned int *)ptrs[i] = 0xDEADBEEF;
        }
    }
    // Free in reverse order
    for (int i = SLUB_NCACHE - 1; i >= 0; i--) {
        if (ptrs[i]) {
            size_t size = 1 << (SLUB_MIN_SHIFT + i);
            if (size >= 4) {
                assert(*(unsigned int *)ptrs[i] == 0xDEADBEEF);
            }
            kfree(ptrs[i]);
        }
    }

    // Test 2: Multiple allocations from same size class
    cprintf("[slub]   Test 2: Multiple objects from same cache (64 bytes)\n");
    void *objs[32];
    for (int i = 0; i < 32; i++) {
        objs[i] = kmalloc(64);
        assert(objs[i] != NULL);
        // Write unique pattern
        *(int *)objs[i] = i;
    }
    // Verify and free
    for (int i = 0; i < 32; i++) {
        assert(*(int *)objs[i] == i);
        kfree(objs[i]);
    }

    // Test 3: Alternating allocation and free
    cprintf("[slub]   Test 3: Alternating alloc/free pattern\n");
    for (int i = 0; i < 16; i++) {
        void *p1 = kmalloc(16);
        void *p2 = kmalloc(32);
        void *p3 = kmalloc(64);
        assert(p1 && p2 && p3);
        kfree(p2);
        void *p4 = kmalloc(32); // Should reuse freed object
        assert(p4 != NULL);
        kfree(p1);
        kfree(p3);
        kfree(p4);
    }

    // Test 4: Small vs large allocations
    cprintf("[slub]   Test 4: Edge cases (very small and boundary sizes)\n");
    void *tiny = kmalloc(1);  // Should use 8-byte cache
    void *small = kmalloc(8);
    void *boundary = kmalloc(4096); // Exactly one page
    assert(tiny && small && boundary);
    kfree(tiny);
    kfree(small);
    kfree(boundary);

    // Test 5: Stress test with many small objects
    cprintf("[slub]   Test 5: Stress test (256 objects, various sizes)\n");
    void *stress_objs[256];
    size_t stress_sizes[256];
    unsigned seed = 0x1234;
    int alloc_count = 0;
    for (int i = 0; i < 256; i++) {
        seed = seed * 1103515245 + 12345;
        size_t s = ((seed >> 16) % 1024) + 1; // 1..1024
        stress_sizes[i] = s;
        stress_objs[i] = kmalloc(s);
        if (stress_objs[i]) {
            alloc_count++;
            // Write size as verification
            if (s >= sizeof(size_t)) {
                *(size_t *)stress_objs[i] = s;
            }
        }
    }
    cprintf("[slub]     Allocated %d objects successfully\n", alloc_count);

    // Verify and free in random order
    for (int i = 255; i >= 0; i--) {
        if (stress_objs[i]) {
            size_t s = stress_sizes[i];
            if (s >= sizeof(size_t)) {
                assert(*(size_t *)stress_objs[i] == s);
            }
            kfree(stress_objs[i]);
        }
    }

    // Test 6: Verify different size classes don't interfere
    cprintf("[slub]   Test 6: Cache isolation test\n");
    void *a16 = kmalloc(16);
    void *a32 = kmalloc(32);
    void *a64 = kmalloc(64);
    *(int *)a16 = 16;
    *(int *)a32 = 32;
    *(int *)a64 = 64;
    kfree(a32);
    void *b32 = kmalloc(32);
    assert(b32 != NULL);
    // Verify other objects not corrupted
    assert(*(int *)a16 == 16);
    assert(*(int *)a64 == 64);
    kfree(a16);
    kfree(b32);
    kfree(a64);

    // Test 7: NULL pointer handling
    cprintf("[slub]   Test 7: NULL pointer handling\n");
    kfree(NULL); // Should not crash
    void *zero_size = kmalloc(0); // Should return NULL
    assert(zero_size == NULL);

    cprintf("[slub] slub_check done - all tests passed!\n");
}
