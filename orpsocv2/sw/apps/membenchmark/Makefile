BOARD ?=ml509_25
# Commands
CC = or32-elf-gcc
#CC = gcc
CPP = or32-elf-g++
OBJCOPY = or32-elf-objcopy
OBJDUMP = or32-elf-objdump
REMOVE = rm -rf
# Compiler flags
CFLAGS = -c -Wall -std=c99 -o2 -I../../drivers/counter/include
VPATH = ../../drivers/counter
# Linker flags
LDFLAGS = -mnewlib -mboard=$(BOARD)

# Sources
TARGET = main.c
SRC = $(TARGET)

# Output filename
OUT = membench

# Object defines
COBJ = $(SRC:.c=.o) counter.o

all: $(SRC) $(OUT) $(OUT).bin

$(OUT).bin: $(OUT)
	$(OBJCOPY) -O binary $< $@

$(OUT): $(COBJ)
	$(CC) $(LDFLAGS) $(COBJ) -o $@

$(COBJ) : %.o : %.c
	$(CC) $(CFLAGS) $< -o $@

clean: 
	$(REMOVE) $(COBJ) $(OUT) $(OUT).bin
