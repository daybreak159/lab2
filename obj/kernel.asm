
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	4bc50513          	addi	a0,a0,1212 # ffffffffc0201508 <etext>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	4c650513          	addi	a0,a0,1222 # ffffffffc0201528 <etext+0x20>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	49a58593          	addi	a1,a1,1178 # ffffffffc0201508 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	4d250513          	addi	a0,a0,1234 # ffffffffc0201548 <etext+0x40>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_lists>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	4de50513          	addi	a0,a0,1246 # ffffffffc0201568 <etext+0x60>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	09a58593          	addi	a1,a1,154 # ffffffffc0206130 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	4ea50513          	addi	a0,a0,1258 # ffffffffc0201588 <etext+0x80>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00006797          	auipc	a5,0x6
ffffffffc02000b6:	47d78793          	addi	a5,a5,1149 # ffffffffc020652f <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	4de50513          	addi	a0,a0,1246 # ffffffffc02015a8 <etext+0xa0>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00006517          	auipc	a0,0x6
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0206018 <free_lists>
ffffffffc02000de:	00006617          	auipc	a2,0x6
ffffffffc02000e2:	05260613          	addi	a2,a2,82 # ffffffffc0206130 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	408010ef          	jal	ffffffffc02014f6 <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	e3650513          	addi	a0,a0,-458 # ffffffffc0201f30 <etext+0xa28>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	5a3000ef          	jal	ffffffffc0200eac <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200116:	10a000ef          	jal	ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc020011a:	65a2                	ld	a1,8(sp)
}
ffffffffc020011c:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc020011e:	419c                	lw	a5,0(a1)
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c19c                	sw	a5,0(a1)
}
ffffffffc0200124:	6105                	addi	sp,sp,32
ffffffffc0200126:	8082                	ret

ffffffffc0200128 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200128:	1101                	addi	sp,sp,-32
ffffffffc020012a:	862a                	mv	a2,a0
ffffffffc020012c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020012e:	00000517          	auipc	a0,0x0
ffffffffc0200132:	fe250513          	addi	a0,a0,-30 # ffffffffc0200110 <cputch>
ffffffffc0200136:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200138:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	7ab000ef          	jal	ffffffffc02010e6 <vprintfmt>
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	4532                	lw	a0,12(sp)
ffffffffc0200144:	6105                	addi	sp,sp,32
ffffffffc0200146:	8082                	ret

ffffffffc0200148 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200148:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014a:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc020014e:	f42e                	sd	a1,40(sp)
ffffffffc0200150:	f832                	sd	a2,48(sp)
ffffffffc0200152:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200154:	862a                	mv	a2,a0
ffffffffc0200156:	004c                	addi	a1,sp,4
ffffffffc0200158:	00000517          	auipc	a0,0x0
ffffffffc020015c:	fb850513          	addi	a0,a0,-72 # ffffffffc0200110 <cputch>
ffffffffc0200160:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e0ba                	sd	a4,64(sp)
ffffffffc0200166:	e4be                	sd	a5,72(sp)
ffffffffc0200168:	e8c2                	sd	a6,80(sp)
ffffffffc020016a:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020016c:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	777000ef          	jal	ffffffffc02010e6 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200174:	60e2                	ld	ra,24(sp)
ffffffffc0200176:	4512                	lw	a0,4(sp)
ffffffffc0200178:	6125                	addi	sp,sp,96
ffffffffc020017a:	8082                	ret

ffffffffc020017c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017c:	1101                	addi	sp,sp,-32
ffffffffc020017e:	e822                	sd	s0,16(sp)
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200184:	00054503          	lbu	a0,0(a0)
ffffffffc0200188:	c51d                	beqz	a0,ffffffffc02001b6 <cputs+0x3a>
ffffffffc020018a:	e426                	sd	s1,8(sp)
ffffffffc020018c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020018e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200190:	090000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00044503          	lbu	a0,0(s0)
ffffffffc0200198:	0405                	addi	s0,s0,1
ffffffffc020019a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020019c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020019e:	f96d                	bnez	a0,ffffffffc0200190 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a0:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a2:	0027841b          	addiw	s0,a5,2
ffffffffc02001a6:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001a8:	078000ef          	jal	ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	8522                	mv	a0,s0
ffffffffc02001b0:	6442                	ld	s0,16(sp)
ffffffffc02001b2:	6105                	addi	sp,sp,32
ffffffffc02001b4:	8082                	ret
    cons_putc(c);
ffffffffc02001b6:	4529                	li	a0,10
ffffffffc02001b8:	068000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001bc:	4405                	li	s0,1
}
ffffffffc02001be:	60e2                	ld	ra,24(sp)
ffffffffc02001c0:	8522                	mv	a0,s0
ffffffffc02001c2:	6442                	ld	s0,16(sp)
ffffffffc02001c4:	6105                	addi	sp,sp,32
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00006317          	auipc	t1,0x6
ffffffffc02001cc:	f1832303          	lw	t1,-232(t1) # ffffffffc02060e0 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d0:	715d                	addi	sp,sp,-80
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	00030363          	beqz	t1,ffffffffc02001e4 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e4:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001e6:	103c                	addi	a5,sp,40
ffffffffc02001e8:	e822                	sd	s0,16(sp)
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	862e                	mv	a2,a1
ffffffffc02001ee:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f0:	00001517          	auipc	a0,0x1
ffffffffc02001f4:	3e850513          	addi	a0,a0,1000 # ffffffffc02015d8 <etext+0xd0>
    is_panic = 1;
ffffffffc02001f8:	00006697          	auipc	a3,0x6
ffffffffc02001fc:	eee6a423          	sw	a4,-280(a3) # ffffffffc02060e0 <is_panic>
    va_start(ap, fmt);
ffffffffc0200200:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	f47ff0ef          	jal	ffffffffc0200148 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200206:	65a2                	ld	a1,8(sp)
ffffffffc0200208:	8522                	mv	a0,s0
ffffffffc020020a:	f1fff0ef          	jal	ffffffffc0200128 <vcprintf>
    cprintf("\n");
ffffffffc020020e:	00001517          	auipc	a0,0x1
ffffffffc0200212:	3ea50513          	addi	a0,a0,1002 # ffffffffc02015f8 <etext+0xf0>
ffffffffc0200216:	f33ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc020021a:	6442                	ld	s0,16(sp)
ffffffffc020021c:	b7d9                	j	ffffffffc02001e2 <__panic+0x1a>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	2280106f          	j	ffffffffc020144c <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	3d650513          	addi	a0,a0,982 # ffffffffc0201600 <etext+0xf8>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	3ce50513          	addi	a0,a0,974 # ffffffffc0201610 <etext+0x108>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00006417          	auipc	s0,0x6
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	3c850513          	addi	a0,a0,968 # ffffffffc0201620 <etext+0x118>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	3d250513          	addi	a0,a0,978 # ffffffffc0201638 <etext+0x130>
    if (boot_dtb == 0) {
ffffffffc020026e:	10070163          	beqz	a4,ffffffffc0200370 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200272:	57f5                	li	a5,-3
ffffffffc0200274:	07fa                	slli	a5,a5,0x1e
ffffffffc0200276:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200278:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed9dbd>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200286:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	8e49                	or	a2,a2,a0
ffffffffc020029a:	0ff7f793          	zext.b	a5,a5
ffffffffc020029e:	8dd1                	or	a1,a1,a2
ffffffffc02002a0:	07a2                	slli	a5,a5,0x8
ffffffffc02002a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002a8:	0cd59863          	bne	a1,a3,ffffffffc0200378 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ac:	4710                	lw	a2,8(a4)
ffffffffc02002ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002da:	01c56533          	or	a0,a0,t3
ffffffffc02002de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f2:	8c49                	or	s0,s0,a0
ffffffffc02002f4:	0622                	slli	a2,a2,0x8
ffffffffc02002f6:	8fcd                	or	a5,a5,a1
ffffffffc02002f8:	06a2                	slli	a3,a3,0x8
ffffffffc02002fa:	8c51                	or	s0,s0,a2
ffffffffc02002fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02002fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200300:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	9381                	srli	a5,a5,0x20
ffffffffc0200306:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200308:	4301                	li	t1,0
        switch (token) {
ffffffffc020030a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200312:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200314:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020031e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200322:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	8ed1                	or	a3,a3,a2
ffffffffc0200330:	0ff77713          	zext.b	a4,a4
ffffffffc0200334:	8fd5                	or	a5,a5,a3
ffffffffc0200336:	0722                	slli	a4,a4,0x8
ffffffffc0200338:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033a:	05178763          	beq	a5,a7,ffffffffc0200388 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200340:	00f8e963          	bltu	a7,a5,ffffffffc0200352 <dtb_init+0x12a>
ffffffffc0200344:	07c78d63          	beq	a5,t3,ffffffffc02003be <dtb_init+0x196>
ffffffffc0200348:	4709                	li	a4,2
ffffffffc020034a:	00e79763          	bne	a5,a4,ffffffffc0200358 <dtb_init+0x130>
ffffffffc020034e:	4301                	li	t1,0
ffffffffc0200350:	b7d1                	j	ffffffffc0200314 <dtb_init+0xec>
ffffffffc0200352:	4711                	li	a4,4
ffffffffc0200354:	fce780e3          	beq	a5,a4,ffffffffc0200314 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200358:	00001517          	auipc	a0,0x1
ffffffffc020035c:	3a850513          	addi	a0,a0,936 # ffffffffc0201700 <etext+0x1f8>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	3d050513          	addi	a0,a0,976 # ffffffffc0201738 <etext+0x230>
}
ffffffffc0200370:	7402                	ld	s0,32(sp)
ffffffffc0200372:	70a2                	ld	ra,40(sp)
ffffffffc0200374:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200376:	bbc9                	j	ffffffffc0200148 <cprintf>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020037c:	00001517          	auipc	a0,0x1
ffffffffc0200380:	2dc50513          	addi	a0,a0,732 # ffffffffc0201658 <etext+0x150>
}
ffffffffc0200384:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200386:	b3c9                	j	ffffffffc0200148 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200388:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020038e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200392:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200396:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	8ed1                	or	a3,a3,a2
ffffffffc02003a4:	0ff77713          	zext.b	a4,a4
ffffffffc02003a8:	8fd5                	or	a5,a5,a3
ffffffffc02003aa:	0722                	slli	a4,a4,0x8
ffffffffc02003ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003ae:	04031463          	bnez	t1,ffffffffc02003f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b2:	1782                	slli	a5,a5,0x20
ffffffffc02003b4:	9381                	srli	a5,a5,0x20
ffffffffc02003b6:	043d                	addi	s0,s0,15
ffffffffc02003b8:	943e                	add	s0,s0,a5
ffffffffc02003ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003bc:	bfa1                	j	ffffffffc0200314 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003be:	8522                	mv	a0,s0
ffffffffc02003c0:	e01a                	sd	t1,0(sp)
ffffffffc02003c2:	0a4010ef          	jal	ffffffffc0201466 <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	2b458593          	addi	a1,a1,692 # ffffffffc0201680 <etext+0x178>
ffffffffc02003d4:	0fa010ef          	jal	ffffffffc02014ce <strncmp>
ffffffffc02003d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003da:	0411                	addi	s0,s0,4
ffffffffc02003dc:	0004879b          	sext.w	a5,s1
ffffffffc02003e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003ec:	00ff0837          	lui	a6,0xff0
ffffffffc02003f0:	488d                	li	a7,3
ffffffffc02003f2:	4e05                	li	t3,1
ffffffffc02003f4:	b705                	j	ffffffffc0200314 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003f8:	00001597          	auipc	a1,0x1
ffffffffc02003fc:	29058593          	addi	a1,a1,656 # ffffffffc0201688 <etext+0x180>
ffffffffc0200400:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200402:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200406:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020040e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200412:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	8ed1                	or	a3,a3,a2
ffffffffc020041c:	0ff77713          	zext.b	a4,a4
ffffffffc0200420:	0722                	slli	a4,a4,0x8
ffffffffc0200422:	8d55                	or	a0,a0,a3
ffffffffc0200424:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200426:	1502                	slli	a0,a0,0x20
ffffffffc0200428:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042a:	954a                	add	a0,a0,s2
ffffffffc020042c:	e01a                	sd	t1,0(sp)
ffffffffc020042e:	06c010ef          	jal	ffffffffc020149a <strcmp>
ffffffffc0200432:	67a2                	ld	a5,8(sp)
ffffffffc0200434:	473d                	li	a4,15
ffffffffc0200436:	6302                	ld	t1,0(sp)
ffffffffc0200438:	00ff0837          	lui	a6,0xff0
ffffffffc020043c:	488d                	li	a7,3
ffffffffc020043e:	4e05                	li	t3,1
ffffffffc0200440:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b2 <dtb_init+0x18a>
ffffffffc0200444:	f53d                	bnez	a0,ffffffffc02003b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200446:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020044e:	00001517          	auipc	a0,0x1
ffffffffc0200452:	24250513          	addi	a0,a0,578 # ffffffffc0201690 <etext+0x188>
           fdt32_to_cpu(x >> 32);
ffffffffc0200456:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020045e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200462:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200466:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020046e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200472:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200476:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	01037333          	and	t1,t1,a6
ffffffffc0200482:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048a:	0ff7f793          	zext.b	a5,a5
ffffffffc020048e:	01de6e33          	or	t3,t3,t4
ffffffffc0200492:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200496:	01067633          	and	a2,a2,a6
ffffffffc020049a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020049e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a2:	07a2                	slli	a5,a5,0x8
ffffffffc02004a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
ffffffffc02004b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	08a2                	slli	a7,a7,0x8
ffffffffc02004d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e4:	01de6833          	or	a6,t3,t4
ffffffffc02004e8:	0ff77713          	zext.b	a4,a4
ffffffffc02004ec:	01166633          	or	a2,a2,a7
ffffffffc02004f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f4:	06a2                	slli	a3,a3,0x8
ffffffffc02004f6:	01046433          	or	s0,s0,a6
ffffffffc02004fa:	0722                	slli	a4,a4,0x8
ffffffffc02004fc:	8fd5                	or	a5,a5,a3
ffffffffc02004fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200500:	1582                	slli	a1,a1,0x20
ffffffffc0200502:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200504:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200506:	9201                	srli	a2,a2,0x20
ffffffffc0200508:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050a:	1402                	slli	s0,s0,0x20
ffffffffc020050c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200510:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200512:	c37ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200516:	85a6                	mv	a1,s1
ffffffffc0200518:	00001517          	auipc	a0,0x1
ffffffffc020051c:	19850513          	addi	a0,a0,408 # ffffffffc02016b0 <etext+0x1a8>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	19e50513          	addi	a0,a0,414 # ffffffffc02016c8 <etext+0x1c0>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	1ac50513          	addi	a0,a0,428 # ffffffffc02016e8 <etext+0x1e0>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00006797          	auipc	a5,0x6
ffffffffc020054c:	ba97b423          	sd	s1,-1112(a5) # ffffffffc02060f0 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00006797          	auipc	a5,0x6
ffffffffc0200554:	b887bc23          	sd	s0,-1128(a5) # ffffffffc02060e8 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00006517          	auipc	a0,0x6
ffffffffc020055e:	b9653503          	ld	a0,-1130(a0) # ffffffffc02060f0 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00006517          	auipc	a0,0x6
ffffffffc0200568:	b8453503          	ld	a0,-1148(a0) # ffffffffc02060e8 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <buddy_nr_free_pages>:
            break;
        }
    }
}

