# 实验二：物理内存管理 - 实验报告

**小组成员：** [填写小组成员]
**完成日期：** 2025年10月

---

## 目录

1. [练习0：填写已有实验](#练习0填写已有实验)
2. [练习1：理解 first-fit 连续物理内存分配算法](#练习1理解-first-fit-连续物理内存分配算法)
3. [练习2：实现 Best-Fit 连续物理内存分配算法](#练习2实现-best-fit-连续物理内存分配算法)
4. [扩展练习 Challenge 1：Buddy System 分配算法](#扩展练习-challenge-1buddy-system-分配算法)
5. [扩展练习 Challenge 2：SLUB 分配算法](#扩展练习-challenge-2slub-分配算法)
6. [扩展练习 Challenge 3：硬件可用物理内存范围的获取方法](#扩展练习-challenge-3硬件可用物理内存范围的获取方法)
7. [与参考答案的比较](#与参考答案的比较)
8. [本实验的重要知识点](#本实验的重要知识点)
9. [总结](#总结)

---

## 练习0：填写已有实验

本实验依赖实验1的代码。我们已将实验1中完成的代码（包括中断处理、时钟中断等）填入本实验相应的LAB1标注部分，并根据实验手册完成了后续的物理内存管理相关修改。

---

## 练习1：理解 first-fit 连续物理内存分配算法

### 1.1 实验目标

理解 `first-fit` 连续物理内存分配算法在 ucore 中的具体实现，分析 `kern/mm/default_pmm.c` 中各函数的作用和物理内存分配的完整流程。

### 1.2 核心数据结构

ucore 使用以下数据结构管理物理页：

- **`struct Page`** ([kern/mm/memlayout.h](kern/mm/memlayout.h))
  - `ref`：页引用计数
  - `flags`：页标志位（`PG_reserved`、`PG_property` 等）
  - `property`：若此页是空闲块头页，记录该块的页数；否则为0
  - `page_link`：链表节点，用于将空闲块头页串入 `free_list`

- **`free_area_t`** ([kern/mm/memlayout.h](kern/mm/memlayout.h))
  - `free_list`：循环双向链表头，串联所有空闲块
  - `nr_free`：当前空闲页总数

### 1.3 关键函数分析

#### 1.3.1 `default_init()`

**作用**：初始化 first-fit 管理器的内部数据结构。

```c
static void default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}
```

**说明**：将空闲链表初始化为空，空闲页计数置零。

#### 1.3.2 `default_init_memmap(struct Page *base, size_t n)`

**作用**：将一段连续的物理页（从 `base` 开始，长度 `n`）初始化为一个空闲块并插入 `free_list`。

**实现要点**：
1. 清除段内每页的 `flags` 和 `property`，将 `ref` 设为 0
2. 对首页 `base` 设置 `property = n` 并标记 `PG_property`
3. 更新 `nr_free += n`
4. 按物理地址升序将 `base` 插入 `free_list`

```c
static void default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```

**说明**：保持链表按地址有序，便于后续合并相邻空闲块。

#### 1.3.3 `default_alloc_pages(size_t n)`

**作用**：按 first-fit 策略分配连续的 `n` 页。

**实现要点**：
1. 若 `n > nr_free` 则直接返回 NULL
2. 遍历 `free_list`，找到第一个 `property >= n` 的块
3. 从链表中删除该块
4. 若块大小 > n，则分裂：在 `base + n` 处创建新空闲块，插回链表
5. 更新 `nr_free -= n`，清除分配页的 `PG_property` 标志
6. 返回块首页指针

```c
static struct Page *default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

**说明**：first-fit 在找到第一个满足条件的块后立即返回，时间复杂度 O(m)，m 为空闲块数量。

#### 1.3.4 `default_free_pages(struct Page *base, size_t n)`

**作用**：释放以 `base` 为起始的连续 `n` 页，并尝试与前后空闲块合并。

**实现要点**：
1. 清除范围内每页的 flags，将 ref 置 0
2. 设置 `base->property = n` 并标记 `PG_property`
3. 更新 `nr_free += n`
4. 按地址顺序插入 `free_list`
5. 检查并合并前向和后向相邻的空闲块

```c
static void default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    /* 合并前后的空闲块 */
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```

**说明**：通过合并相邻空闲块减少外部碎片。

### 1.4 物理内存分配流程

系统启动时的完整流程：

1. **`pmm_init()`** → **`init_pmm_manager()`**：选择 pmm_manager（如 `default_pmm_manager`），调用其 `init()`
2. **`page_init()`**：解析 DTB/e820/UEFI 获取物理内存布局，构造 `pages` 数组，调用 `init_memmap()` 将可用内存区域加入管理
3. **`check_alloc_page()`**：调用 `pmm_manager->check()` 验证实现正确性
4. 运行时：模块通过 `alloc_pages(n)` 和 `free_pages(base, n)` 进行内存分配和释放

### 1.5 first-fit 的改进空间

**优点**：
- 实现简单，易于理解
- 在空闲块较少时性能尚可

**不足与改进方向**：

1. **性能优化**
   - 当前实现：线性遍历链表，时间复杂度 O(m)
   - 改进方案：
     - next-fit：记录上次分配位置，从该位置继续查找
     - 分级链表：按块大小分组，快速定位合适块
     - 树/位图索引：使用红黑树或位图加速查找

2. **碎片控制**
   - 当前实现：first-fit 易产生外部碎片（链表前部留下大量小块）
   - 改进方案：
     - best-fit：选择最小满足块，减少剩余碎片
     - 设置分裂阈值：若剩余块过小则不分裂
     - 对小对象使用 slab 分配器

3. **并发支持**
   - 当前实现：无锁保护，仅适用于单核或内核初始化阶段
   - 改进方案：
     - 引入自旋锁或互斥锁
     - per-CPU 缓存减少锁竞争
     - 无锁数据结构（如 lock-free 链表）

---

## 练习2：实现 Best-Fit 连续物理内存分配算法

### 2.1 实验目标

在 ucore 的 pmm 框架下实现 Best-Fit 连续内存分配器，通过内置的 `best_fit_check()` 验证功能正确性。

### 2.2 实现要点

Best-Fit 与 First-Fit 的主要区别在于分配策略：

- **First-Fit**：找到第一个满足 `property >= n` 的块即返回
- **Best-Fit**：遍历整个链表，选择最小的满足 `property >= n` 的块

**修改文件**：[kern/mm/best_fit_pmm.c](kern/mm/best_fit_pmm.c)

### 2.3 核心实现：`best_fit_alloc_pages()`

```c
static struct Page *best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;

    /* Best-fit: 遍历整个链表，选择最小满足需求的块 */
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && p->property < min_size) {
            min_size = p->property;
            page = p;
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

**说明**：通过遍历完整链表并记录 `min_size`，选择最合适的块进行分配，以期减少外部碎片。

### 2.4 其他函数实现

`best_fit_init()`、`best_fit_init_memmap()`、`best_fit_free_pages()` 的实现与 `default_pmm.c` 基本一致，保持接口统一和行为一致性。

### 2.5 测试与验证

在 [kern/mm/pmm.c](kern/mm/pmm.c) 中切换 pmm_manager：

```c
pmm_manager = &best_fit_pmm_manager;
```

编译运行：

```bash
make clean && make && make qemu
```

**测试输出**：

```
memory management: best_fit_pmm_manager
check_alloc_page() succeeded!
```

说明 Best-Fit 实现通过了框架的自检测试。

### 2.6 Best-Fit vs First-Fit 示例对比

**场景**：空闲链表中有三个块：

- 块 A：size = 6 pages（链表头）
- 块 B：size = 2 pages
- 块 C：size = 3 pages

请求 `alloc_pages(2)`：

- **First-Fit**：选择块 A（第一个满足的），分裂后剩余 4 pages（可能产生较大碎片）
- **Best-Fit**：选择块 B（size = 2，正好匹配），无剩余，减少碎片

### 2.7 Best-Fit 的改进空间

**优点**：
- 减少某些场景下的外部碎片
- 对固定大小的频繁分配效果较好

**不足与改进方向**：

1. **性能**
   - 问题：必须遍历整个链表，时间复杂度 O(m)
   - 改进：使用分级桶、红黑树等数据结构加速查找

2. **碎片**
   - 问题：虽然减少大碎片，但可能产生许多不可用的小碎片
   - 改进：结合阈值策略，或对小对象使用 slab

3. **并发**
   - 问题：无锁保护
   - 改进：引入锁或 per-CPU 缓存

---

## 扩展练习 Challenge 1：Buddy System 分配算法

### 3.1 目标与背景

实现一个教学级的 Buddy System（伙伴系统）物理内存分配器，通过在引导时自动运行的自检验证功能正确性。

**核心思想**：

- 将内存划分为 2^k 大小的块（k 称为 order）
- 维护 0 到 MAX_ORDER 的空闲链表
- 分配时：若当前 order 无空闲块，从更高 order 拆分
- 释放时：尝试与 buddy 块合并，减少碎片

### 3.2 设计概述

**关键概念**：

- **MAX_ORDER**：设为 10，管理 2^0 到 2^10 页（最大 4MB）
- **Buddy 块**：两个大小相同、地址连续、合并后对齐的块互为 buddy
- **Buddy 计算**：`buddy_index = current_index XOR (1 << order)`

**数据结构**：

```c
typedef struct buddy_block {
    list_entry_t link;       // 链表节点
    unsigned int order;      // 块的 order
    struct Page *base;       // 块的起始页
} buddy_block_t;

static list_entry_t free_lists[MAX_ORDER + 1];  // 每个 order 一个链表
static free_area_t free_area;                    // 保存 nr_free
```

**文件位置**：[kern/mm/buddy_pmm.c](kern/mm/buddy_pmm.c)

### 3.3 关键实现

#### 3.3.1 `buddy_init()`

初始化所有 order 的空闲链表：

```c
static void buddy_init(void) {
    int i;
    cprintf("[buddy] buddy_init() start\n");
    for (i = 0; i <= MAX_ORDER; i++)
        list_init(&free_lists[i]);
    free_area.nr_free = 0;
    max_order_inited = 0;
    cprintf("[buddy] buddy_init() done\n");
}
```

#### 3.3.2 `size_to_order(n)`

计算满足 2^order >= n 的最小 order：

```c
static unsigned int size_to_order(unsigned int n) {
    unsigned int o = 0;
    unsigned int s = 1;
    while (s < n) { s <<= 1; o++; }
    return o;
}
```

#### 3.3.3 `buddy_init_memmap(base, n)`

将连续的 n 页拆分为多个 2^k 块并加入相应的 free_lists：

```c
static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    cprintf("[buddy] buddy_init_memmap: base=%p n=%u\n", base, (unsigned)n);

    // 清除页标志
    struct Page *p = base;
    for (; p < base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }

    // 拆分为 2^k 块
    size_t remain = n;
    struct Page *cur = base;
    while (remain > 0) {
        unsigned int o = 0;
        while ((1UL << (o + 1)) <= remain) o++;
        if (o > MAX_ORDER) {
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
    cprintf("[buddy] buddy_init_memmap: finished, total free pages=%u\n",
            (unsigned)free_area.nr_free);
}
```

#### 3.3.4 `buddy_alloc_pages(n)`

从合适的 order 分配，若无空闲块则从更高 order 拆分：

```c
static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0 || n > free_area.nr_free) return NULL;
    unsigned int need_order = size_to_order(n);
    unsigned int o;

    // 查找第一个非空的 free_list
    for (o = need_order; o <= MAX_ORDER; o++) {
        if (!list_empty(&free_lists[o])) break;
    }
    if (o > MAX_ORDER) return NULL;

    // 取出块并拆分
    list_entry_t *le = list_next(&free_lists[o]);
    struct Page *blk = buddy_remove_free(le);
    while (o > need_order) {
        o--;
        struct Page *buddy = blk + (1UL << o);
        buddy_add_free(buddy, o);
    }
    ClearPageProperty(blk);
    return blk;
}
```

#### 3.3.5 `buddy_free_pages(base, n)` - 关键：合并逻辑

释放时迭代查找并合并 buddy 块，直到无法继续合并：

```c
static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    unsigned int o = size_to_order(n);
    struct Page *blk = base;

    // 迭代合并 buddy 块
    while (o <= MAX_ORDER) {
        struct Page *buddy = buddy_find_and_remove(blk, o);
        if (!buddy) {
            // Buddy 不在空闲列表中，无法合并
            buddy_add_free(blk, o);
            break;
        }

        // 合并：保留低地址作为新块起始
        if (blk > buddy) {
            blk = buddy;
        }
        o++;

        if (o > MAX_ORDER) {
            buddy_add_free(blk, MAX_ORDER);
            break;
        }
    }
}
```

**buddy_find_and_remove() 实现**：

```c
static struct Page *buddy_find_and_remove(struct Page *base, unsigned int order) {
    // 计算 buddy 地址：索引 XOR (1 << order)
    uintptr_t idx = page_index(base);
    uintptr_t buddy_idx = idx ^ (1UL << order);
    struct Page *buddy_addr = pages + buddy_idx;

    // 在 free_lists[order] 中查找
    list_entry_t *le = &free_lists[order];
    while ((le = list_next(le)) != &free_lists[order]) {
        buddy_block_t *b = to_struct(le, buddy_block_t, link);
        if (b->base == buddy_addr) {
            buddy_remove_free(le);
            return buddy_addr;
        }
    }
    return NULL;
}
```

**说明**：通过 XOR 运算快速定位 buddy，若 buddy 空闲则合并，否则直接插入当前 order 链表。

### 3.4 测试与验证

**测试函数**：`buddy_check()` 包含三个阶段：

1. **确定性测试**：分配和释放固定模式的块
2. **随机化测试**：随机大小的分配/释放序列（4轮）
3. **Final smoke 测试**：持续分配单页直到 OOM，然后全部释放

**运行方法**：

在 [pmm.c:44](kern/mm/pmm.c#L44) 设置：

```c
pmm_manager = &buddy_pmm_manager;
```

编译运行：

```bash
make clean && make && make qemu
```

**预期输出**：

```
memory management: buddy_pmm_manager
[buddy] buddy_init() start
[buddy] buddy_init() done
[buddy] buddy_init_memmap: base=0xffffffffc020e2f0 n=31930
[buddy] buddy_init_memmap: finished, total free pages=31930
[buddy_check] start deterministic tests
[buddy_check] deterministic tests done
[buddy_check] start randomized stress tests
[buddy_check] randomized round 1
[buddy_check] randomized round 2
[buddy_check] randomized round 3
[buddy_check] randomized round 4
[buddy_check] randomized tests done
[buddy_check] start final smoke test (allocate single pages until OOM / cap)
[buddy_check] final smoke allocated 1024 pages (cap=1024), now freeing them
[buddy_check] finished, buddy_check() succeeded!
check_alloc_page() succeeded!
```

### 3.5 算法正确性分析

**合并验证**：

1. 释放块后，系统尝试与 buddy 合并
2. 若 buddy 空闲，则从相应 order 的链表中移除，合并为更高 order 的块
3. 迭代继续，直到 buddy 不空闲或达到 MAX_ORDER

**测试覆盖**：

- 确定性测试验证基本分配/释放功能
- 随机测试覆盖多种大小和顺序组合
- Smoke 测试验证高压下的稳定性和资源回收

### 3.6 改进空间

1. **性能优化**
   - 当前：链性查找 buddy，O(m)
   - 改进：使用位图或树结构加速定位

2. **一致性检查**
   - 实现 `buddy_check_consistency()`，遍历所有链表，验证：
     - 块按 order 对齐
     - 无重叠
     - nr_free 统计准确

3. **并发支持**
   - 引入 per-CPU free lists
   - 使用细粒度锁减少竞争

---

## 扩展练习 Challenge 2：SLUB 分配算法

### 4.1 目标与背景

实现一个教学级的 SLUB 风格内存分配器，在页分配器之上实现任意大小对象的分配（`kmalloc`/`kfree`）。

**核心思想**：

- **两层架构**：
  - 第一层：页分配器（`alloc_pages`/`free_pages`）
  - 第二层：对象分配器（按 size class 缓存）
- **Size class**：8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 字节
- **Slab page**：每个 size class 维护若干 slab（单页），页内对象用空闲链表管理

### 4.2 设计概述

**数据结构**：

```c
typedef struct slab_page {
    struct slab_page *next;   // 下一个 slab
    obj_head_t *free_list;    // 空闲对象链表
    unsigned used;            // 已分配对象数
    unsigned obj_per_page;    // 页内对象总数
    unsigned cache_idx;       // 所属 cache 索引（用于 kfree 定位）
} slab_page_t;

typedef struct slub_cache {
    size_t obj_size;          // 对象大小
    slab_page_t *pages;       // slab 链表
} slub_cache_t;

static slub_cache_t caches[SLUB_NCACHE];  // 10个 size class
```

**文件位置**：[kern/mm/slub.c](kern/mm/slub.c)

### 4.3 关键实现

#### 4.3.1 `slub_init()`

初始化所有 size class 的 cache：

```c
void slub_init(void) {
    for (int i = 0; i < SLUB_NCACHE; i++) {
        caches[i].obj_size = (1 << (SLUB_MIN_SHIFT + i));
        caches[i].pages = NULL;
    }
    cprintf("[slub] init: %d caches from %u to %u bytes\n", SLUB_NCACHE,
            (unsigned)caches[0].obj_size, (unsigned)caches[SLUB_NCACHE - 1].obj_size);
}
```

#### 4.3.2 `slab_page_init()` - 创建空闲对象链表

在分配的页内初始化 slab_page 并构建对象空闲链表：

```c
static void slab_page_init(slab_page_t *sp, size_t obj_size, unsigned cache_idx) {
    sp->next = NULL;
    sp->used = 0;
    sp->free_list = NULL;
    sp->obj_per_page = (PGSIZE - sizeof(slab_page_t)) / obj_size;
    sp->cache_idx = cache_idx;

    // 构建空闲链表
    uintptr_t base = (uintptr_t)sp + sizeof(slab_page_t);
    uintptr_t aligned = (base + obj_size - 1) & ~(obj_size - 1);
    obj_head_t *prev = NULL;
    for (unsigned i = 0; i < sp->obj_per_page; i++) {
        obj_head_t *o = (obj_head_t *)(aligned + i * obj_size);
        o->next = prev;
        prev = o;
    }
    sp->free_list = prev;
}
```

#### 4.3.3 `kmalloc(size)` - 分配对象

```c
void *kmalloc(size_t size) {
    if (size == 0) return NULL;

    // 大对象直接分配页
    if (size > (1U << SLUB_MAX_SHIFT)) {
        size_t np = (size + PGSIZE - 1) / PGSIZE;
        struct Page *pg = alloc_pages(np);
        if (!pg) return NULL;
        void *pa = (void *)page2pa(pg);
        return (void *)((uintptr_t)pa + va_pa_offset);
    }

    // 选择合适的 cache
    int idx = size_to_index(size);
    slub_cache_t *c = &caches[idx];

    // 查找有空闲对象的 slab
    slab_page_t *sp = c->pages;
    while (sp) {
        if (sp->free_list) break;
        sp = sp->next;
    }

    // 若无可用 slab，分配新页
    if (!sp) {
        sp = alloc_slab_page(c, idx);
        if (!sp) return NULL;
    }

    // 从空闲链表中取对象
    obj_head_t *obj = sp->free_list;
    sp->free_list = obj->next;
    sp->used++;
    return (void *)obj;
}
```

#### 4.3.4 `kfree(ptr)` - 释放对象

通过页对齐定位 slab_page，将对象归还到空闲链表：

```c
void kfree(void *ptr) {
    if (!ptr) return;

    // 对齐到页边界获取 slab_page
    uintptr_t page_addr = (uintptr_t)ptr & ~(PGSIZE - 1);
    slab_page_t *sp = (slab_page_t *)page_addr;

    // 验证 cache_idx 有效性
    if (sp->cache_idx >= SLUB_NCACHE) {
        // 可能是大对象，简化实现中选择泄漏
        return;
    }

    // 归还对象到空闲链表
    obj_head_t *o = (obj_head_t *)ptr;
    o->next = sp->free_list;
    sp->free_list = o;
    sp->used--;

    // 可选：若 slab 完全空闲，考虑归还页给 pmm
}
```

**关键设计**：

- **cache_idx 字段**：记录 slab 所属的 cache 索引，使 `kfree()` 能正确定位
- **页对齐定位**：通过 `ptr & ~(PGSIZE - 1)` 快速找到 slab_page header

### 4.4 测试与验证

**测试函数**：`slub_check()` 包含：

1. **确定性测试**：分配和释放固定大小对象（16、32、64 字节）
2. **随机化测试**：随机大小（1-1024 字节）的分配/释放序列（256次）

**运行方法**：

在 [pmm.c:130-131](kern/mm/pmm.c#L130-L131) 中已集成：

```c
slub_init();
slub_check();
```

**预期输出**：

```
[slub] init: 10 caches from 8 to 4096 bytes
[slub] slub_check start
[slub] slub_check done
```

### 4.5 算法正确性分析

**空闲链表管理**：

- 每个对象本身的内存空间用于存储 `next` 指针
- 分配时从链表头取对象，释放时插回链表头
- 通过 `sp->used` 计数跟踪已分配对象数

**Cache 选择**：

- `size_to_index()` 选择第一个 >= 请求大小的 size class
- 保证分配的对象足够大，避免溢出

### 4.6 改进空间

1. **kfree 可靠性**
   - 当前：通过页对齐定位 slab_page，限制每 slab 为单页
   - 改进：在 `struct Page` 中增加 slab 元数据指针，或在对象前写 header

2. **Slab 回收策略**
   - 当前：空 slab 不回收
   - 改进：当 `used == 0` 且空 slab 数超过阈值时，归还页给 pmm

3. **并发优化**
   - 引入 per-CPU caches
   - 对每个 cache 使用细粒度锁

4. **一致性检查**
   - 实现 `slub_check_consistency()`，验证：
     - free_list 长度 = obj_per_page - used
     - 无对象重叠
     - 统计正确

---

## 扩展练习 Challenge 3：硬件可用物理内存范围的获取方法

### 5.1 问题背景

如果 OS 无法提前知道当前硬件的可用物理内存范围，需要有方法让 OS 自行获取。

### 5.2 方法总结（按优先级）

#### 5.2.1 固件/引导器提供的内存表（首选，安全可靠）

1. **UEFI GetMemoryMap()**
   - 返回 EFI_MEMORY_DESCRIPTOR 数组，包含类型、物理地址、页数
   - 类型包括：Conventional、Reserved、ACPI、MMIO 等

2. **BIOS e820**
   - x86 legacy BIOS 中断 INT 15h, AX=E820h
   - 返回内存区域列表及类型（可用/保留/ACPI/NVS）

3. **Device Tree (DTB)**
   - ARM/RISC-V 平台标准
   - 在 `/memory` 节点的 `reg` 字段中描述物理内存范围
   - 本实验使用的方法（见 [kern/driver/dtb.c](kern/driver/dtb.c)）

4. **Multiboot / Bootinfo**
   - GRUB 等引导器传递内存映射给内核
   - 通过 multiboot_info_t 结构体获取

5. **Hypervisor / Cloud Metadata**
   - Xen/KVM/QEMU 的 hypercall 或 virtio 接口
   - 云平台的 metadata API

#### 5.2.2 ACPI / 平台表（补充信息）

- 用于识别保留区域、NUMA 布局等
- 并非直接的内存映射源，需结合其他方法

#### 5.2.3 受控物理探测（最后手段，危险）

**仅在无固件信息时使用，风险高，需严格受控。**

**基本原理**：

- 对物理地址进行小心的读/写探测
- 若能成功读写，认为是 RAM；若触发异常，认为是 MMIO 或不存在

**必要的安全措施**：

1. **粗粒度探测**：步进至少 1 MiB，避免误探测到小型 MMIO 区
2. **异常处理**：捕获机器检查异常（Machine Check Exception）
3. **只读优先**：先尝试读，若读失败则跳过
4. **写入保护**：
   - 禁用所有外设 DMA
   - 避开已知的 PCI MMIO 区域
   - 写入前保存原值，验证后恢复
5. **早期执行**：在设备驱动加载前进行

**伪代码**：

```
probe_base = SAFE_START        // 跳过低地址与已知保留区
probe_limit = PLATFORM_MAX
step = 1 MiB
available_ranges = []

for addr in range(probe_base, probe_limit, step):
    if overlaps_reserved(addr, step):
        continue
    try:
        val = safe_read_physical(addr)
    except MachineCheck:
        continue

    // 可选：写探测（高风险）
    if safe_write_and_verify(addr, PATTERN):
        mark addr..addr+step as RAM
    else:
        maybe_mark_readable_as_ram(addr)

// 合并连续段并减去已知占用
normalize_and_subtract_reserved(available_ranges)
return available_ranges
```

### 5.3 合并与验证

无论使用哪种方法，都需要：

1. **合并区间**：排序、合并重叠和相邻区间
2. **减去保留区**：
   - Kernel image
   - Bootloader / DTB
   - PCI holes
   - 固件保留区
   - 设备专用映射（MMIO）
3. **一致性检查**：页对齐、统计核对
4. **交付 PMM**：调用 `init_memmap()` 逐段初始化，运行 `check()` 验证

### 5.4 动态场景注意事项

- **内存热插拔**：依赖固件/ACPI 事件通知，不应用探测
- **虚拟化**：优先使用 hypervisor API，避免 guest 内部探测
- **MMIO / PCI holes**：维护设备地址黑名单，通过 PCI enumeration 确定设备 BAR

### 5.5 工程实施建议

1. **抽象 memory discovery provider**
   - 实现 UEFI/e820/DTB/hypervisor provider 接口
   - 探测作为可选 provider（需显式开启）

2. **Early init 阶段运行**
   - 仅在非常受控配置下启用探测
   - 由启动参数或编译开关控制

3. **记录来源与可信度**
   - 便于诊断和调试

4. **黑名单机制**
   - 维护 PCI MMIO、固件保留地址黑名单
   - 写探测前关闭 DMA/外设

### 5.6 总结

- **最安全**：依赖固件/引导提供的内存映射（UEFI/e820/DTB/hypervisor）
- **受控探测**：仅作最后手段，必须非常保守
- **关键**：所有发现的区间必须与保留区合并/校验后再交由 pmm 使用

---

## 与参考答案的比较

### 6.1 First-Fit 实现

我们的实现与参考答案 `default_pmm.c` 基本一致：

- 数据结构：使用 `free_list` 和 `nr_free`
- 链表维护：按物理地址升序排列
- 合并策略：释放时检查前后相邻块

### 6.2 Best-Fit 实现

**主要差异**：

- **参考答案**：First-Fit（找到第一个满足条件的块即分配）
- **我们的实现**：Best-Fit（遍历全部空闲块，选择最小满足条件的块）

其他如 `init_memmap`、分裂、合并逻辑保持一致，保证接口一致性。

### 6.3 Buddy System 实现

参考实现可能采用：

- **二叉树表示**：使用 `longest[]` 数组隐式表示二叉树
- **合并策略**：可能在分配时合并，或使用不同的 buddy 查找算法

我们的实现：

- **链表表示**：每个 order 使用独立链表
- **迭代合并**：在 `free_pages` 中显式查找并合并 buddy
- **优点**：实现直观，易于理解和调试

### 6.4 SLUB 实现

参考实现可能包含：

- 多页 slab 支持
- 更复杂的 cache 管理（partial/full/empty 链表）
- 对象前 header 或更复杂的元数据

我们的实现：

- 简化为单页 slab
- 通过页对齐定位 slab_page
- 使用 `cache_idx` 字段辅助 kfree 定位

---

## 本实验的重要知识点

### 7.1 与 OS 原理的对应

| 实验知识点 | OS 原理对应 | 关系与理解 |
|-----------|-----------|----------|
| **物理内存分配算法** | 内存管理：连续分配、伙伴系统、Slab | 实验实现了教学版本，原理强调权衡和优化策略 |
| **First-Fit / Best-Fit** | 动态分区分配算法 | 实验验证了不同策略对碎片的影响 |
| **Buddy System** | 伙伴系统、2^k 分配 | 实验实现了分裂和合并，理解了快速合并的原理 |
| **SLUB / Slab** | 内核对象缓存、两层分配 | 实验简化了实现，原理涉及 per-CPU cache、着色等 |
| **元数据设计** | 内存块描述符、位图、链表 | 实验通过 `struct Page` 理解了元数据与内存块的关联 |
| **链表数据结构** | 双向链表、嵌入式链表 | 实验使用了 Linux 风格的侵入式链表 |
| **内存碎片** | 外部碎片、内部碎片 | 实验通过不同算法对比理解了碎片产生与控制 |
| **DTB/UEFI/e820** | 固件接口、硬件抽象 | 实验使用了 DTB 获取内存布局 |

### 7.2 实验中的知识点总结

1. **连续分配算法的权衡**
   - First-Fit：快速但易产生碎片
   - Best-Fit：减少大碎片但遍历开销大
   - 性能与碎片是核心权衡

2. **Buddy System 的优势**
   - 快速合并：O(1) 计算 buddy 地址
   - 减少碎片：2^k 对齐便于合并
   - 适用于页级分配

3. **Slab/SLUB 的必要性**
   - 解决小对象频繁分配的效率问题
   - 减少内部碎片
   - 提供对象级缓存

4. **元数据设计的重要性**
   - 复用页结构：Buddy 在首页存 block 描述符
   - SLUB 使用页首存 slab_page
   - 权衡：元数据开销 vs 管理效率

5. **测试与验证**
   - 确定性测试：验证基本功能
   - 随机测试：发现边界情况
   - Smoke 测试：验证高压下的稳定性

### 7.3 OS 原理中重要但实验未覆盖的知识点

1. **虚拟内存管理**
   - 页表管理、TLB
   - 页替换算法（LRU、Clock、Working Set）
   - 写时复制（Copy-on-Write）

2. **并发内存分配**
   - 多核锁竞争
   - per-CPU allocator
   - 无锁数据结构

3. **高级分配器特性**
   - NUMA-aware 分配
   - 内存压缩与碎片整理
   - 大页支持（Huge Pages）

4. **内存保护**
   - 段保护、页保护
   - ASLR、DEP/NX
   - Meltdown/Spectre 防护

---

## 总结

### 8.1 实验完成情况

本实验完成了以下内容：

1. ✅ **练习1**：深入理解了 First-Fit 算法及其在 ucore 中的实现
2. ✅ **练习2**：成功实现了 Best-Fit 算法并通过测试
3. ✅ **扩展练习1**：实现了带完整合并逻辑的 Buddy System，通过所有自检
4. ✅ **扩展练习2**：实现了两层 SLUB 分配器，支持任意大小对象分配
5. ✅ **扩展练习3**：分析了硬件内存范围的多种获取方法

### 8.2 实现亮点

1. **Buddy System 合并优化**
   - 实现了迭代合并逻辑
   - 通过 XOR 运算快速定位 buddy
   - 详细的日志输出便于调试和验证

2. **SLUB cache_idx 设计**
   - 在 slab_page 中增加 cache_idx 字段
   - 使 kfree() 能正确定位对象所属 cache
   - 简洁高效的页对齐定位方法

3. **完善的测试套件**
   - 三阶段测试：确定性 + 随机化 + smoke
   - 覆盖基本功能、边界情况和高压场景
   - 详细的进度日志便于观察测试过程

4. **统一的接口设计**
   - 所有分配器实现 `pmm_manager` 接口
   - 通过切换指针即可测试不同算法
   - 便于对比和性能评估

### 8.3 测试验证

所有实现均通过框架提供的 `check()` 函数验证：

```bash
# First-Fit
pmm_manager = &default_pmm_manager;
# 输出：check_alloc_page() succeeded!

# Best-Fit
pmm_manager = &best_fit_pmm_manager;
# 输出：check_alloc_page() succeeded!

# Buddy System
pmm_manager = &buddy_pmm_manager;
# 输出：[buddy_check] finished, buddy_check() succeeded!

# SLUB
slub_init();
slub_check();
# 输出：[slub] slub_check done
```

### 8.4 后续改进方向

1. **性能优化**
   - 使用更高效的数据结构（红黑树、位图）
   - 实现 per-CPU cache 减少锁竞争
   - 增加 SLUB 的 partial/full 链表管理

2. **功能完善**
   - Buddy System 增加一致性检查函数
   - SLUB 实现空 slab 回收机制
   - 支持大页（Huge Pages）

3. **并发支持**
   - 引入细粒度锁
   - 实现无锁分配算法
   - 添加多核压力测试

4. **可观测性**
   - 增加统计信息（碎片率、命中率、分配延迟）
   - 实现 /proc 风格的调试接口
   - 可视化内存布局

### 8.5 收获与体会

通过本实验，我们：

1. **深入理解了内存管理的核心算法**
   - First-Fit、Best-Fit 的权衡
   - Buddy System 的快速合并机制
   - Slab 的对象缓存思想

2. **掌握了内核数据结构的设计技巧**
   - 侵入式链表的优雅设计
   - 元数据的复用与优化
   - 对齐、填充、位运算的应用

3. **学会了内核代码的测试与验证方法**
   - 确定性测试保证基本功能
   - 随机测试发现边界问题
   - Smoke 测试验证稳定性

4. **认识到工程实现与理论的差距**
   - 教学实现 vs 生产级实现
   - 简洁性 vs 性能优化
   - 单核 vs 多核并发

---

**实验完成！**

