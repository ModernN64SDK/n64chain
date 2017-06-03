//
// libn64/os/thread.c: OS thread functions.
//
// n64chain: A (free) open-source N64 development toolchain.
// Copyright 2014-16 Tyler J. Stachecki <stachecki.tyler@gmail.com>
//
// This file is subject to the terms and conditions defined in
// 'LICENSE', which is part of this source code package.
//

#include <libn64.h>
#include <os/thread.h>
#include <os/thread_table.h>

// Initialize the thread table.
void libn64_thread_early_init(uint32_t kernel_sp) {
  struct libn64_thread *self;
  unsigned i;

  // Determine the address of the thread table and thread block.
  struct libn64_thread_table *thread_table =
    (struct libn64_thread_table *) kernel_sp;

  struct libn64_thread *thread_block =
    (struct libn64_thread *) (kernel_sp + LIBN64_THREADS_MAX * 0x10);

  __asm__(
    ".set noat\n\t"
    "lui $at, 0x8000\n\t"
    "sw %0, 0x424($at)\n\t"
    :: "r"(thread_block)
  );

  // Initialize the thread stack.
  for (i = 0; i < LIBN64_THREADS_MAX; i++)
    thread_table->free_list[i] = thread_block + i;

  thread_table->free_threads = LIBN64_THREADS_MAX - 1;

  // Initialize the ready thread queue and initial thread.
  self = thread_block + thread_table->free_threads;
  thread_table->ready_queue.count = 1;

  thread_table->ready_queue.heap[0].priority = LIBN64_THREAD_MIN_PRIORITY;
  thread_table->ready_queue.heap[0].thread = self;
  self->priority = LIBN64_THREAD_MIN_PRIORITY;
}