static size_t buddy_nr_free_pages(void) { return free_area.nr_free; }
ffffffffc020056e:	00006517          	auipc	a0,0x6
ffffffffc0200572:	b6a56503          	lwu	a0,-1174(a0) # ffffffffc02060d8 <free_area+0x10>
ffffffffc0200576:	8082                	ret

ffffffffc0200578 <buddy_init>:
static void buddy_init(void) {
ffffffffc0200578:	1141                	addi	sp,sp,-16
    cprintf("[buddy] buddy_init() start\n");
ffffffffc020057a:	00001517          	auipc	a0,0x1
ffffffffc020057e:	1d650513          	addi	a0,a0,470 # ffffffffc0201750 <etext+0x248>
static void buddy_init(void) {
ffffffffc0200582:	e406                	sd	ra,8(sp)
    cprintf("[buddy] buddy_init() start\n");
ffffffffc0200584:	bc5ff0ef          	jal	ffffffffc0200148 <cprintf>
    for (i = 0; i <= MAX_ORDER; i++)
ffffffffc0200588:	00006797          	auipc	a5,0x6
ffffffffc020058c:	a9078793          	addi	a5,a5,-1392 # ffffffffc0206018 <free_lists>
ffffffffc0200590:	00006717          	auipc	a4,0x6
ffffffffc0200594:	b3870713          	addi	a4,a4,-1224 # ffffffffc02060c8 <free_area>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200598:	e79c                	sd	a5,8(a5)
ffffffffc020059a:	e39c                	sd	a5,0(a5)
ffffffffc020059c:	07c1                	addi	a5,a5,16
ffffffffc020059e:	fee79de3          	bne	a5,a4,ffffffffc0200598 <buddy_init+0x20>
}
ffffffffc02005a2:	60a2                	ld	ra,8(sp)
    free_area.nr_free = 0;
ffffffffc02005a4:	00006797          	auipc	a5,0x6
ffffffffc02005a8:	b207aa23          	sw	zero,-1228(a5) # ffffffffc02060d8 <free_area+0x10>
    max_order_inited = 0;
ffffffffc02005ac:	00006797          	auipc	a5,0x6
ffffffffc02005b0:	b407a623          	sw	zero,-1204(a5) # ffffffffc02060f8 <max_order_inited>
    cprintf("[buddy] buddy_init() done\n");
ffffffffc02005b4:	00001517          	auipc	a0,0x1
ffffffffc02005b8:	1bc50513          	addi	a0,a0,444 # ffffffffc0201770 <etext+0x268>
}
ffffffffc02005bc:	0141                	addi	sp,sp,16
    cprintf("[buddy] buddy_init() done\n");
ffffffffc02005be:	b669                	j	ffffffffc0200148 <cprintf>

ffffffffc02005c0 <buddy_check>:
        if (allocs[i]) free_pages(allocs[i], sizes[i]);
        if (i == 0) break; // prevent unsigned wrap
    }
}

