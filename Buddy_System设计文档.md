# Buddy System (伙伴系统) 设计文档

## 1. 概述

### 1.1 设计目标

实现一个基于伙伴系统算法的物理内存分配器，用于管理 ucore 操作系统中的物理页面。该实现需要：

- 支持高效的块分配和释放
- 实现自动合并以减少外部碎片
- 通过充分的测试用例验证正确性
- 提供清晰的设计文档

### 1.2 核心思想

Buddy System（伙伴系统）是一种经典的内存管理算法，其核心思想是：

1. **2的幂次方块大小**：所有内存块的大小都是 2^k 页（k 称为 order）
2. **伙伴关系**：两个相同大小、地址连续的块互为伙伴（buddy）
3. **按需分裂**：当需要分配较小块时，从更大的块分裂而来
4. **自动合并**：释放时，若伙伴块也空闲，则自动合并成更大的块

### 1.3 参考资源

- [伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)
- Linux Kernel Buddy System 实现
- 《Operating System Concepts》第9章：内存管理

---

## 2. 算法原理

### 2.1 伙伴块的定义

两个块互为伙伴（buddy）需要满足以下条件：

1. **大小相同**：两个块都是 2^k 页
2. **地址连续**：物理地址相邻
3. **对齐要求**：合并后的块地址必须对齐到 2^(k+1)

### 2.2 伙伴地址计算

给定一个块的起始页索引 `idx` 和 order `k`，其伙伴块的索引可通过异或运算快速计算：

```c
buddy_idx = idx XOR (1 << k)
```

**原理**：
- 对于 order k 的块，其地址的第 k 位决定了它是"左伙伴"还是"右伙伴"
- 通过 XOR (1 << k) 翻转第 k 位，即可得到伙伴块的地址

**示例**：
```
假设页大小 4KB，order = 2（块大小 16KB）

块 A: 页索引 4 (二进制: 0100)
伙伴: 4 XOR (1 << 2) = 4 XOR 4 = 0 (页索引 0)

块 B: 页索引 8 (二进制: 1000)
伙伴: 8 XOR (1 << 2) = 8 XOR 4 = 12 (页索引 12)
```

### 2.3 分配算法

```
输入：请求 n 页
输出：分配的块起始地址，或 NULL（失败）

1. 计算所需 order: k = ceil(log2(n))
2. 从 order k 开始向上查找非空链表
3. 如果所有链表都为空，返回 NULL（OOM）
4. 从找到的 order j 取出一个块
5. 当 j > k 时：
   - 将块分裂为两个 order (j-1) 的块
   - 将右半块插入 free_lists[j-1]
   - j = j - 1
6. 返回块的起始地址
```

**时间复杂度**：O(MAX_ORDER) = O(log N)，其中 N 是总页数

### 2.4 释放与合并算法

```
输入：释放 n 页，起始地址 base
输出：无

1. 计算 order: k = ceil(log2(n))
2. 当前块 = base，当前 order = k
3. 循环合并：
   a. 计算伙伴块地址: buddy = base XOR (1 << k)
   b. 在 free_lists[k] 中查找伙伴块
   c. 如果找不到伙伴，或 k >= MAX_ORDER：
      - 将当前块插入 free_lists[k]
      - 退出循环
   d. 否则：
      - 从 free_lists[k] 移除伙伴块
      - 合并：新块起始 = min(base, buddy)
      - k = k + 1
      - 继续循环
```

**时间复杂度**：O(MAX_ORDER) = O(log N)

---

## 3. 数据结构设计

### 3.1 核心数据结构

```c
#define MAX_ORDER 10  // 管理 2^0 到 2^10 页（4KB - 4MB）

// 伙伴块描述符（复用 Page 结构体空间）
typedef struct buddy_block {
    list_entry_t link;       // 链表节点
    unsigned int order;      // 块的 order
    struct Page *base;       // 块的起始页指针
} buddy_block_t;

// 每个 order 维护一个空闲链表
static list_entry_t free_lists[MAX_ORDER + 1];

// 全局空闲页统计
static free_area_t free_area;  // .nr_free 保存总空闲页数
```

