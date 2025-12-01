CC = gcc
ASMFLAGS = -no-pie -Wall -nostartfiles

SRC = part1.s part2.s

OUT = $(SRC:.s=)

all: $(OUT)

%: %.s
	$(CC) $(ASMFLAGS) $< -o $@

clean:
	rm -f $(OUT)