static void buddy_check(void) {
ffffffffc02005c0:	7159                	addi	sp,sp,-112
ffffffffc02005c2:	f486                	sd	ra,104(sp)
ffffffffc02005c4:	f0a2                	sd	s0,96(sp)
ffffffffc02005c6:	eca6                	sd	s1,88(sp)
ffffffffc02005c8:	1880                	addi	s0,sp,112
ffffffffc02005ca:	e4ce                	sd	s3,72(sp)
ffffffffc02005cc:	e0d2                	sd	s4,64(sp)
ffffffffc02005ce:	e8ca                	sd	s2,80(sp)
ffffffffc02005d0:	fc56                	sd	s5,56(sp)
ffffffffc02005d2:	f85a                	sd	s6,48(sp)
ffffffffc02005d4:	f45e                	sd	s7,40(sp)
ffffffffc02005d6:	f062                	sd	s8,32(sp)
ffffffffc02005d8:	ec66                	sd	s9,24(sp)
ffffffffc02005da:	e86a                	sd	s10,16(sp)
ffffffffc02005dc:	e46e                	sd	s11,8(sp)
    int score = 0, sumscore = 8;  // Total 8 test points

    cprintf("[buddy_check] start deterministic tests\n");
ffffffffc02005de:	00001517          	auipc	a0,0x1
ffffffffc02005e2:	1b250513          	addi	a0,a0,434 # ffffffffc0201790 <etext+0x288>
ffffffffc02005e6:	b63ff0ef          	jal	ffffffffc0200148 <cprintf>
    size_t initial_free = nr_free_pages();
ffffffffc02005ea:	0b7000ef          	jal	ffffffffc0200ea0 <nr_free_pages>
ffffffffc02005ee:	84aa                	mv	s1,a0
    cprintf("[buddy_check]   Test 1: Single page allocation\n");
ffffffffc02005f0:	00001517          	auipc	a0,0x1
ffffffffc02005f4:	1d050513          	addi	a0,a0,464 # ffffffffc02017c0 <etext+0x2b8>
ffffffffc02005f8:	b51ff0ef          	jal	ffffffffc0200148 <cprintf>
    a = alloc_page();
ffffffffc02005fc:	4505                	li	a0,1
ffffffffc02005fe:	08b000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc0200602:	89aa                	mv	s3,a0
    b = alloc_page();
ffffffffc0200604:	4505                	li	a0,1
ffffffffc0200606:	083000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc020060a:	8a2a                	mv	s4,a0
    c = alloc_page();
ffffffffc020060c:	4505                	li	a0,1
ffffffffc020060e:	07b000ef          	jal	ffffffffc0200e88 <alloc_pages>
    assert(a && b && c);
ffffffffc0200612:	0019b793          	seqz	a5,s3
ffffffffc0200616:	001a3713          	seqz	a4,s4
ffffffffc020061a:	8fd9                	or	a5,a5,a4
ffffffffc020061c:	42079d63          	bnez	a5,ffffffffc0200a56 <buddy_check+0x496>
ffffffffc0200620:	892a                	mv	s2,a0
ffffffffc0200622:	42050a63          	beqz	a0,ffffffffc0200a56 <buddy_check+0x496>
    assert(nr_free_pages() == initial_free - 3);
ffffffffc0200626:	07b000ef          	jal	ffffffffc0200ea0 <nr_free_pages>
ffffffffc020062a:	ffd48793          	addi	a5,s1,-3
ffffffffc020062e:	32f51463          	bne	a0,a5,ffffffffc0200956 <buddy_check+0x396>
    cprintf("[buddy_check]   Test 2: Single page free and coalescing\n");
ffffffffc0200632:	00001517          	auipc	a0,0x1
ffffffffc0200636:	22650513          	addi	a0,a0,550 # ffffffffc0201858 <etext+0x350>
ffffffffc020063a:	b0fff0ef          	jal	ffffffffc0200148 <cprintf>
    free_page(b);
ffffffffc020063e:	8552                	mv	a0,s4
ffffffffc0200640:	4585                	li	a1,1
ffffffffc0200642:	053000ef          	jal	ffffffffc0200e94 <free_pages>
    free_page(a);
ffffffffc0200646:	854e                	mv	a0,s3
ffffffffc0200648:	4585                	li	a1,1
ffffffffc020064a:	04b000ef          	jal	ffffffffc0200e94 <free_pages>
    free_page(c);
ffffffffc020064e:	854a                	mv	a0,s2
ffffffffc0200650:	4585                	li	a1,1
ffffffffc0200652:	043000ef          	jal	ffffffffc0200e94 <free_pages>
    assert(nr_free_pages() == initial_free);
ffffffffc0200656:	04b000ef          	jal	ffffffffc0200ea0 <nr_free_pages>
ffffffffc020065a:	40a49e63          	bne	s1,a0,ffffffffc0200a76 <buddy_check+0x4b6>
    cprintf("[buddy_check]   Test 3: Multi-page allocation (power of 2)\n");
ffffffffc020065e:	00001517          	auipc	a0,0x1
ffffffffc0200662:	25a50513          	addi	a0,a0,602 # ffffffffc02018b8 <etext+0x3b0>
ffffffffc0200666:	ae3ff0ef          	jal	ffffffffc0200148 <cprintf>
    a = alloc_pages(2);
ffffffffc020066a:	4509                	li	a0,2
ffffffffc020066c:	01d000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc0200670:	89aa                	mv	s3,a0
    b = alloc_pages(4);
ffffffffc0200672:	4511                	li	a0,4
ffffffffc0200674:	015000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc0200678:	892a                	mv	s2,a0
    assert(a && b);
ffffffffc020067a:	34098e63          	beqz	s3,ffffffffc02009d6 <buddy_check+0x416>
ffffffffc020067e:	34050c63          	beqz	a0,ffffffffc02009d6 <buddy_check+0x416>
    assert(nr_free_pages() == initial_free - 6);
ffffffffc0200682:	01f000ef          	jal	ffffffffc0200ea0 <nr_free_pages>
ffffffffc0200686:	ffa48793          	addi	a5,s1,-6
ffffffffc020068a:	32f51663          	bne	a0,a5,ffffffffc02009b6 <buddy_check+0x3f6>
    free_pages(a, 2);
ffffffffc020068e:	854e                	mv	a0,s3
ffffffffc0200690:	4589                	li	a1,2
ffffffffc0200692:	003000ef          	jal	ffffffffc0200e94 <free_pages>
    free_pages(b, 4);
ffffffffc0200696:	854a                	mv	a0,s2
ffffffffc0200698:	4591                	li	a1,4
ffffffffc020069a:	7fa000ef          	jal	ffffffffc0200e94 <free_pages>
    assert(nr_free_pages() == initial_free);
ffffffffc020069e:	003000ef          	jal	ffffffffc0200ea0 <nr_free_pages>
ffffffffc02006a2:	2ea49a63          	bne	s1,a0,ffffffffc0200996 <buddy_check+0x3d6>
    cprintf("[buddy_check]   Test 4: Non-power-of-2 allocation (rounded up)\n");
ffffffffc02006a6:	00001517          	auipc	a0,0x1
ffffffffc02006aa:	28250513          	addi	a0,a0,642 # ffffffffc0201928 <etext+0x420>
ffffffffc02006ae:	a9bff0ef          	jal	ffffffffc0200148 <cprintf>
    a = alloc_pages(3); // Should allocate 4 pages (2^2)
ffffffffc02006b2:	450d                	li	a0,3
ffffffffc02006b4:	7d4000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc02006b8:	892a                	mv	s2,a0
    assert(a);
ffffffffc02006ba:	2a050e63          	beqz	a0,ffffffffc0200976 <buddy_check+0x3b6>
    assert(nr_free_pages() <= initial_free - 4);
ffffffffc02006be:	7e2000ef          	jal	ffffffffc0200ea0 <nr_free_pages>
ffffffffc02006c2:	ffc48793          	addi	a5,s1,-4
ffffffffc02006c6:	34a7e863          	bltu	a5,a0,ffffffffc0200a16 <buddy_check+0x456>
    free_pages(a, 3);
ffffffffc02006ca:	854a                	mv	a0,s2
ffffffffc02006cc:	458d                	li	a1,3
ffffffffc02006ce:	7c6000ef          	jal	ffffffffc0200e94 <free_pages>
    cprintf("[buddy_check]   Test 5: Large block allocation\n");
ffffffffc02006d2:	00001517          	auipc	a0,0x1
ffffffffc02006d6:	2c650513          	addi	a0,a0,710 # ffffffffc0201998 <etext+0x490>
ffffffffc02006da:	a6fff0ef          	jal	ffffffffc0200148 <cprintf>
    d = alloc_pages(1 << (MAX_ORDER - 1));
ffffffffc02006de:	20000513          	li	a0,512
ffffffffc02006e2:	7a6000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc02006e6:	892a                	mv	s2,a0
    if (d) {
ffffffffc02006e8:	cd01                	beqz	a0,ffffffffc0200700 <buddy_check+0x140>
        assert(nr_free_pages() <= initial_free - (1 << (MAX_ORDER - 1)));
ffffffffc02006ea:	7b6000ef          	jal	ffffffffc0200ea0 <nr_free_pages>
ffffffffc02006ee:	e0048493          	addi	s1,s1,-512
ffffffffc02006f2:	30a4e263          	bltu	s1,a0,ffffffffc02009f6 <buddy_check+0x436>
        free_pages(d, 1 << (MAX_ORDER - 1));
ffffffffc02006f6:	854a                	mv	a0,s2
ffffffffc02006f8:	20000593          	li	a1,512
ffffffffc02006fc:	798000ef          	jal	ffffffffc0200e94 <free_pages>
    cprintf("[buddy_check]   Test 6: Verify coalescing after mixed operations\n");
ffffffffc0200700:	00001517          	auipc	a0,0x1
ffffffffc0200704:	30850513          	addi	a0,a0,776 # ffffffffc0201a08 <etext+0x500>
ffffffffc0200708:	a41ff0ef          	jal	ffffffffc0200148 <cprintf>
    a = alloc_pages(2);
ffffffffc020070c:	4509                	li	a0,2
ffffffffc020070e:	77a000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc0200712:	84aa                	mv	s1,a0
    b = alloc_pages(2);
ffffffffc0200714:	4509                	li	a0,2
ffffffffc0200716:	772000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc020071a:	89aa                	mv	s3,a0
    c = alloc_pages(2);
ffffffffc020071c:	4509                	li	a0,2
ffffffffc020071e:	76a000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc0200722:	892a                	mv	s2,a0
    d = alloc_pages(2);
ffffffffc0200724:	4509                	li	a0,2
ffffffffc0200726:	762000ef          	jal	ffffffffc0200e88 <alloc_pages>
    assert(a && b && c && d);
ffffffffc020072a:	30048663          	beqz	s1,ffffffffc0200a36 <buddy_check+0x476>
ffffffffc020072e:	30098463          	beqz	s3,ffffffffc0200a36 <buddy_check+0x476>
ffffffffc0200732:	30090263          	beqz	s2,ffffffffc0200a36 <buddy_check+0x476>
ffffffffc0200736:	30050063          	beqz	a0,ffffffffc0200a36 <buddy_check+0x476>
    free_pages(d, 2);
ffffffffc020073a:	4589                	li	a1,2
ffffffffc020073c:	758000ef          	jal	ffffffffc0200e94 <free_pages>
    free_pages(b, 2);
ffffffffc0200740:	854e                	mv	a0,s3
ffffffffc0200742:	4589                	li	a1,2
ffffffffc0200744:	750000ef          	jal	ffffffffc0200e94 <free_pages>
    free_pages(c, 2);
ffffffffc0200748:	854a                	mv	a0,s2
ffffffffc020074a:	4589                	li	a1,2
ffffffffc020074c:	748000ef          	jal	ffffffffc0200e94 <free_pages>
    free_pages(a, 2);
ffffffffc0200750:	8526                	mv	a0,s1
ffffffffc0200752:	4589                	li	a1,2
ffffffffc0200754:	740000ef          	jal	ffffffffc0200e94 <free_pages>
    struct Page *large = alloc_pages(8);
ffffffffc0200758:	4521                	li	a0,8
ffffffffc020075a:	72e000ef          	jal	ffffffffc0200e88 <alloc_pages>
    if (large) {
ffffffffc020075e:	c501                	beqz	a0,ffffffffc0200766 <buddy_check+0x1a6>
        free_pages(large, 8);
ffffffffc0200760:	45a1                	li	a1,8
ffffffffc0200762:	732000ef          	jal	ffffffffc0200e94 <free_pages>
    buddy_deterministic_tests();
    cprintf("[buddy_check] deterministic tests done\n");
ffffffffc0200766:	00001517          	auipc	a0,0x1
ffffffffc020076a:	30250513          	addi	a0,a0,770 # ffffffffc0201a68 <etext+0x560>
ffffffffc020076e:	9dbff0ef          	jal	ffffffffc0200148 <cprintf>

    #ifdef ucore_test
    score += 3;  // 3 points for deterministic tests (6 sub-tests)
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc0200772:	4621                	li	a2,8
ffffffffc0200774:	458d                	li	a1,3
ffffffffc0200776:	00001517          	auipc	a0,0x1
ffffffffc020077a:	31a50513          	addi	a0,a0,794 # ffffffffc0201a90 <etext+0x588>
ffffffffc020077e:	9cbff0ef          	jal	ffffffffc0200148 <cprintf>
    #endif

    cprintf("[buddy_check] start randomized stress tests\n");
ffffffffc0200782:	00001517          	auipc	a0,0x1
ffffffffc0200786:	32e50513          	addi	a0,a0,814 # ffffffffc0201ab0 <etext+0x5a8>
        seed = seed * 1103515245 + 12345;
ffffffffc020078a:	41c65b37          	lui	s6,0x41c65
ffffffffc020078e:	6a8d                	lui	s5,0x3
    cprintf("[buddy_check] start randomized stress tests\n");
ffffffffc0200790:	9b9ff0ef          	jal	ffffffffc0200148 <cprintf>
        seed = seed * 1103515245 + 12345;
ffffffffc0200794:	e6db0b1b          	addiw	s6,s6,-403 # 41c64e6d <kern_entry-0xffffffff7e59b193>
ffffffffc0200798:	039a8a9b          	addiw	s5,s5,57 # 3039 <kern_entry-0xffffffffc01fcfc7>
    // run randomized tests a few times to increase confidence
    for (int i = 0; i < 4; i++) {
ffffffffc020079c:	4b81                	li	s7,0
ffffffffc020079e:	4c91                	li	s9,4
        cprintf("[buddy_check] randomized round %d\n", i+1);
ffffffffc02007a0:	2b85                	addiw	s7,s7,1
ffffffffc02007a2:	85de                	mv	a1,s7
ffffffffc02007a4:	00001517          	auipc	a0,0x1
ffffffffc02007a8:	33c50513          	addi	a0,a0,828 # ffffffffc0201ae0 <etext+0x5d8>
ffffffffc02007ac:	99dff0ef          	jal	ffffffffc0200148 <cprintf>
static void buddy_random_tests(void) {
ffffffffc02007b0:	8c0a                	mv	s8,sp
    struct Page *allocs[N];
ffffffffc02007b2:	80010113          	addi	sp,sp,-2048
ffffffffc02007b6:	898a                	mv	s3,sp
    size_t sizes[N];
ffffffffc02007b8:	80010113          	addi	sp,sp,-2048
ffffffffc02007bc:	890a                	mv	s2,sp
ffffffffc02007be:	87ce                	mv	a5,s3
ffffffffc02007c0:	870a                	mv	a4,sp
    for (i = 0; i < N; i++) allocs[i] = NULL, sizes[i] = 0;
ffffffffc02007c2:	0007b023          	sd	zero,0(a5)
ffffffffc02007c6:	00073023          	sd	zero,0(a4)
ffffffffc02007ca:	07a1                	addi	a5,a5,8
ffffffffc02007cc:	0721                	addi	a4,a4,8
ffffffffc02007ce:	ff879ae3          	bne	a5,s8,ffffffffc02007c2 <buddy_check+0x202>
ffffffffc02007d2:	7ff90a13          	addi	s4,s2,2047
    unsigned int seed = 0x12345678;
ffffffffc02007d6:	123454b7          	lui	s1,0x12345
ffffffffc02007da:	0a05                	addi	s4,s4,1
ffffffffc02007dc:	67848493          	addi	s1,s1,1656 # 12345678 <kern_entry-0xffffffffadeba988>
    for (i = 0; i < N; i++) allocs[i] = NULL, sizes[i] = 0;
ffffffffc02007e0:	8dce                	mv	s11,s3
ffffffffc02007e2:	8d4a                	mv	s10,s2
        seed = seed * 1103515245 + 12345;
ffffffffc02007e4:	036484bb          	mulw	s1,s1,s6
    for (i = 0; i < N; i++) {
ffffffffc02007e8:	0d21                	addi	s10,s10,8
ffffffffc02007ea:	0da1                	addi	s11,s11,8
        seed = seed * 1103515245 + 12345;
ffffffffc02007ec:	009a84bb          	addw	s1,s5,s1
        size_t s = (r % 16) + 1; // 1..16 pages
ffffffffc02007f0:	02c49793          	slli	a5,s1,0x2c
ffffffffc02007f4:	03c7d513          	srli	a0,a5,0x3c
ffffffffc02007f8:	0505                	addi	a0,a0,1
        sizes[i] = s;
ffffffffc02007fa:	fead3c23          	sd	a0,-8(s10)
        allocs[i] = alloc_pages(s);
ffffffffc02007fe:	68a000ef          	jal	ffffffffc0200e88 <alloc_pages>
ffffffffc0200802:	feadbc23          	sd	a0,-8(s11)
    for (i = 0; i < N; i++) {
ffffffffc0200806:	fd4d1fe3          	bne	s10,s4,ffffffffc02007e4 <buddy_check+0x224>
ffffffffc020080a:	7f890913          	addi	s2,s2,2040
ffffffffc020080e:	7f898493          	addi	s1,s3,2040
ffffffffc0200812:	a011                	j	ffffffffc0200816 <buddy_check+0x256>
ffffffffc0200814:	14e1                	addi	s1,s1,-8
        if (allocs[i]) free_pages(allocs[i], sizes[i]);
ffffffffc0200816:	6088                	ld	a0,0(s1)
ffffffffc0200818:	c509                	beqz	a0,ffffffffc0200822 <buddy_check+0x262>
ffffffffc020081a:	00093583          	ld	a1,0(s2)
ffffffffc020081e:	676000ef          	jal	ffffffffc0200e94 <free_pages>
        if (i == 0) break; // prevent unsigned wrap
ffffffffc0200822:	1961                	addi	s2,s2,-8
ffffffffc0200824:	fe9998e3          	bne	s3,s1,ffffffffc0200814 <buddy_check+0x254>
ffffffffc0200828:	8162                	mv	sp,s8
    for (int i = 0; i < 4; i++) {
ffffffffc020082a:	f79b9be3          	bne	s7,s9,ffffffffc02007a0 <buddy_check+0x1e0>
        buddy_random_tests();
    }
    cprintf("[buddy_check] randomized tests done\n");
ffffffffc020082e:	00001517          	auipc	a0,0x1
ffffffffc0200832:	2da50513          	addi	a0,a0,730 # ffffffffc0201b08 <etext+0x600>
ffffffffc0200836:	913ff0ef          	jal	ffffffffc0200148 <cprintf>

    #ifdef ucore_test
    score += 2;  // 2 points for randomized stress tests
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc020083a:	4621                	li	a2,8
ffffffffc020083c:	4595                	li	a1,5
ffffffffc020083e:	00001517          	auipc	a0,0x1
ffffffffc0200842:	25250513          	addi	a0,a0,594 # ffffffffc0201a90 <etext+0x588>
ffffffffc0200846:	903ff0ef          	jal	ffffffffc0200148 <cprintf>
    #endif

    cprintf("[buddy_check] start final smoke test (allocate single pages until OOM / cap)\n");
ffffffffc020084a:	00001517          	auipc	a0,0x1
ffffffffc020084e:	2e650513          	addi	a0,a0,742 # ffffffffc0201b30 <etext+0x628>
ffffffffc0200852:	8f7ff0ef          	jal	ffffffffc0200148 <cprintf>
    const size_t CAP = 1024;
    const size_t PROG = 128;
    size_t allocated = 0;
    struct Page *plist[CAP];
ffffffffc0200856:	77f9                	lui	a5,0xffffe
ffffffffc0200858:	913e                	add	sp,sp,a5
ffffffffc020085a:	898a                	mv	s3,sp
ffffffffc020085c:	890a                	mv	s2,sp
    size_t allocated = 0;
ffffffffc020085e:	4481                	li	s1,0
    while (allocated < CAP) {
ffffffffc0200860:	40000a13          	li	s4,1024
ffffffffc0200864:	a021                	j	ffffffffc020086c <buddy_check+0x2ac>
ffffffffc0200866:	0921                	addi	s2,s2,8
ffffffffc0200868:	03448763          	beq	s1,s4,ffffffffc0200896 <buddy_check+0x2d6>
        struct Page *q = alloc_page();
ffffffffc020086c:	4505                	li	a0,1
ffffffffc020086e:	61a000ef          	jal	ffffffffc0200e88 <alloc_pages>
        if (!q) break;
ffffffffc0200872:	cd45                	beqz	a0,ffffffffc020092a <buddy_check+0x36a>
        plist[allocated++] = q;
ffffffffc0200874:	0485                	addi	s1,s1,1
ffffffffc0200876:	00a93023          	sd	a0,0(s2)
        if ((allocated % PROG) == 0) {
ffffffffc020087a:	07f4f793          	andi	a5,s1,127
ffffffffc020087e:	f7e5                	bnez	a5,ffffffffc0200866 <buddy_check+0x2a6>
            cprintf("[buddy_check] final smoke progress: allocated %u pages\n", (unsigned)allocated);
ffffffffc0200880:	0004859b          	sext.w	a1,s1
ffffffffc0200884:	00001517          	auipc	a0,0x1
ffffffffc0200888:	2fc50513          	addi	a0,a0,764 # ffffffffc0201b80 <etext+0x678>
ffffffffc020088c:	8bdff0ef          	jal	ffffffffc0200148 <cprintf>
    while (allocated < CAP) {
ffffffffc0200890:	0921                	addi	s2,s2,8
ffffffffc0200892:	fd449de3          	bne	s1,s4,ffffffffc020086c <buddy_check+0x2ac>
        }
    }
    cprintf("[buddy_check] final smoke allocated %u pages (cap=%u), now freeing them\n", (unsigned)allocated, (unsigned)CAP);
ffffffffc0200896:	8626                	mv	a2,s1
ffffffffc0200898:	85a6                	mv	a1,s1
ffffffffc020089a:	00001517          	auipc	a0,0x1
ffffffffc020089e:	31e50513          	addi	a0,a0,798 # ffffffffc0201bb8 <etext+0x6b0>
ffffffffc02008a2:	8a7ff0ef          	jal	ffffffffc0200148 <cprintf>

    #ifdef ucore_test
    score += 2;  // 2 points for successful allocation
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc02008a6:	4621                	li	a2,8
ffffffffc02008a8:	459d                	li	a1,7
ffffffffc02008aa:	00001517          	auipc	a0,0x1
ffffffffc02008ae:	1e650513          	addi	a0,a0,486 # ffffffffc0201a90 <etext+0x588>
ffffffffc02008b2:	897ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc02008b6:	8a26                	mv	s4,s1
ffffffffc02008b8:	4901                	li	s2,0
ffffffffc02008ba:	a021                	j	ffffffffc02008c2 <buddy_check+0x302>
    #endif

    for (size_t j = 0; j < allocated; j++) {
ffffffffc02008bc:	09a1                	addi	s3,s3,8
ffffffffc02008be:	03248663          	beq	s1,s2,ffffffffc02008ea <buddy_check+0x32a>
        free_page(plist[j]);
ffffffffc02008c2:	0009b503          	ld	a0,0(s3)
ffffffffc02008c6:	4585                	li	a1,1
        if (((j+1) % PROG) == 0) {
ffffffffc02008c8:	0905                	addi	s2,s2,1
        free_page(plist[j]);
ffffffffc02008ca:	5ca000ef          	jal	ffffffffc0200e94 <free_pages>
        if (((j+1) % PROG) == 0) {
ffffffffc02008ce:	07f97793          	andi	a5,s2,127
ffffffffc02008d2:	f7ed                	bnez	a5,ffffffffc02008bc <buddy_check+0x2fc>
            cprintf("[buddy_check] final smoke freeing progress: freed %u pages\n", (unsigned)(j+1));
ffffffffc02008d4:	0009059b          	sext.w	a1,s2
ffffffffc02008d8:	00001517          	auipc	a0,0x1
ffffffffc02008dc:	37850513          	addi	a0,a0,888 # ffffffffc0201c50 <etext+0x748>
ffffffffc02008e0:	869ff0ef          	jal	ffffffffc0200148 <cprintf>
    for (size_t j = 0; j < allocated; j++) {
ffffffffc02008e4:	09a1                	addi	s3,s3,8
ffffffffc02008e6:	fd249ee3          	bne	s1,s2,ffffffffc02008c2 <buddy_check+0x302>
        }
    }

    #ifdef ucore_test
    score += 1;  // 1 point for successful free and memory recovery
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc02008ea:	4621                	li	a2,8
ffffffffc02008ec:	85b2                	mv	a1,a2
ffffffffc02008ee:	00001517          	auipc	a0,0x1
ffffffffc02008f2:	1a250513          	addi	a0,a0,418 # ffffffffc0201a90 <etext+0x588>
ffffffffc02008f6:	853ff0ef          	jal	ffffffffc0200148 <cprintf>
    #endif

    cprintf("[buddy_check] finished, buddy_check() succeeded! total freed %u pages\n", (unsigned)allocated);
ffffffffc02008fa:	85d2                	mv	a1,s4
ffffffffc02008fc:	00001517          	auipc	a0,0x1
ffffffffc0200900:	30c50513          	addi	a0,a0,780 # ffffffffc0201c08 <etext+0x700>
ffffffffc0200904:	845ff0ef          	jal	ffffffffc0200148 <cprintf>
}
ffffffffc0200908:	f9040113          	addi	sp,s0,-112
ffffffffc020090c:	70a6                	ld	ra,104(sp)
ffffffffc020090e:	7406                	ld	s0,96(sp)
ffffffffc0200910:	64e6                	ld	s1,88(sp)
ffffffffc0200912:	6946                	ld	s2,80(sp)
ffffffffc0200914:	69a6                	ld	s3,72(sp)
ffffffffc0200916:	6a06                	ld	s4,64(sp)
ffffffffc0200918:	7ae2                	ld	s5,56(sp)
ffffffffc020091a:	7b42                	ld	s6,48(sp)
ffffffffc020091c:	7ba2                	ld	s7,40(sp)
ffffffffc020091e:	7c02                	ld	s8,32(sp)
ffffffffc0200920:	6ce2                	ld	s9,24(sp)
ffffffffc0200922:	6d42                	ld	s10,16(sp)
ffffffffc0200924:	6da2                	ld	s11,8(sp)
ffffffffc0200926:	6165                	addi	sp,sp,112
ffffffffc0200928:	8082                	ret
    cprintf("[buddy_check] final smoke allocated %u pages (cap=%u), now freeing them\n", (unsigned)allocated, (unsigned)CAP);
ffffffffc020092a:	00048a1b          	sext.w	s4,s1
ffffffffc020092e:	85d2                	mv	a1,s4
ffffffffc0200930:	40000613          	li	a2,1024
ffffffffc0200934:	00001517          	auipc	a0,0x1
ffffffffc0200938:	28450513          	addi	a0,a0,644 # ffffffffc0201bb8 <etext+0x6b0>
ffffffffc020093c:	80dff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc0200940:	4621                	li	a2,8
ffffffffc0200942:	459d                	li	a1,7
ffffffffc0200944:	00001517          	auipc	a0,0x1
ffffffffc0200948:	14c50513          	addi	a0,a0,332 # ffffffffc0201a90 <etext+0x588>
ffffffffc020094c:	ffcff0ef          	jal	ffffffffc0200148 <cprintf>
    for (size_t j = 0; j < allocated; j++) {
ffffffffc0200950:	f4a5                	bnez	s1,ffffffffc02008b8 <buddy_check+0x2f8>
ffffffffc0200952:	4a01                	li	s4,0
ffffffffc0200954:	bf59                	j	ffffffffc02008ea <buddy_check+0x32a>
    assert(nr_free_pages() == initial_free - 3);
ffffffffc0200956:	00001697          	auipc	a3,0x1
ffffffffc020095a:	eda68693          	addi	a3,a3,-294 # ffffffffc0201830 <etext+0x328>
ffffffffc020095e:	00001617          	auipc	a2,0x1
ffffffffc0200962:	ea260613          	addi	a2,a2,-350 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200966:	0be00593          	li	a1,190
ffffffffc020096a:	00001517          	auipc	a0,0x1
ffffffffc020096e:	eae50513          	addi	a0,a0,-338 # ffffffffc0201818 <etext+0x310>
ffffffffc0200972:	857ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(a);
ffffffffc0200976:	00001697          	auipc	a3,0x1
ffffffffc020097a:	ff268693          	addi	a3,a3,-14 # ffffffffc0201968 <etext+0x460>
ffffffffc020097e:	00001617          	auipc	a2,0x1
ffffffffc0200982:	e8260613          	addi	a2,a2,-382 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200986:	0d200593          	li	a1,210
ffffffffc020098a:	00001517          	auipc	a0,0x1
ffffffffc020098e:	e8e50513          	addi	a0,a0,-370 # ffffffffc0201818 <etext+0x310>
ffffffffc0200992:	837ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free_pages() == initial_free);
ffffffffc0200996:	00001697          	auipc	a3,0x1
ffffffffc020099a:	f0268693          	addi	a3,a3,-254 # ffffffffc0201898 <etext+0x390>
ffffffffc020099e:	00001617          	auipc	a2,0x1
ffffffffc02009a2:	e6260613          	addi	a2,a2,-414 # ffffffffc0201800 <etext+0x2f8>
ffffffffc02009a6:	0ce00593          	li	a1,206
ffffffffc02009aa:	00001517          	auipc	a0,0x1
ffffffffc02009ae:	e6e50513          	addi	a0,a0,-402 # ffffffffc0201818 <etext+0x310>
ffffffffc02009b2:	817ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free_pages() == initial_free - 6);
ffffffffc02009b6:	00001697          	auipc	a3,0x1
ffffffffc02009ba:	f4a68693          	addi	a3,a3,-182 # ffffffffc0201900 <etext+0x3f8>
ffffffffc02009be:	00001617          	auipc	a2,0x1
ffffffffc02009c2:	e4260613          	addi	a2,a2,-446 # ffffffffc0201800 <etext+0x2f8>
ffffffffc02009c6:	0cb00593          	li	a1,203
ffffffffc02009ca:	00001517          	auipc	a0,0x1
ffffffffc02009ce:	e4e50513          	addi	a0,a0,-434 # ffffffffc0201818 <etext+0x310>
ffffffffc02009d2:	ff6ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(a && b);
ffffffffc02009d6:	00001697          	auipc	a3,0x1
ffffffffc02009da:	f2268693          	addi	a3,a3,-222 # ffffffffc02018f8 <etext+0x3f0>
ffffffffc02009de:	00001617          	auipc	a2,0x1
ffffffffc02009e2:	e2260613          	addi	a2,a2,-478 # ffffffffc0201800 <etext+0x2f8>
ffffffffc02009e6:	0ca00593          	li	a1,202
ffffffffc02009ea:	00001517          	auipc	a0,0x1
ffffffffc02009ee:	e2e50513          	addi	a0,a0,-466 # ffffffffc0201818 <etext+0x310>
ffffffffc02009f2:	fd6ff0ef          	jal	ffffffffc02001c8 <__panic>
        assert(nr_free_pages() <= initial_free - (1 << (MAX_ORDER - 1)));
ffffffffc02009f6:	00001697          	auipc	a3,0x1
ffffffffc02009fa:	fd268693          	addi	a3,a3,-46 # ffffffffc02019c8 <etext+0x4c0>
ffffffffc02009fe:	00001617          	auipc	a2,0x1
ffffffffc0200a02:	e0260613          	addi	a2,a2,-510 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200a06:	0d900593          	li	a1,217
ffffffffc0200a0a:	00001517          	auipc	a0,0x1
ffffffffc0200a0e:	e0e50513          	addi	a0,a0,-498 # ffffffffc0201818 <etext+0x310>
ffffffffc0200a12:	fb6ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free_pages() <= initial_free - 4);
ffffffffc0200a16:	00001697          	auipc	a3,0x1
ffffffffc0200a1a:	f5a68693          	addi	a3,a3,-166 # ffffffffc0201970 <etext+0x468>
ffffffffc0200a1e:	00001617          	auipc	a2,0x1
ffffffffc0200a22:	de260613          	addi	a2,a2,-542 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200a26:	0d300593          	li	a1,211
ffffffffc0200a2a:	00001517          	auipc	a0,0x1
ffffffffc0200a2e:	dee50513          	addi	a0,a0,-530 # ffffffffc0201818 <etext+0x310>
ffffffffc0200a32:	f96ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(a && b && c && d);
ffffffffc0200a36:	00001697          	auipc	a3,0x1
ffffffffc0200a3a:	01a68693          	addi	a3,a3,26 # ffffffffc0201a50 <etext+0x548>
ffffffffc0200a3e:	00001617          	auipc	a2,0x1
ffffffffc0200a42:	dc260613          	addi	a2,a2,-574 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200a46:	0e300593          	li	a1,227
ffffffffc0200a4a:	00001517          	auipc	a0,0x1
ffffffffc0200a4e:	dce50513          	addi	a0,a0,-562 # ffffffffc0201818 <etext+0x310>
ffffffffc0200a52:	f76ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(a && b && c);
ffffffffc0200a56:	00001697          	auipc	a3,0x1
ffffffffc0200a5a:	d9a68693          	addi	a3,a3,-614 # ffffffffc02017f0 <etext+0x2e8>
ffffffffc0200a5e:	00001617          	auipc	a2,0x1
ffffffffc0200a62:	da260613          	addi	a2,a2,-606 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200a66:	0bd00593          	li	a1,189
ffffffffc0200a6a:	00001517          	auipc	a0,0x1
ffffffffc0200a6e:	dae50513          	addi	a0,a0,-594 # ffffffffc0201818 <etext+0x310>
ffffffffc0200a72:	f56ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free_pages() == initial_free);
ffffffffc0200a76:	00001697          	auipc	a3,0x1
ffffffffc0200a7a:	e2268693          	addi	a3,a3,-478 # ffffffffc0201898 <etext+0x390>
ffffffffc0200a7e:	00001617          	auipc	a2,0x1
ffffffffc0200a82:	d8260613          	addi	a2,a2,-638 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200a86:	0c500593          	li	a1,197
ffffffffc0200a8a:	00001517          	auipc	a0,0x1
ffffffffc0200a8e:	d8e50513          	addi	a0,a0,-626 # ffffffffc0201818 <etext+0x310>
ffffffffc0200a92:	f36ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200a96 <buddy_alloc_pages>:
    if (n == 0 || n > free_area.nr_free) return NULL;
ffffffffc0200a96:	c57d                	beqz	a0,ffffffffc0200b84 <buddy_alloc_pages+0xee>
ffffffffc0200a98:	00005817          	auipc	a6,0x5
ffffffffc0200a9c:	64082803          	lw	a6,1600(a6) # ffffffffc02060d8 <free_area+0x10>
ffffffffc0200aa0:	02081793          	slli	a5,a6,0x20
ffffffffc0200aa4:	9381                	srli	a5,a5,0x20
ffffffffc0200aa6:	0ea7e063          	bltu	a5,a0,ffffffffc0200b86 <buddy_alloc_pages+0xf0>
    unsigned int need_order = size_to_order(n);
ffffffffc0200aaa:	2501                	sext.w	a0,a0
    while (s < n) { s <<= 1; o++; }
ffffffffc0200aac:	4785                	li	a5,1
    unsigned int o = 0;
ffffffffc0200aae:	4601                	li	a2,0
    while (s < n) { s <<= 1; o++; }
ffffffffc0200ab0:	00f50a63          	beq	a0,a5,ffffffffc0200ac4 <buddy_alloc_pages+0x2e>
ffffffffc0200ab4:	0017979b          	slliw	a5,a5,0x1
ffffffffc0200ab8:	2605                	addiw	a2,a2,1
ffffffffc0200aba:	fea7ede3          	bltu	a5,a0,ffffffffc0200ab4 <buddy_alloc_pages+0x1e>
    for (o = need_order; o <= MAX_ORDER; o++) {
ffffffffc0200abe:	47a9                	li	a5,10
ffffffffc0200ac0:	0cc7e363          	bltu	a5,a2,ffffffffc0200b86 <buddy_alloc_pages+0xf0>
ffffffffc0200ac4:	02061793          	slli	a5,a2,0x20
ffffffffc0200ac8:	01c7d713          	srli	a4,a5,0x1c
ffffffffc0200acc:	00005697          	auipc	a3,0x5
ffffffffc0200ad0:	54c68693          	addi	a3,a3,1356 # ffffffffc0206018 <free_lists>
ffffffffc0200ad4:	9736                	add	a4,a4,a3
ffffffffc0200ad6:	87b2                	mv	a5,a2
ffffffffc0200ad8:	452d                	li	a0,11
ffffffffc0200ada:	a029                	j	ffffffffc0200ae4 <buddy_alloc_pages+0x4e>
ffffffffc0200adc:	2785                	addiw	a5,a5,1 # ffffffffffffe001 <end+0x3fdf7ed1>
ffffffffc0200ade:	0741                	addi	a4,a4,16
ffffffffc0200ae0:	0aa78363          	beq	a5,a0,ffffffffc0200b86 <buddy_alloc_pages+0xf0>
        if (!list_empty(&free_lists[o])) break;
ffffffffc0200ae4:	670c                	ld	a1,8(a4)
ffffffffc0200ae6:	fee58be3          	beq	a1,a4,ffffffffc0200adc <buddy_alloc_pages+0x46>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200aea:	02079593          	slli	a1,a5,0x20
ffffffffc0200aee:	01c5d713          	srli	a4,a1,0x1c
ffffffffc0200af2:	9736                	add	a4,a4,a3
ffffffffc0200af4:	6718                	ld	a4,8(a4)
    free_area.nr_free -= (1UL << b->order);
ffffffffc0200af6:	4305                	li	t1,1
ffffffffc0200af8:	4b0c                	lw	a1,16(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200afa:	00073e03          	ld	t3,0(a4)
ffffffffc0200afe:	00873883          	ld	a7,8(a4)
ffffffffc0200b02:	00b315b3          	sll	a1,t1,a1
    struct Page *base = b->base;
ffffffffc0200b06:	6f08                	ld	a0,24(a4)
    free_area.nr_free -= (1UL << b->order);
ffffffffc0200b08:	40b8083b          	subw	a6,a6,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200b0c:	011e3423          	sd	a7,8(t3)
ffffffffc0200b10:	00005717          	auipc	a4,0x5
ffffffffc0200b14:	5d072423          	sw	a6,1480(a4) # ffffffffc02060d8 <free_area+0x10>
    next->prev = prev;
ffffffffc0200b18:	01c8b023          	sd	t3,0(a7)
    while (o > need_order) {
ffffffffc0200b1c:	06f67063          	bgeu	a2,a5,ffffffffc0200b7c <buddy_alloc_pages+0xe6>
ffffffffc0200b20:	37fd                	addiw	a5,a5,-1
ffffffffc0200b22:	02079593          	slli	a1,a5,0x20
ffffffffc0200b26:	01c5d713          	srli	a4,a1,0x1c
ffffffffc0200b2a:	00005897          	auipc	a7,0x5
ffffffffc0200b2e:	5ce8a883          	lw	a7,1486(a7) # ffffffffc02060f8 <max_order_inited>
ffffffffc0200b32:	96ba                	add	a3,a3,a4
ffffffffc0200b34:	4e81                	li	t4,0
        struct Page *buddy = blk + (1UL << o);
ffffffffc0200b36:	02800e13          	li	t3,40
ffffffffc0200b3a:	a011                	j	ffffffffc0200b3e <buddy_alloc_pages+0xa8>
ffffffffc0200b3c:	37fd                	addiw	a5,a5,-1
ffffffffc0200b3e:	00fe1733          	sll	a4,t3,a5
ffffffffc0200b42:	972a                	add	a4,a4,a0
    free_area.nr_free += (1UL << order);
ffffffffc0200b44:	00f315b3          	sll	a1,t1,a5
    b->order = order;
ffffffffc0200b48:	cb1c                	sw	a5,16(a4)
    b->base = base;
ffffffffc0200b4a:	ef18                	sd	a4,24(a4)
    free_area.nr_free += (1UL << order);
ffffffffc0200b4c:	0105883b          	addw	a6,a1,a6
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b50:	668c                	ld	a1,8(a3)
    if (order > max_order_inited) max_order_inited = order;
ffffffffc0200b52:	00f8f463          	bgeu	a7,a5,ffffffffc0200b5a <buddy_alloc_pages+0xc4>
ffffffffc0200b56:	88be                	mv	a7,a5
ffffffffc0200b58:	4e85                	li	t4,1
    prev->next = next->prev = elm;
ffffffffc0200b5a:	e198                	sd	a4,0(a1)
ffffffffc0200b5c:	e698                	sd	a4,8(a3)
    elm->prev = prev;
ffffffffc0200b5e:	e314                	sd	a3,0(a4)
    elm->next = next;
ffffffffc0200b60:	e70c                	sd	a1,8(a4)
    while (o > need_order) {
ffffffffc0200b62:	16c1                	addi	a3,a3,-16
ffffffffc0200b64:	fcf61ce3          	bne	a2,a5,ffffffffc0200b3c <buddy_alloc_pages+0xa6>
ffffffffc0200b68:	00005797          	auipc	a5,0x5
ffffffffc0200b6c:	5707a823          	sw	a6,1392(a5) # ffffffffc02060d8 <free_area+0x10>
ffffffffc0200b70:	000e8663          	beqz	t4,ffffffffc0200b7c <buddy_alloc_pages+0xe6>
ffffffffc0200b74:	00005797          	auipc	a5,0x5
ffffffffc0200b78:	5917a223          	sw	a7,1412(a5) # ffffffffc02060f8 <max_order_inited>
    ClearPageProperty(blk);
ffffffffc0200b7c:	651c                	ld	a5,8(a0)
ffffffffc0200b7e:	9bf5                	andi	a5,a5,-3
ffffffffc0200b80:	e51c                	sd	a5,8(a0)
    return blk;
ffffffffc0200b82:	8082                	ret
}
ffffffffc0200b84:	8082                	ret
    if (n == 0 || n > free_area.nr_free) return NULL;
ffffffffc0200b86:	4501                	li	a0,0
ffffffffc0200b88:	8082                	ret

ffffffffc0200b8a <buddy_init_memmap>:
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200b8a:	7179                	addi	sp,sp,-48
ffffffffc0200b8c:	f022                	sd	s0,32(sp)
ffffffffc0200b8e:	f406                	sd	ra,40(sp)
ffffffffc0200b90:	ec26                	sd	s1,24(sp)
ffffffffc0200b92:	842e                	mv	s0,a1
    assert(n > 0);
ffffffffc0200b94:	18058063          	beqz	a1,ffffffffc0200d14 <buddy_init_memmap+0x18a>
    cprintf("[buddy] buddy_init_memmap: base=%p n=%u\n", base, (unsigned)n);
ffffffffc0200b98:	85aa                	mv	a1,a0
ffffffffc0200b9a:	e42a                	sd	a0,8(sp)
ffffffffc0200b9c:	0004061b          	sext.w	a2,s0
ffffffffc0200ba0:	00001517          	auipc	a0,0x1
ffffffffc0200ba4:	0f850513          	addi	a0,a0,248 # ffffffffc0201c98 <etext+0x790>
ffffffffc0200ba8:	da0ff0ef          	jal	ffffffffc0200148 <cprintf>
    for (; p < base + n; p++) {
ffffffffc0200bac:	65a2                	ld	a1,8(sp)
ffffffffc0200bae:	00241693          	slli	a3,s0,0x2
ffffffffc0200bb2:	96a2                	add	a3,a3,s0
ffffffffc0200bb4:	068e                	slli	a3,a3,0x3
ffffffffc0200bb6:	96ae                	add	a3,a3,a1
    struct Page *p = base;
ffffffffc0200bb8:	87ae                	mv	a5,a1
    for (; p < base + n; p++) {
ffffffffc0200bba:	02d5f063          	bgeu	a1,a3,ffffffffc0200bda <buddy_init_memmap+0x50>
        assert(PageReserved(p));
ffffffffc0200bbe:	6798                	ld	a4,8(a5)
ffffffffc0200bc0:	8b05                	andi	a4,a4,1
ffffffffc0200bc2:	12070963          	beqz	a4,ffffffffc0200cf4 <buddy_init_memmap+0x16a>
        p->flags = p->property = 0;
ffffffffc0200bc6:	0007a823          	sw	zero,16(a5)
ffffffffc0200bca:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200bce:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++) {
ffffffffc0200bd2:	02878793          	addi	a5,a5,40
ffffffffc0200bd6:	fed7e4e3          	bltu	a5,a3,ffffffffc0200bbe <buddy_init_memmap+0x34>
    while (remain > 0) {
ffffffffc0200bda:	00005317          	auipc	t1,0x5
ffffffffc0200bde:	4fe32303          	lw	t1,1278(t1) # ffffffffc02060d8 <free_area+0x10>
ffffffffc0200be2:	00005e17          	auipc	t3,0x5
ffffffffc0200be6:	516e2e03          	lw	t3,1302(t3) # ffffffffc02060f8 <max_order_inited>
    struct Page *p = base;
ffffffffc0200bea:	4e81                	li	t4,0
ffffffffc0200bec:	00005517          	auipc	a0,0x5
ffffffffc0200bf0:	42c50513          	addi	a0,a0,1068 # ffffffffc0206018 <free_lists>
        while ((1UL << (o + 1)) <= remain) o++;
ffffffffc0200bf4:	4605                	li	a2,1
        if (o > MAX_ORDER) {
ffffffffc0200bf6:	4829                	li	a6,10
            cur += (1UL << o);
ffffffffc0200bf8:	02800f13          	li	t5,40
    if (order > max_order_inited) max_order_inited = order;
ffffffffc0200bfc:	4fa5                	li	t6,9
                cur += (1UL << MAX_ORDER);
ffffffffc0200bfe:	68a9                	lui	a7,0xa
        unsigned int o = 0;
ffffffffc0200c00:	4781                	li	a5,0
        while ((1UL << (o + 1)) <= remain) o++;
ffffffffc0200c02:	86be                	mv	a3,a5
ffffffffc0200c04:	2785                	addiw	a5,a5,1
ffffffffc0200c06:	00f61733          	sll	a4,a2,a5
ffffffffc0200c0a:	fee47ce3          	bgeu	s0,a4,ffffffffc0200c02 <buddy_init_memmap+0x78>
            unsigned int blocks = (1UL << o) / (1UL << MAX_ORDER);
ffffffffc0200c0e:	00d617b3          	sll	a5,a2,a3
        if (o > MAX_ORDER) {
ffffffffc0200c12:	06d86563          	bltu	a6,a3,ffffffffc0200c7c <buddy_init_memmap+0xf2>
    list_add(&free_lists[order], &b->link);
ffffffffc0200c16:	02069713          	slli	a4,a3,0x20
ffffffffc0200c1a:	9301                	srli	a4,a4,0x20
ffffffffc0200c1c:	00471293          	slli	t0,a4,0x4
ffffffffc0200c20:	92aa                	add	t0,t0,a0
    b->order = order;
ffffffffc0200c22:	c994                	sw	a3,16(a1)
    b->base = base;
ffffffffc0200c24:	ed8c                	sd	a1,24(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c26:	0082b383          	ld	t2,8(t0)
    free_area.nr_free += (1UL << order);
ffffffffc0200c2a:	0067833b          	addw	t1,a5,t1
    if (order > max_order_inited) max_order_inited = order;
ffffffffc0200c2e:	00de7463          	bgeu	t3,a3,ffffffffc0200c36 <buddy_init_memmap+0xac>
ffffffffc0200c32:	8e36                	mv	t3,a3
ffffffffc0200c34:	4e85                	li	t4,1
    prev->next = next->prev = elm;
ffffffffc0200c36:	0712                	slli	a4,a4,0x4
ffffffffc0200c38:	00b3b023          	sd	a1,0(t2)
ffffffffc0200c3c:	972a                	add	a4,a4,a0
ffffffffc0200c3e:	e70c                	sd	a1,8(a4)
            cur += (1UL << o);
ffffffffc0200c40:	00df16b3          	sll	a3,t5,a3
    elm->next = next;
ffffffffc0200c44:	0075b423          	sd	t2,8(a1)
    elm->prev = prev;
ffffffffc0200c48:	0055b023          	sd	t0,0(a1)
            remain -= (1UL << o);
ffffffffc0200c4c:	8c1d                	sub	s0,s0,a5
            cur += (1UL << o);
ffffffffc0200c4e:	95b6                	add	a1,a1,a3
    while (remain > 0) {
ffffffffc0200c50:	f845                	bnez	s0,ffffffffc0200c00 <buddy_init_memmap+0x76>
ffffffffc0200c52:	000e8663          	beqz	t4,ffffffffc0200c5e <buddy_init_memmap+0xd4>
ffffffffc0200c56:	00005797          	auipc	a5,0x5
ffffffffc0200c5a:	4bc7a123          	sw	t3,1186(a5) # ffffffffc02060f8 <max_order_inited>
}
ffffffffc0200c5e:	7402                	ld	s0,32(sp)
ffffffffc0200c60:	70a2                	ld	ra,40(sp)
ffffffffc0200c62:	64e2                	ld	s1,24(sp)
ffffffffc0200c64:	00005797          	auipc	a5,0x5
ffffffffc0200c68:	4667aa23          	sw	t1,1140(a5) # ffffffffc02060d8 <free_area+0x10>
    cprintf("[buddy] buddy_init_memmap: finished, total free pages=%u\n", (unsigned)free_area.nr_free);
ffffffffc0200c6c:	859a                	mv	a1,t1
ffffffffc0200c6e:	00001517          	auipc	a0,0x1
ffffffffc0200c72:	06a50513          	addi	a0,a0,106 # ffffffffc0201cd8 <etext+0x7d0>
}
ffffffffc0200c76:	6145                	addi	sp,sp,48
    cprintf("[buddy] buddy_init_memmap: finished, total free pages=%u\n", (unsigned)free_area.nr_free);
ffffffffc0200c78:	cd0ff06f          	j	ffffffffc0200148 <cprintf>
            unsigned int blocks = (1UL << o) / (1UL << MAX_ORDER);
ffffffffc0200c7c:	83a9                	srli	a5,a5,0xa
ffffffffc0200c7e:	0007871b          	sext.w	a4,a5
            for (unsigned int b = 0; b < blocks; b++) {
ffffffffc0200c82:	df3d                	beqz	a4,ffffffffc0200c00 <buddy_init_memmap+0x76>
ffffffffc0200c84:	1782                	slli	a5,a5,0x20
ffffffffc0200c86:	9381                	srli	a5,a5,0x20
ffffffffc0200c88:	00279693          	slli	a3,a5,0x2
ffffffffc0200c8c:	fff7039b          	addiw	t2,a4,-1
ffffffffc0200c90:	96be                	add	a3,a3,a5
ffffffffc0200c92:	06b6                	slli	a3,a3,0xd
ffffffffc0200c94:	02039493          	slli	s1,t2,0x20
    b->order = order;
ffffffffc0200c98:	0105a823          	sw	a6,16(a1)
    b->base = base;
ffffffffc0200c9c:	ed8c                	sd	a1,24(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c9e:	7558                	ld	a4,168(a0)
ffffffffc0200ca0:	96ae                	add	a3,a3,a1
    if (order > max_order_inited) max_order_inited = order;
ffffffffc0200ca2:	9081                	srli	s1,s1,0x20
ffffffffc0200ca4:	87ae                	mv	a5,a1
ffffffffc0200ca6:	01cfe463          	bltu	t6,t3,ffffffffc0200cae <buddy_init_memmap+0x124>
ffffffffc0200caa:	4e85                	li	t4,1
ffffffffc0200cac:	4e29                	li	t3,10
ffffffffc0200cae:	00005297          	auipc	t0,0x5
ffffffffc0200cb2:	40a28293          	addi	t0,t0,1034 # ffffffffc02060b8 <free_lists+0xa0>
ffffffffc0200cb6:	a029                	j	ffffffffc0200cc0 <buddy_init_memmap+0x136>
ffffffffc0200cb8:	7558                	ld	a4,168(a0)
    b->order = order;
ffffffffc0200cba:	0107a823          	sw	a6,16(a5)
    b->base = base;
ffffffffc0200cbe:	ef9c                	sd	a5,24(a5)
    prev->next = next->prev = elm;
ffffffffc0200cc0:	e31c                	sd	a5,0(a4)
ffffffffc0200cc2:	f55c                	sd	a5,168(a0)
    elm->next = next;
ffffffffc0200cc4:	e798                	sd	a4,8(a5)
    elm->prev = prev;
ffffffffc0200cc6:	0057b023          	sd	t0,0(a5)
                cur += (1UL << MAX_ORDER);
ffffffffc0200cca:	97c6                	add	a5,a5,a7
            for (unsigned int b = 0; b < blocks; b++) {
ffffffffc0200ccc:	fef696e3          	bne	a3,a5,ffffffffc0200cb8 <buddy_init_memmap+0x12e>
ffffffffc0200cd0:	00249793          	slli	a5,s1,0x2
ffffffffc0200cd4:	97a6                	add	a5,a5,s1
ffffffffc0200cd6:	c0040413          	addi	s0,s0,-1024
ffffffffc0200cda:	04aa                	slli	s1,s1,0xa
ffffffffc0200cdc:	4003031b          	addiw	t1,t1,1024
    free_area.nr_free += (1UL << order);
ffffffffc0200ce0:	00a3971b          	slliw	a4,t2,0xa
ffffffffc0200ce4:	95c6                	add	a1,a1,a7
ffffffffc0200ce6:	07b6                	slli	a5,a5,0xd
ffffffffc0200ce8:	8c05                	sub	s0,s0,s1
ffffffffc0200cea:	0067033b          	addw	t1,a4,t1
ffffffffc0200cee:	95be                	add	a1,a1,a5
    while (remain > 0) {
ffffffffc0200cf0:	f801                	bnez	s0,ffffffffc0200c00 <buddy_init_memmap+0x76>
ffffffffc0200cf2:	b785                	j	ffffffffc0200c52 <buddy_init_memmap+0xc8>
        assert(PageReserved(p));
ffffffffc0200cf4:	00001697          	auipc	a3,0x1
ffffffffc0200cf8:	fd468693          	addi	a3,a3,-44 # ffffffffc0201cc8 <etext+0x7c0>
ffffffffc0200cfc:	00001617          	auipc	a2,0x1
ffffffffc0200d00:	b0460613          	addi	a2,a2,-1276 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200d04:	05000593          	li	a1,80
ffffffffc0200d08:	00001517          	auipc	a0,0x1
ffffffffc0200d0c:	b1050513          	addi	a0,a0,-1264 # ffffffffc0201818 <etext+0x310>
ffffffffc0200d10:	cb8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200d14:	00001697          	auipc	a3,0x1
ffffffffc0200d18:	f7c68693          	addi	a3,a3,-132 # ffffffffc0201c90 <etext+0x788>
ffffffffc0200d1c:	00001617          	auipc	a2,0x1
ffffffffc0200d20:	ae460613          	addi	a2,a2,-1308 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200d24:	04b00593          	li	a1,75
ffffffffc0200d28:	00001517          	auipc	a0,0x1
ffffffffc0200d2c:	af050513          	addi	a0,a0,-1296 # ffffffffc0201818 <etext+0x310>
ffffffffc0200d30:	c98ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200d34 <buddy_free_pages>:
    assert(n > 0);
ffffffffc0200d34:	12058863          	beqz	a1,ffffffffc0200e64 <buddy_free_pages+0x130>
    unsigned int o = size_to_order(n);
ffffffffc0200d38:	0005871b          	sext.w	a4,a1
    while (s < n) { s <<= 1; o++; }
ffffffffc0200d3c:	4785                	li	a5,1
    unsigned int o = 0;
ffffffffc0200d3e:	4581                	li	a1,0
    while (s < n) { s <<= 1; o++; }
ffffffffc0200d40:	00e7f763          	bgeu	a5,a4,ffffffffc0200d4e <buddy_free_pages+0x1a>
ffffffffc0200d44:	0017979b          	slliw	a5,a5,0x1
ffffffffc0200d48:	2585                	addiw	a1,a1,1
ffffffffc0200d4a:	fee7ede3          	bltu	a5,a4,ffffffffc0200d44 <buddy_free_pages+0x10>
    while (o <= MAX_ORDER) {
ffffffffc0200d4e:	47a9                	li	a5,10
ffffffffc0200d50:	10b7e463          	bltu	a5,a1,ffffffffc0200e58 <buddy_free_pages+0x124>
    return (uintptr_t)(p - pages);
ffffffffc0200d54:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200d58:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac6b9d>
ffffffffc0200d5c:	02079f13          	slli	t5,a5,0x20
ffffffffc0200d60:	00005297          	auipc	t0,0x5
ffffffffc0200d64:	3782a283          	lw	t0,888(t0) # ffffffffc02060d8 <free_area+0x10>
ffffffffc0200d68:	9f3e                	add	t5,t5,a5
ffffffffc0200d6a:	00005e17          	auipc	t3,0x5
ffffffffc0200d6e:	3bee3e03          	ld	t3,958(t3) # ffffffffc0206128 <pages>
ffffffffc0200d72:	02059793          	slli	a5,a1,0x20
ffffffffc0200d76:	01c7d613          	srli	a2,a5,0x1c
ffffffffc0200d7a:	00005397          	auipc	t2,0x5
ffffffffc0200d7e:	29e38393          	addi	t2,t2,670 # ffffffffc0206018 <free_lists>
ffffffffc0200d82:	8896                	mv	a7,t0
ffffffffc0200d84:	961e                	add	a2,a2,t2
ffffffffc0200d86:	4801                	li	a6,0
    uintptr_t buddy_idx = idx ^ (1UL << order);
ffffffffc0200d88:	4e85                	li	t4,1
        if (o > MAX_ORDER) {
ffffffffc0200d8a:	4fad                	li	t6,11
    return (uintptr_t)(p - pages);
ffffffffc0200d8c:	41c506b3          	sub	a3,a0,t3
ffffffffc0200d90:	868d                	srai	a3,a3,0x3
ffffffffc0200d92:	03e686b3          	mul	a3,a3,t5
    uintptr_t buddy_idx = idx ^ (1UL << order);
ffffffffc0200d96:	00be9333          	sll	t1,t4,a1
    list_entry_t *le = &free_lists[order];
ffffffffc0200d9a:	87b2                	mv	a5,a2
    uintptr_t buddy_idx = idx ^ (1UL << order);
ffffffffc0200d9c:	0066c6b3          	xor	a3,a3,t1
    struct Page *buddy_addr = pages + buddy_idx;
ffffffffc0200da0:	00269713          	slli	a4,a3,0x2
ffffffffc0200da4:	9736                	add	a4,a4,a3
ffffffffc0200da6:	070e                	slli	a4,a4,0x3
ffffffffc0200da8:	9772                	add	a4,a4,t3
    while ((le = list_next(le)) != &free_lists[order]) {
ffffffffc0200daa:	a021                	j	ffffffffc0200db2 <buddy_free_pages+0x7e>
        if (b->base == buddy_addr) {
ffffffffc0200dac:	6f94                	ld	a3,24(a5)
ffffffffc0200dae:	04d70563          	beq	a4,a3,ffffffffc0200df8 <buddy_free_pages+0xc4>
    return listelm->next;
ffffffffc0200db2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_lists[order]) {
ffffffffc0200db4:	fec79ce3          	bne	a5,a2,ffffffffc0200dac <buddy_free_pages+0x78>
ffffffffc0200db8:	00081363          	bnez	a6,ffffffffc0200dbe <buddy_free_pages+0x8a>
ffffffffc0200dbc:	8896                	mv	a7,t0
    __list_add(elm, listelm, listelm->next);
ffffffffc0200dbe:	02059713          	slli	a4,a1,0x20
ffffffffc0200dc2:	01c75793          	srli	a5,a4,0x1c
ffffffffc0200dc6:	979e                	add	a5,a5,t2
ffffffffc0200dc8:	6798                	ld	a4,8(a5)
    b->order = order;
ffffffffc0200dca:	c90c                	sw	a1,16(a0)
    b->base = base;
ffffffffc0200dcc:	ed08                	sd	a0,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200dce:	e308                	sd	a0,0(a4)
    if (order > max_order_inited) max_order_inited = order;
ffffffffc0200dd0:	00005697          	auipc	a3,0x5
ffffffffc0200dd4:	3286a683          	lw	a3,808(a3) # ffffffffc02060f8 <max_order_inited>
ffffffffc0200dd8:	e788                	sd	a0,8(a5)
    free_area.nr_free += (1UL << order);
ffffffffc0200dda:	0113033b          	addw	t1,t1,a7
ffffffffc0200dde:	00005797          	auipc	a5,0x5
ffffffffc0200de2:	2e67ad23          	sw	t1,762(a5) # ffffffffc02060d8 <free_area+0x10>
    elm->next = next;
ffffffffc0200de6:	e518                	sd	a4,8(a0)
    elm->prev = prev;
ffffffffc0200de8:	e110                	sd	a2,0(a0)
    if (order > max_order_inited) max_order_inited = order;
ffffffffc0200dea:	06b6f763          	bgeu	a3,a1,ffffffffc0200e58 <buddy_free_pages+0x124>
ffffffffc0200dee:	00005797          	auipc	a5,0x5
ffffffffc0200df2:	30b7a523          	sw	a1,778(a5) # ffffffffc02060f8 <max_order_inited>
ffffffffc0200df6:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200df8:	0007b803          	ld	a6,0(a5)
ffffffffc0200dfc:	6794                	ld	a3,8(a5)
    free_area.nr_free -= (1UL << b->order);
ffffffffc0200dfe:	4b9c                	lw	a5,16(a5)
    prev->next = next;
ffffffffc0200e00:	00d83423          	sd	a3,8(a6)
ffffffffc0200e04:	00fe97b3          	sll	a5,t4,a5
    next->prev = prev;
ffffffffc0200e08:	0106b023          	sd	a6,0(a3)
ffffffffc0200e0c:	40f888bb          	subw	a7,a7,a5
        if (!buddy) {
ffffffffc0200e10:	d75d                	beqz	a4,ffffffffc0200dbe <buddy_free_pages+0x8a>
        if (blk > buddy) {
ffffffffc0200e12:	00a77363          	bgeu	a4,a0,ffffffffc0200e18 <buddy_free_pages+0xe4>
ffffffffc0200e16:	853a                	mv	a0,a4
        o++; // Merged block has order + 1
ffffffffc0200e18:	2585                	addiw	a1,a1,1
        if (o > MAX_ORDER) {
ffffffffc0200e1a:	0641                	addi	a2,a2,16
ffffffffc0200e1c:	4805                	li	a6,1
ffffffffc0200e1e:	f7f597e3          	bne	a1,t6,ffffffffc0200d8c <buddy_free_pages+0x58>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e22:	0a83b783          	ld	a5,168(t2)
    b->order = order;
ffffffffc0200e26:	4729                	li	a4,10
    b->base = base;
ffffffffc0200e28:	ed08                	sd	a0,24(a0)
    b->order = order;
ffffffffc0200e2a:	c918                	sw	a4,16(a0)
    prev->next = next->prev = elm;
ffffffffc0200e2c:	e388                	sd	a0,0(a5)
    if (order > max_order_inited) max_order_inited = order;
ffffffffc0200e2e:	00005697          	auipc	a3,0x5
ffffffffc0200e32:	2ca6a683          	lw	a3,714(a3) # ffffffffc02060f8 <max_order_inited>
ffffffffc0200e36:	0aa3b423          	sd	a0,168(t2)
    free_area.nr_free += (1UL << order);
ffffffffc0200e3a:	4008889b          	addiw	a7,a7,1024 # a400 <kern_entry-0xffffffffc01f5c00>
    elm->prev = prev;
ffffffffc0200e3e:	00005617          	auipc	a2,0x5
ffffffffc0200e42:	27a60613          	addi	a2,a2,634 # ffffffffc02060b8 <free_lists+0xa0>
    elm->next = next;
ffffffffc0200e46:	e51c                	sd	a5,8(a0)
ffffffffc0200e48:	00005597          	auipc	a1,0x5
ffffffffc0200e4c:	2915a823          	sw	a7,656(a1) # ffffffffc02060d8 <free_area+0x10>
    elm->prev = prev;
ffffffffc0200e50:	e110                	sd	a2,0(a0)
    if (order > max_order_inited) max_order_inited = order;
ffffffffc0200e52:	47a5                	li	a5,9
ffffffffc0200e54:	00d7f363          	bgeu	a5,a3,ffffffffc0200e5a <buddy_free_pages+0x126>
ffffffffc0200e58:	8082                	ret
ffffffffc0200e5a:	00005797          	auipc	a5,0x5
ffffffffc0200e5e:	28e7af23          	sw	a4,670(a5) # ffffffffc02060f8 <max_order_inited>
ffffffffc0200e62:	8082                	ret
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200e64:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200e66:	00001697          	auipc	a3,0x1
ffffffffc0200e6a:	e2a68693          	addi	a3,a3,-470 # ffffffffc0201c90 <etext+0x788>
ffffffffc0200e6e:	00001617          	auipc	a2,0x1
ffffffffc0200e72:	99260613          	addi	a2,a2,-1646 # ffffffffc0201800 <etext+0x2f8>
ffffffffc0200e76:	09700593          	li	a1,151
ffffffffc0200e7a:	00001517          	auipc	a0,0x1
ffffffffc0200e7e:	99e50513          	addi	a0,a0,-1634 # ffffffffc0201818 <etext+0x310>
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200e82:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200e84:	b44ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200e88 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200e88:	00005797          	auipc	a5,0x5
ffffffffc0200e8c:	2787b783          	ld	a5,632(a5) # ffffffffc0206100 <pmm_manager>
ffffffffc0200e90:	6f9c                	ld	a5,24(a5)
ffffffffc0200e92:	8782                	jr	a5

ffffffffc0200e94 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200e94:	00005797          	auipc	a5,0x5
ffffffffc0200e98:	26c7b783          	ld	a5,620(a5) # ffffffffc0206100 <pmm_manager>
ffffffffc0200e9c:	739c                	ld	a5,32(a5)
ffffffffc0200e9e:	8782                	jr	a5

ffffffffc0200ea0 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200ea0:	00005797          	auipc	a5,0x5
ffffffffc0200ea4:	2607b783          	ld	a5,608(a5) # ffffffffc0206100 <pmm_manager>
ffffffffc0200ea8:	779c                	ld	a5,40(a5)
ffffffffc0200eaa:	8782                	jr	a5

ffffffffc0200eac <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200eac:	00001797          	auipc	a5,0x1
ffffffffc0200eb0:	0a478793          	addi	a5,a5,164 # ffffffffc0201f50 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200eb4:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200eb6:	7139                	addi	sp,sp,-64
ffffffffc0200eb8:	fc06                	sd	ra,56(sp)
ffffffffc0200eba:	f822                	sd	s0,48(sp)
ffffffffc0200ebc:	f426                	sd	s1,40(sp)
ffffffffc0200ebe:	ec4e                	sd	s3,24(sp)
ffffffffc0200ec0:	f04a                	sd	s2,32(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200ec2:	00005417          	auipc	s0,0x5
ffffffffc0200ec6:	23e40413          	addi	s0,s0,574 # ffffffffc0206100 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200eca:	00001517          	auipc	a0,0x1
ffffffffc0200ece:	e6650513          	addi	a0,a0,-410 # ffffffffc0201d30 <etext+0x828>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200ed2:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ed4:	a74ff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc0200ed8:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200eda:	00005497          	auipc	s1,0x5
ffffffffc0200ede:	23e48493          	addi	s1,s1,574 # ffffffffc0206118 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200ee2:	679c                	ld	a5,8(a5)
ffffffffc0200ee4:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ee6:	57f5                	li	a5,-3
ffffffffc0200ee8:	07fa                	slli	a5,a5,0x1e
ffffffffc0200eea:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200eec:	e6eff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc0200ef0:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200ef2:	e72ff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200ef6:	14050c63          	beqz	a0,ffffffffc020104e <pmm_init+0x1a2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200efa:	00a98933          	add	s2,s3,a0
ffffffffc0200efe:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc0200f00:	00001517          	auipc	a0,0x1
ffffffffc0200f04:	e7850513          	addi	a0,a0,-392 # ffffffffc0201d78 <etext+0x870>
ffffffffc0200f08:	a40ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200f0c:	65a2                	ld	a1,8(sp)
ffffffffc0200f0e:	864e                	mv	a2,s3
ffffffffc0200f10:	fff90693          	addi	a3,s2,-1
ffffffffc0200f14:	00001517          	auipc	a0,0x1
ffffffffc0200f18:	e7c50513          	addi	a0,a0,-388 # ffffffffc0201d90 <etext+0x888>
ffffffffc0200f1c:	a2cff0ef          	jal	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0200f20:	c80007b7          	lui	a5,0xc8000
ffffffffc0200f24:	85ca                	mv	a1,s2
ffffffffc0200f26:	0d27e263          	bltu	a5,s2,ffffffffc0200fea <pmm_init+0x13e>
ffffffffc0200f2a:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200f2c:	00006697          	auipc	a3,0x6
ffffffffc0200f30:	20368693          	addi	a3,a3,515 # ffffffffc020712f <end+0xfff>
ffffffffc0200f34:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc0200f36:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f38:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc0200f3c:	00005797          	auipc	a5,0x5
ffffffffc0200f40:	1eb7b223          	sd	a1,484(a5) # ffffffffc0206120 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200f44:	00005797          	auipc	a5,0x5
ffffffffc0200f48:	1ed7b223          	sd	a3,484(a5) # ffffffffc0206128 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f4c:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200f4e:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f50:	02080963          	beqz	a6,ffffffffc0200f82 <pmm_init+0xd6>
ffffffffc0200f54:	00259613          	slli	a2,a1,0x2
ffffffffc0200f58:	962e                	add	a2,a2,a1
ffffffffc0200f5a:	fec007b7          	lui	a5,0xfec00
ffffffffc0200f5e:	97b6                	add	a5,a5,a3
ffffffffc0200f60:	060e                	slli	a2,a2,0x3
ffffffffc0200f62:	963e                	add	a2,a2,a5
ffffffffc0200f64:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc0200f66:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f68:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9ef8>
        SetPageReserved(pages + i);
ffffffffc0200f6c:	00176713          	ori	a4,a4,1
ffffffffc0200f70:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f74:	fec799e3          	bne	a5,a2,ffffffffc0200f66 <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f78:	00281793          	slli	a5,a6,0x2
ffffffffc0200f7c:	97c2                	add	a5,a5,a6
ffffffffc0200f7e:	078e                	slli	a5,a5,0x3
ffffffffc0200f80:	96be                	add	a3,a3,a5
ffffffffc0200f82:	c02007b7          	lui	a5,0xc0200
ffffffffc0200f86:	0af6e863          	bltu	a3,a5,ffffffffc0201036 <pmm_init+0x18a>
ffffffffc0200f8a:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200f8c:	77fd                	lui	a5,0xfffff
ffffffffc0200f8e:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f92:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200f94:	0526ed63          	bltu	a3,s2,ffffffffc0200fee <pmm_init+0x142>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200f98:	601c                	ld	a5,0(s0)
ffffffffc0200f9a:	7b9c                	ld	a5,48(a5)
ffffffffc0200f9c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	e7a50513          	addi	a0,a0,-390 # ffffffffc0201e18 <etext+0x910>
ffffffffc0200fa6:	9a2ff0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200faa:	00004597          	auipc	a1,0x4
ffffffffc0200fae:	05658593          	addi	a1,a1,86 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200fb2:	00005797          	auipc	a5,0x5
ffffffffc0200fb6:	14b7bf23          	sd	a1,350(a5) # ffffffffc0206110 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200fba:	c02007b7          	lui	a5,0xc0200
ffffffffc0200fbe:	0af5e463          	bltu	a1,a5,ffffffffc0201066 <pmm_init+0x1ba>
ffffffffc0200fc2:	609c                	ld	a5,0(s1)
}
ffffffffc0200fc4:	7442                	ld	s0,48(sp)
ffffffffc0200fc6:	70e2                	ld	ra,56(sp)
ffffffffc0200fc8:	74a2                	ld	s1,40(sp)
ffffffffc0200fca:	7902                	ld	s2,32(sp)
ffffffffc0200fcc:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200fce:	40f586b3          	sub	a3,a1,a5
ffffffffc0200fd2:	00005797          	auipc	a5,0x5
ffffffffc0200fd6:	12d7bb23          	sd	a3,310(a5) # ffffffffc0206108 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200fda:	00001517          	auipc	a0,0x1
ffffffffc0200fde:	e5e50513          	addi	a0,a0,-418 # ffffffffc0201e38 <etext+0x930>
ffffffffc0200fe2:	8636                	mv	a2,a3
}
ffffffffc0200fe4:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200fe6:	962ff06f          	j	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0200fea:	85be                	mv	a1,a5
ffffffffc0200fec:	bf3d                	j	ffffffffc0200f2a <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200fee:	6705                	lui	a4,0x1
ffffffffc0200ff0:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0200ff2:	96ba                	add	a3,a3,a4
ffffffffc0200ff4:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200ff6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200ffa:	02b7f263          	bgeu	a5,a1,ffffffffc020101e <pmm_init+0x172>
    pmm_manager->init_memmap(base, n);
ffffffffc0200ffe:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201000:	fff80637          	lui	a2,0xfff80
ffffffffc0201004:	97b2                	add	a5,a5,a2
ffffffffc0201006:	00279513          	slli	a0,a5,0x2
ffffffffc020100a:	953e                	add	a0,a0,a5
ffffffffc020100c:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020100e:	40d90933          	sub	s2,s2,a3
ffffffffc0201012:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201014:	00c95593          	srli	a1,s2,0xc
ffffffffc0201018:	9546                	add	a0,a0,a7
ffffffffc020101a:	9782                	jalr	a5
}
ffffffffc020101c:	bfb5                	j	ffffffffc0200f98 <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc020101e:	00001617          	auipc	a2,0x1
ffffffffc0201022:	dca60613          	addi	a2,a2,-566 # ffffffffc0201de8 <etext+0x8e0>
ffffffffc0201026:	06a00593          	li	a1,106
ffffffffc020102a:	00001517          	auipc	a0,0x1
ffffffffc020102e:	dde50513          	addi	a0,a0,-546 # ffffffffc0201e08 <etext+0x900>
ffffffffc0201032:	996ff0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201036:	00001617          	auipc	a2,0x1
ffffffffc020103a:	d8a60613          	addi	a2,a2,-630 # ffffffffc0201dc0 <etext+0x8b8>
ffffffffc020103e:	06400593          	li	a1,100
ffffffffc0201042:	00001517          	auipc	a0,0x1
ffffffffc0201046:	d2650513          	addi	a0,a0,-730 # ffffffffc0201d68 <etext+0x860>
ffffffffc020104a:	97eff0ef          	jal	ffffffffc02001c8 <__panic>
        panic("DTB memory info not available");
ffffffffc020104e:	00001617          	auipc	a2,0x1
ffffffffc0201052:	cfa60613          	addi	a2,a2,-774 # ffffffffc0201d48 <etext+0x840>
ffffffffc0201056:	04c00593          	li	a1,76
ffffffffc020105a:	00001517          	auipc	a0,0x1
ffffffffc020105e:	d0e50513          	addi	a0,a0,-754 # ffffffffc0201d68 <etext+0x860>
ffffffffc0201062:	966ff0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201066:	86ae                	mv	a3,a1
ffffffffc0201068:	00001617          	auipc	a2,0x1
ffffffffc020106c:	d5860613          	addi	a2,a2,-680 # ffffffffc0201dc0 <etext+0x8b8>
ffffffffc0201070:	07f00593          	li	a1,127
ffffffffc0201074:	00001517          	auipc	a0,0x1
ffffffffc0201078:	cf450513          	addi	a0,a0,-780 # ffffffffc0201d68 <etext+0x860>
ffffffffc020107c:	94cff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0201080 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201080:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201082:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201086:	f022                	sd	s0,32(sp)
ffffffffc0201088:	ec26                	sd	s1,24(sp)
ffffffffc020108a:	e84a                	sd	s2,16(sp)
ffffffffc020108c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020108e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201092:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201094:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201098:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020109c:	84aa                	mv	s1,a0
ffffffffc020109e:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02010a0:	03067d63          	bgeu	a2,a6,ffffffffc02010da <printnum+0x5a>
ffffffffc02010a4:	e44e                	sd	s3,8(sp)
ffffffffc02010a6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02010a8:	4785                	li	a5,1
ffffffffc02010aa:	00e7d763          	bge	a5,a4,ffffffffc02010b8 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02010ae:	85ca                	mv	a1,s2
ffffffffc02010b0:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02010b2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02010b4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02010b6:	fc65                	bnez	s0,ffffffffc02010ae <printnum+0x2e>
ffffffffc02010b8:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010ba:	00001797          	auipc	a5,0x1
ffffffffc02010be:	dbe78793          	addi	a5,a5,-578 # ffffffffc0201e78 <etext+0x970>
ffffffffc02010c2:	97d2                	add	a5,a5,s4
}
ffffffffc02010c4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010c6:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02010ca:	70a2                	ld	ra,40(sp)
ffffffffc02010cc:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010ce:	85ca                	mv	a1,s2
ffffffffc02010d0:	87a6                	mv	a5,s1
}
ffffffffc02010d2:	6942                	ld	s2,16(sp)
ffffffffc02010d4:	64e2                	ld	s1,24(sp)
ffffffffc02010d6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010d8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02010da:	03065633          	divu	a2,a2,a6
ffffffffc02010de:	8722                	mv	a4,s0
ffffffffc02010e0:	fa1ff0ef          	jal	ffffffffc0201080 <printnum>
ffffffffc02010e4:	bfd9                	j	ffffffffc02010ba <printnum+0x3a>

ffffffffc02010e6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02010e6:	7119                	addi	sp,sp,-128
ffffffffc02010e8:	f4a6                	sd	s1,104(sp)
ffffffffc02010ea:	f0ca                	sd	s2,96(sp)
ffffffffc02010ec:	ecce                	sd	s3,88(sp)
ffffffffc02010ee:	e8d2                	sd	s4,80(sp)
ffffffffc02010f0:	e4d6                	sd	s5,72(sp)
ffffffffc02010f2:	e0da                	sd	s6,64(sp)
ffffffffc02010f4:	f862                	sd	s8,48(sp)
ffffffffc02010f6:	fc86                	sd	ra,120(sp)
ffffffffc02010f8:	f8a2                	sd	s0,112(sp)
ffffffffc02010fa:	fc5e                	sd	s7,56(sp)
ffffffffc02010fc:	f466                	sd	s9,40(sp)
ffffffffc02010fe:	f06a                	sd	s10,32(sp)
ffffffffc0201100:	ec6e                	sd	s11,24(sp)
ffffffffc0201102:	84aa                	mv	s1,a0
ffffffffc0201104:	8c32                	mv	s8,a2
ffffffffc0201106:	8a36                	mv	s4,a3
ffffffffc0201108:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020110a:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020110e:	05500b13          	li	s6,85
ffffffffc0201112:	00001a97          	auipc	s5,0x1
ffffffffc0201116:	e76a8a93          	addi	s5,s5,-394 # ffffffffc0201f88 <buddy_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020111a:	000c4503          	lbu	a0,0(s8)
ffffffffc020111e:	001c0413          	addi	s0,s8,1
ffffffffc0201122:	01350a63          	beq	a0,s3,ffffffffc0201136 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201126:	cd0d                	beqz	a0,ffffffffc0201160 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201128:	85ca                	mv	a1,s2
ffffffffc020112a:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020112c:	00044503          	lbu	a0,0(s0)
ffffffffc0201130:	0405                	addi	s0,s0,1
ffffffffc0201132:	ff351ae3          	bne	a0,s3,ffffffffc0201126 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201136:	5cfd                	li	s9,-1
ffffffffc0201138:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc020113a:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020113e:	4b81                	li	s7,0
ffffffffc0201140:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201142:	00044683          	lbu	a3,0(s0)
ffffffffc0201146:	00140c13          	addi	s8,s0,1
ffffffffc020114a:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020114e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201152:	02bb6663          	bltu	s6,a1,ffffffffc020117e <vprintfmt+0x98>
ffffffffc0201156:	058a                	slli	a1,a1,0x2
ffffffffc0201158:	95d6                	add	a1,a1,s5
ffffffffc020115a:	4198                	lw	a4,0(a1)
ffffffffc020115c:	9756                	add	a4,a4,s5
ffffffffc020115e:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201160:	70e6                	ld	ra,120(sp)
ffffffffc0201162:	7446                	ld	s0,112(sp)
ffffffffc0201164:	74a6                	ld	s1,104(sp)
ffffffffc0201166:	7906                	ld	s2,96(sp)
ffffffffc0201168:	69e6                	ld	s3,88(sp)
ffffffffc020116a:	6a46                	ld	s4,80(sp)
ffffffffc020116c:	6aa6                	ld	s5,72(sp)
ffffffffc020116e:	6b06                	ld	s6,64(sp)
ffffffffc0201170:	7be2                	ld	s7,56(sp)
ffffffffc0201172:	7c42                	ld	s8,48(sp)
ffffffffc0201174:	7ca2                	ld	s9,40(sp)
ffffffffc0201176:	7d02                	ld	s10,32(sp)
ffffffffc0201178:	6de2                	ld	s11,24(sp)
ffffffffc020117a:	6109                	addi	sp,sp,128
ffffffffc020117c:	8082                	ret
            putch('%', putdat);
ffffffffc020117e:	85ca                	mv	a1,s2
ffffffffc0201180:	02500513          	li	a0,37
ffffffffc0201184:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201186:	fff44783          	lbu	a5,-1(s0)
ffffffffc020118a:	02500713          	li	a4,37
ffffffffc020118e:	8c22                	mv	s8,s0
ffffffffc0201190:	f8e785e3          	beq	a5,a4,ffffffffc020111a <vprintfmt+0x34>
ffffffffc0201194:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201198:	1c7d                	addi	s8,s8,-1
ffffffffc020119a:	fee79de3          	bne	a5,a4,ffffffffc0201194 <vprintfmt+0xae>
ffffffffc020119e:	bfb5                	j	ffffffffc020111a <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02011a0:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02011a4:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02011a6:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02011aa:	fd06071b          	addiw	a4,a2,-48
ffffffffc02011ae:	24e56a63          	bltu	a0,a4,ffffffffc0201402 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc02011b2:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011b4:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc02011b6:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc02011ba:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02011be:	0197073b          	addw	a4,a4,s9
ffffffffc02011c2:	0017171b          	slliw	a4,a4,0x1
ffffffffc02011c6:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02011c8:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02011cc:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02011ce:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02011d2:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02011d6:	feb570e3          	bgeu	a0,a1,ffffffffc02011b6 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02011da:	f60d54e3          	bgez	s10,ffffffffc0201142 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02011de:	8d66                	mv	s10,s9
ffffffffc02011e0:	5cfd                	li	s9,-1
ffffffffc02011e2:	b785                	j	ffffffffc0201142 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011e4:	8db6                	mv	s11,a3
ffffffffc02011e6:	8462                	mv	s0,s8
ffffffffc02011e8:	bfa9                	j	ffffffffc0201142 <vprintfmt+0x5c>
ffffffffc02011ea:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02011ec:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02011ee:	bf91                	j	ffffffffc0201142 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02011f0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02011f2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02011f6:	00f74463          	blt	a4,a5,ffffffffc02011fe <vprintfmt+0x118>
    else if (lflag) {
ffffffffc02011fa:	1a078763          	beqz	a5,ffffffffc02013a8 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc02011fe:	000a3603          	ld	a2,0(s4)
ffffffffc0201202:	46c1                	li	a3,16
ffffffffc0201204:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201206:	000d879b          	sext.w	a5,s11
ffffffffc020120a:	876a                	mv	a4,s10
ffffffffc020120c:	85ca                	mv	a1,s2
ffffffffc020120e:	8526                	mv	a0,s1
ffffffffc0201210:	e71ff0ef          	jal	ffffffffc0201080 <printnum>
            break;
ffffffffc0201214:	b719                	j	ffffffffc020111a <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201216:	000a2503          	lw	a0,0(s4)
ffffffffc020121a:	85ca                	mv	a1,s2
ffffffffc020121c:	0a21                	addi	s4,s4,8
ffffffffc020121e:	9482                	jalr	s1
            break;
ffffffffc0201220:	bded                	j	ffffffffc020111a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201222:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201224:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201228:	00f74463          	blt	a4,a5,ffffffffc0201230 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020122c:	16078963          	beqz	a5,ffffffffc020139e <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0201230:	000a3603          	ld	a2,0(s4)
ffffffffc0201234:	46a9                	li	a3,10
ffffffffc0201236:	8a2e                	mv	s4,a1
ffffffffc0201238:	b7f9                	j	ffffffffc0201206 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc020123a:	85ca                	mv	a1,s2
ffffffffc020123c:	03000513          	li	a0,48
ffffffffc0201240:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201242:	85ca                	mv	a1,s2
ffffffffc0201244:	07800513          	li	a0,120
ffffffffc0201248:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020124a:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020124e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201250:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201252:	bf55                	j	ffffffffc0201206 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201254:	85ca                	mv	a1,s2
ffffffffc0201256:	02500513          	li	a0,37
ffffffffc020125a:	9482                	jalr	s1
            break;
ffffffffc020125c:	bd7d                	j	ffffffffc020111a <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020125e:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201262:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201264:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201266:	bf95                	j	ffffffffc02011da <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201268:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020126a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020126e:	00f74463          	blt	a4,a5,ffffffffc0201276 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201272:	12078163          	beqz	a5,ffffffffc0201394 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0201276:	000a3603          	ld	a2,0(s4)
ffffffffc020127a:	46a1                	li	a3,8
ffffffffc020127c:	8a2e                	mv	s4,a1
ffffffffc020127e:	b761                	j	ffffffffc0201206 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0201280:	876a                	mv	a4,s10
ffffffffc0201282:	000d5363          	bgez	s10,ffffffffc0201288 <vprintfmt+0x1a2>
ffffffffc0201286:	4701                	li	a4,0
ffffffffc0201288:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020128c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020128e:	bd55                	j	ffffffffc0201142 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0201290:	000d841b          	sext.w	s0,s11
ffffffffc0201294:	fd340793          	addi	a5,s0,-45
ffffffffc0201298:	00f037b3          	snez	a5,a5
ffffffffc020129c:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02012a0:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02012a4:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02012a6:	008a0793          	addi	a5,s4,8
ffffffffc02012aa:	e43e                	sd	a5,8(sp)
ffffffffc02012ac:	100d8c63          	beqz	s11,ffffffffc02013c4 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02012b0:	12071363          	bnez	a4,ffffffffc02013d6 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012b4:	000dc783          	lbu	a5,0(s11)
ffffffffc02012b8:	0007851b          	sext.w	a0,a5
ffffffffc02012bc:	c78d                	beqz	a5,ffffffffc02012e6 <vprintfmt+0x200>
ffffffffc02012be:	0d85                	addi	s11,s11,1
ffffffffc02012c0:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012c2:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012c6:	000cc563          	bltz	s9,ffffffffc02012d0 <vprintfmt+0x1ea>
ffffffffc02012ca:	3cfd                	addiw	s9,s9,-1
ffffffffc02012cc:	008c8d63          	beq	s9,s0,ffffffffc02012e6 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012d0:	020b9663          	bnez	s7,ffffffffc02012fc <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02012d4:	85ca                	mv	a1,s2
ffffffffc02012d6:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012d8:	000dc783          	lbu	a5,0(s11)
ffffffffc02012dc:	0d85                	addi	s11,s11,1
ffffffffc02012de:	3d7d                	addiw	s10,s10,-1
ffffffffc02012e0:	0007851b          	sext.w	a0,a5
ffffffffc02012e4:	f3ed                	bnez	a5,ffffffffc02012c6 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02012e6:	01a05963          	blez	s10,ffffffffc02012f8 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc02012ea:	85ca                	mv	a1,s2
ffffffffc02012ec:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02012f0:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc02012f2:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc02012f4:	fe0d1be3          	bnez	s10,ffffffffc02012ea <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02012f8:	6a22                	ld	s4,8(sp)
ffffffffc02012fa:	b505                	j	ffffffffc020111a <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012fc:	3781                	addiw	a5,a5,-32
ffffffffc02012fe:	fcfa7be3          	bgeu	s4,a5,ffffffffc02012d4 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201302:	03f00513          	li	a0,63
ffffffffc0201306:	85ca                	mv	a1,s2
ffffffffc0201308:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020130a:	000dc783          	lbu	a5,0(s11)
ffffffffc020130e:	0d85                	addi	s11,s11,1
ffffffffc0201310:	3d7d                	addiw	s10,s10,-1
ffffffffc0201312:	0007851b          	sext.w	a0,a5
ffffffffc0201316:	dbe1                	beqz	a5,ffffffffc02012e6 <vprintfmt+0x200>
ffffffffc0201318:	fa0cd9e3          	bgez	s9,ffffffffc02012ca <vprintfmt+0x1e4>
ffffffffc020131c:	b7c5                	j	ffffffffc02012fc <vprintfmt+0x216>
            if (err < 0) {
ffffffffc020131e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201322:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201324:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201326:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc020132a:	8fb9                	xor	a5,a5,a4
ffffffffc020132c:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201330:	02d64563          	blt	a2,a3,ffffffffc020135a <vprintfmt+0x274>
ffffffffc0201334:	00001797          	auipc	a5,0x1
ffffffffc0201338:	dac78793          	addi	a5,a5,-596 # ffffffffc02020e0 <error_string>
ffffffffc020133c:	00369713          	slli	a4,a3,0x3
ffffffffc0201340:	97ba                	add	a5,a5,a4
ffffffffc0201342:	639c                	ld	a5,0(a5)
ffffffffc0201344:	cb99                	beqz	a5,ffffffffc020135a <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201346:	86be                	mv	a3,a5
ffffffffc0201348:	00001617          	auipc	a2,0x1
ffffffffc020134c:	b6060613          	addi	a2,a2,-1184 # ffffffffc0201ea8 <etext+0x9a0>
ffffffffc0201350:	85ca                	mv	a1,s2
ffffffffc0201352:	8526                	mv	a0,s1
ffffffffc0201354:	0d8000ef          	jal	ffffffffc020142c <printfmt>
ffffffffc0201358:	b3c9                	j	ffffffffc020111a <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020135a:	00001617          	auipc	a2,0x1
ffffffffc020135e:	b3e60613          	addi	a2,a2,-1218 # ffffffffc0201e98 <etext+0x990>
ffffffffc0201362:	85ca                	mv	a1,s2
ffffffffc0201364:	8526                	mv	a0,s1
ffffffffc0201366:	0c6000ef          	jal	ffffffffc020142c <printfmt>
ffffffffc020136a:	bb45                	j	ffffffffc020111a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020136c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020136e:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201372:	00f74363          	blt	a4,a5,ffffffffc0201378 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0201376:	cf81                	beqz	a5,ffffffffc020138e <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0201378:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020137c:	02044b63          	bltz	s0,ffffffffc02013b2 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201380:	8622                	mv	a2,s0
ffffffffc0201382:	8a5e                	mv	s4,s7
ffffffffc0201384:	46a9                	li	a3,10
ffffffffc0201386:	b541                	j	ffffffffc0201206 <vprintfmt+0x120>
            lflag ++;
ffffffffc0201388:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020138a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020138c:	bb5d                	j	ffffffffc0201142 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020138e:	000a2403          	lw	s0,0(s4)
ffffffffc0201392:	b7ed                	j	ffffffffc020137c <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0201394:	000a6603          	lwu	a2,0(s4)
ffffffffc0201398:	46a1                	li	a3,8
ffffffffc020139a:	8a2e                	mv	s4,a1
ffffffffc020139c:	b5ad                	j	ffffffffc0201206 <vprintfmt+0x120>
ffffffffc020139e:	000a6603          	lwu	a2,0(s4)
ffffffffc02013a2:	46a9                	li	a3,10
ffffffffc02013a4:	8a2e                	mv	s4,a1
ffffffffc02013a6:	b585                	j	ffffffffc0201206 <vprintfmt+0x120>
ffffffffc02013a8:	000a6603          	lwu	a2,0(s4)
ffffffffc02013ac:	46c1                	li	a3,16
ffffffffc02013ae:	8a2e                	mv	s4,a1
ffffffffc02013b0:	bd99                	j	ffffffffc0201206 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc02013b2:	85ca                	mv	a1,s2
ffffffffc02013b4:	02d00513          	li	a0,45
ffffffffc02013b8:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc02013ba:	40800633          	neg	a2,s0
ffffffffc02013be:	8a5e                	mv	s4,s7
ffffffffc02013c0:	46a9                	li	a3,10
ffffffffc02013c2:	b591                	j	ffffffffc0201206 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02013c4:	e329                	bnez	a4,ffffffffc0201406 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013c6:	02800793          	li	a5,40
ffffffffc02013ca:	853e                	mv	a0,a5
ffffffffc02013cc:	00001d97          	auipc	s11,0x1
ffffffffc02013d0:	ac5d8d93          	addi	s11,s11,-1339 # ffffffffc0201e91 <etext+0x989>
ffffffffc02013d4:	b5f5                	j	ffffffffc02012c0 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02013d6:	85e6                	mv	a1,s9
ffffffffc02013d8:	856e                	mv	a0,s11
ffffffffc02013da:	0a4000ef          	jal	ffffffffc020147e <strnlen>
ffffffffc02013de:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02013e2:	01a05863          	blez	s10,ffffffffc02013f2 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02013e6:	85ca                	mv	a1,s2
ffffffffc02013e8:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02013ea:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02013ec:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02013ee:	fe0d1ce3          	bnez	s10,ffffffffc02013e6 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013f2:	000dc783          	lbu	a5,0(s11)
ffffffffc02013f6:	0007851b          	sext.w	a0,a5
ffffffffc02013fa:	ec0792e3          	bnez	a5,ffffffffc02012be <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013fe:	6a22                	ld	s4,8(sp)
ffffffffc0201400:	bb29                	j	ffffffffc020111a <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201402:	8462                	mv	s0,s8
ffffffffc0201404:	bbd9                	j	ffffffffc02011da <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201406:	85e6                	mv	a1,s9
ffffffffc0201408:	00001517          	auipc	a0,0x1
ffffffffc020140c:	a8850513          	addi	a0,a0,-1400 # ffffffffc0201e90 <etext+0x988>
ffffffffc0201410:	06e000ef          	jal	ffffffffc020147e <strnlen>
ffffffffc0201414:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201418:	02800793          	li	a5,40
                p = "(null)";
ffffffffc020141c:	00001d97          	auipc	s11,0x1
ffffffffc0201420:	a74d8d93          	addi	s11,s11,-1420 # ffffffffc0201e90 <etext+0x988>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201424:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201426:	fda040e3          	bgtz	s10,ffffffffc02013e6 <vprintfmt+0x300>
ffffffffc020142a:	bd51                	j	ffffffffc02012be <vprintfmt+0x1d8>

ffffffffc020142c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020142c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020142e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201432:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201434:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201436:	ec06                	sd	ra,24(sp)
ffffffffc0201438:	f83a                	sd	a4,48(sp)
ffffffffc020143a:	fc3e                	sd	a5,56(sp)
ffffffffc020143c:	e0c2                	sd	a6,64(sp)
ffffffffc020143e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201440:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201442:	ca5ff0ef          	jal	ffffffffc02010e6 <vprintfmt>
}
ffffffffc0201446:	60e2                	ld	ra,24(sp)
ffffffffc0201448:	6161                	addi	sp,sp,80
ffffffffc020144a:	8082                	ret

ffffffffc020144c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020144c:	00005717          	auipc	a4,0x5
ffffffffc0201450:	bc473703          	ld	a4,-1084(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201454:	4781                	li	a5,0
ffffffffc0201456:	88ba                	mv	a7,a4
ffffffffc0201458:	852a                	mv	a0,a0
ffffffffc020145a:	85be                	mv	a1,a5
ffffffffc020145c:	863e                	mv	a2,a5
ffffffffc020145e:	00000073          	ecall
ffffffffc0201462:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201464:	8082                	ret

ffffffffc0201466 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201466:	00054783          	lbu	a5,0(a0)
ffffffffc020146a:	cb81                	beqz	a5,ffffffffc020147a <strlen+0x14>
    size_t cnt = 0;
ffffffffc020146c:	4781                	li	a5,0
        cnt ++;
ffffffffc020146e:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201470:	00f50733          	add	a4,a0,a5
ffffffffc0201474:	00074703          	lbu	a4,0(a4)
ffffffffc0201478:	fb7d                	bnez	a4,ffffffffc020146e <strlen+0x8>
    }
    return cnt;
}
ffffffffc020147a:	853e                	mv	a0,a5
ffffffffc020147c:	8082                	ret

ffffffffc020147e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020147e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201480:	e589                	bnez	a1,ffffffffc020148a <strnlen+0xc>
ffffffffc0201482:	a811                	j	ffffffffc0201496 <strnlen+0x18>
        cnt ++;
ffffffffc0201484:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201486:	00f58863          	beq	a1,a5,ffffffffc0201496 <strnlen+0x18>
ffffffffc020148a:	00f50733          	add	a4,a0,a5
ffffffffc020148e:	00074703          	lbu	a4,0(a4)
ffffffffc0201492:	fb6d                	bnez	a4,ffffffffc0201484 <strnlen+0x6>
ffffffffc0201494:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201496:	852e                	mv	a0,a1
ffffffffc0201498:	8082                	ret

ffffffffc020149a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020149a:	00054783          	lbu	a5,0(a0)
ffffffffc020149e:	e791                	bnez	a5,ffffffffc02014aa <strcmp+0x10>
ffffffffc02014a0:	a01d                	j	ffffffffc02014c6 <strcmp+0x2c>
ffffffffc02014a2:	00054783          	lbu	a5,0(a0)
ffffffffc02014a6:	cb99                	beqz	a5,ffffffffc02014bc <strcmp+0x22>
ffffffffc02014a8:	0585                	addi	a1,a1,1
ffffffffc02014aa:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02014ae:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02014b0:	fef709e3          	beq	a4,a5,ffffffffc02014a2 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014b4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02014b8:	9d19                	subw	a0,a0,a4
ffffffffc02014ba:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014bc:	0015c703          	lbu	a4,1(a1)
ffffffffc02014c0:	4501                	li	a0,0
}
ffffffffc02014c2:	9d19                	subw	a0,a0,a4
ffffffffc02014c4:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014c6:	0005c703          	lbu	a4,0(a1)
ffffffffc02014ca:	4501                	li	a0,0
ffffffffc02014cc:	b7f5                	j	ffffffffc02014b8 <strcmp+0x1e>

ffffffffc02014ce <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014ce:	ce01                	beqz	a2,ffffffffc02014e6 <strncmp+0x18>
ffffffffc02014d0:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02014d4:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014d6:	cb91                	beqz	a5,ffffffffc02014ea <strncmp+0x1c>
ffffffffc02014d8:	0005c703          	lbu	a4,0(a1)
ffffffffc02014dc:	00f71763          	bne	a4,a5,ffffffffc02014ea <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02014e0:	0505                	addi	a0,a0,1
ffffffffc02014e2:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014e4:	f675                	bnez	a2,ffffffffc02014d0 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014e6:	4501                	li	a0,0
ffffffffc02014e8:	8082                	ret
ffffffffc02014ea:	00054503          	lbu	a0,0(a0)
ffffffffc02014ee:	0005c783          	lbu	a5,0(a1)
ffffffffc02014f2:	9d1d                	subw	a0,a0,a5
}
ffffffffc02014f4:	8082                	ret

ffffffffc02014f6 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02014f6:	ca01                	beqz	a2,ffffffffc0201506 <memset+0x10>
ffffffffc02014f8:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02014fa:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02014fc:	0785                	addi	a5,a5,1
ffffffffc02014fe:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201502:	fef61de3          	bne	a2,a5,ffffffffc02014fc <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201506:	8082                	ret