### 3.2 设计说明

**为什么用链表数组？**
- 每个 order 对应一个独立链表，查找和插入 O(1)（针对特定 order）
- 分裂和合并时只需操作相邻 order 的链表
- 实现简单，易于调试

**为什么复用 Page 结构体？**
- 节省额外内存开销
- 块的首页本身包含足够空间存储描述符
- 与 ucore 框架的 `struct Page` 设计一致

**MAX_ORDER 的选择**：
- MAX_ORDER = 10 意味着最大块为 2^10 = 1024 页 = 4MB
- 对于教学系统（128MB 物理内存）足够
- 生产环境可根据需求调整

---

## 4. 关键函数实现

### 4.1 初始化 - `buddy_init()`

```c
static void buddy_init(void) {
    int i;
    for (i = 0; i <= MAX_ORDER; i++)
        list_init(&free_lists[i]);
    free_area.nr_free = 0;
}
```

**功能**：初始化所有 order 的空闲链表为空。

### 4.2 内存区域初始化 - `buddy_init_memmap()`

```c
static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    // 清除页标志
    for (struct Page *p = base; p < base + n; p++) {
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }

    // 将 n 页拆分为多个 2^k 块
    size_t remain = n;
    struct Page *cur = base;
    while (remain > 0) {
        // 找到最大的 k 使得 2^k <= remain
        unsigned int k = 0;
        while ((1UL << (k + 1)) <= remain) k++;

        if (k > MAX_ORDER) {
            // 拆分为多个 MAX_ORDER 块
            unsigned int blocks = (1UL << k) / (1UL << MAX_ORDER);
            for (unsigned int b = 0; b < blocks; b++) {
                buddy_add_free(cur, MAX_ORDER);
                cur += (1UL << MAX_ORDER);
                remain -= (1UL << MAX_ORDER);
            }
        } else {
            buddy_add_free(cur, k);
            cur += (1UL << k);
            remain -= (1UL << k);
        }
    }
}
```

**功能**：将连续的 n 页按照最优方式拆分为多个 2^k 块，插入相应的空闲链表。

**算法思想**：贪心策略，每次分配尽可能大的块。

### 4.3 分配 - `buddy_alloc_pages()`

```c
static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0 || n > free_area.nr_free) return NULL;

    unsigned int need_order = size_to_order(n);

    // 查找第一个非空链表
    unsigned int o;
    for (o = need_order; o <= MAX_ORDER; o++) {
        if (!list_empty(&free_lists[o])) break;
    }
    if (o > MAX_ORDER) return NULL;

    // 取出块并分裂
    list_entry_t *le = list_next(&free_lists[o]);
    struct Page *blk = buddy_remove_free(le);

    while (o > need_order) {
        o--;
        struct Page *buddy = blk + (1UL << o);
        buddy_add_free(buddy, o);
    }

    return blk;
}
```

**关键点**：
- 非2的幂次方请求会向上取整（如请求3页会分配4页）
- 分裂过程：从大块逐步分裂为小块，将未使用的半块放回链表

### 4.4 释放与合并 - `buddy_free_pages()`

