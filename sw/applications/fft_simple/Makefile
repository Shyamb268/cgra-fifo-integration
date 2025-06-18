CC = gcc
CFLAGS = -Wall -Wextra
LDFLAGS = -lm

SRCS = main.c vcd_writer.c
OBJS = $(SRCS:.c=.o)
TARGET = fft_simple

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET) $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all clean 