```c
static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    unsigned int o = size_to_order(n);
    struct Page *blk = base;

    // 迭代合并
    while (o <= MAX_ORDER) {
        struct Page *buddy = buddy_find_and_remove(blk, o);
        if (!buddy) {
            // 伙伴不空闲，无法合并
            buddy_add_free(blk, o);
            break;
        }

        // 合并：保留低地址
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

**关键点**：
- 使用 `buddy_find_and_remove()` 查找并移除伙伴块
- 迭代合并：合并后继续尝试与更高 order 的伙伴合并
- 保留低地址保证对齐要求

### 4.5 伙伴查找 - `buddy_find_and_remove()`

```c
static struct Page *buddy_find_and_remove(struct Page *base, unsigned int order) {
    // 计算伙伴地址
    uintptr_t idx = base - pages;
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

**优化空间**：
- 当前为线性查找，O(m)，m 为该 order 的块数
- 可优化为位图或哈希表，达到 O(1)

---

## 5. 测试设计

### 5.1 测试目标

- **功能正确性**：验证分配、释放、合并的基本功能
- **边界情况**：测试单页、大块、非2幂次方大小
- **合并验证**：确认伙伴块能正确合并
- **稳定性**：随机压力测试，验证长时间运行无错误

### 5.2 测试用例

#### Test 1: 单页分配与释放
```c
struct Page *a = alloc_page();
struct Page *b = alloc_page();
struct Page *c = alloc_page();
free_page(b);
free_page(a);
free_page(c);
```
**验证**：分配后空闲页减少，释放后恢复。

#### Test 2: 多页分配（2的幂次方）
```c
struct Page *a = alloc_pages(2);  // 2页
struct Page *b = alloc_pages(4);  // 4页
free_pages(a, 2);
free_pages(b, 4);
```
**验证**：2^k 大小的分配和释放正确。

#### Test 3: 非2幂次方分配
```c
struct Page *a = alloc_pages(3);  // 会分配4页
free_pages(a, 3);
```
**验证**：向上取整到2的幂次方。

#### Test 4: 大块分配
```c
struct Page *d = alloc_pages(1 << (MAX_ORDER - 1));  // 512页
free_pages(d, 1 << (MAX_ORDER - 1));
```
**验证**：接近最大 order 的分配和释放。

#### Test 5: 合并验证
```c
// 分配多个2页块
struct Page *a = alloc_pages(2);
struct Page *b = alloc_pages(2);
struct Page *c = alloc_pages(2);
struct Page *d = alloc_pages(2);

// 按顺序释放
free_pages(a, 2);
free_pages(b, 2);
free_pages(c, 2);
free_pages(d, 2);

// 尝试分配大块（验证合并成功）
struct Page *large = alloc_pages(8);
```
**验证**：释放的小块能合并成大块。

#### Test 6: 随机压力测试
```c
for (int i = 0; i < 256; i++) {
    size_t size = random(1, 16);
    allocs[i] = alloc_pages(size);
}
for (int i = 255; i >= 0; i--) {
    free_pages(allocs[i], sizes[i]);
}
```
**验证**：随机分配和释放无崩溃，内存泄漏检查。

#### Test 7: OOM测试
```c
while (true) {
    struct Page *p = alloc_page();
    if (!p) break;  // 内存耗尽
}
```
**验证**：OOM 时返回 NULL 而不是崩溃。

### 5.3 测试结果验证

每个测试用例通过以下方式验证：

1. **断言检查**：`assert()` 验证返回值和状态
2. **空闲页统计**：检查 `nr_free_pages()` 是否正确
3. **日志输出**：打印关键步骤，便于调试
4. **无崩溃**：所有测试完成无 panic

---

## 6. 性能分析

### 6.1 时间复杂度

| 操作 | 时间复杂度 | 说明 |
|------|-----------|------|
| 分配 | O(log N) | 最多分裂 MAX_ORDER 次 |
| 释放 | O(log N) | 最多合并 MAX_ORDER 次 |
| 查找伙伴 | O(m) | m 为该 order 的块数 |

### 6.2 空间复杂度

- **元数据开销**：复用 `struct Page`，无额外内存
- **链表数组**：`sizeof(list_entry_t) * (MAX_ORDER + 1)` ≈ 176 字节

### 6.3 优缺点分析

**优点**：
1. ✅ 减少外部碎片：自动合并相邻空闲块
2. ✅ 分配快速：O(log N) 时间复杂度
3. ✅ 实现简单：算法清晰，易于理解和维护

**缺点**：
1. ❌ 内部碎片：非2幂次方请求会浪费空间（如请求3页实际分配4页）
2. ❌ 伙伴查找慢：当前O(m)线性查找，可优化
3. ❌ 不适合小对象：页级分配，对于小于4KB的对象效率低

---

## 7. 改进方向

### 7.1 优化伙伴查找

**当前问题**：线性查找 O(m)

**优化方案**：
1. **位图索引**：为每个 order 维护位图，标记哪些块空闲
2. **哈希表**：用块地址作为 key，O(1) 查找
3. **树结构**：完全二叉树表示，隐式存储伙伴关系

### 7.2 支持更大的块

当前 MAX_ORDER = 10（4MB），对于大内存系统不够。

**改进**：动态调整 MAX_ORDER，或支持多级 buddy system。

### 7.3 减少内部碎片

**方案1**：混合分配策略
- 对于接近2幂次方的请求（如3页），尝试从更小块组合
- 需要额外的簿记开销

**方案2**：分级分配器
- Buddy System 管理页级（4KB+）
- SLUB/Slab 管理小对象（<4KB）

### 7.4 并发优化

**当前问题**：单核设计，无锁保护

**改进方案**：
1. **Per-CPU 缓存**：每个 CPU 维护独立的小块缓存
2. **细粒度锁**：为每个 order 的链表单独加锁
3. **无锁算法**：使用 CAS 操作的 lock-free buddy system

---

## 8. 与参考实现的对比

### 8.1 与 Linux Buddy System 的差异

| 特性 | Linux Kernel | 本实现 |
|------|-------------|--------|
| 数据结构 | free_area[] + free_list | free_lists[] + 链表 |
| 伙伴查找 | 位图 + 页框编号 | 线性查找链表 |
| 并发控制 | zone->lock 自旋锁 | 无（单核） |
| MAX_ORDER | 11（通常） | 10 |
| 优化 | 高度优化（fast path） | 教学简化版 |

### 8.2 与参考资料的关系

本实现参考了[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)的核心思想，但在以下方面有所不同：

1. **数据结构**：使用链表而非二叉树，更符合 ucore 框架
2. **合并策略**：显式迭代合并，而非递归
3. **测试完备性**：增加了6+类测试用例，覆盖更全面

---

## 9. 总结

### 9.1 实现完成度

✅ **已完成**：
- 基本的分配、释放功能
- 完整的伙伴合并机制
- 6种以上测试用例
- 详细的设计文档

⚠️ **简化处理**：
- 伙伴查找为线性，未优化为O(1)
- 无并发控制，仅适用单核
- MAX_ORDER 固定，不支持动态调整

### 9.2 适用场景

本实现适用于：
- ✅ 教学和学习 Buddy System 算法
- ✅ 单核或内核初始化阶段的内存管理
- ✅ 页级（4KB+）的内存分配

不适用于：
- ❌ 生产环境的高并发场景
- ❌ 小对象（<4KB）的频繁分配
- ❌ 对性能要求极高的实时系统

### 9.3 学习价值

通过本实现，可以深入理解：

1. **Buddy System 核心思想**：2的幂次方、伙伴关系、自动合并
2. **位运算技巧**：XOR 快速计算伙伴地址
3. **数据结构设计**：链表数组的权衡
4. **内存碎片**：内部碎片 vs 外部碎片
5. **测试驱动开发**：如何设计完备的测试用例

---

## 10. 参考文献

1. [伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html) - CoolShell
2. *Understanding the Linux Kernel, 3rd Edition* - Daniel P. Bovet & Marco Cesati
3. *Operating System Concepts, 10th Edition* - Abraham Silberschatz et al.
4. [Linux Kernel Source: mm/page_alloc.c](https://github.com/torvalds/linux/blob/master/mm/page_alloc.c)
5. uCore Operating System Lab Manual - Tsinghua University

---

**文档版本**：v1.0
**最后更新**：2025年10月
**作者**：[小组成员]
