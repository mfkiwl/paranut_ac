# change this to the correct location of your OR32 toolchain installation
OR32_ELF_FOLDER=/opt/openrisc

all: install_libboard install_crt0

install_libboard: ml509_25.a ml509_33.a ml509_50.a ml509_66.a
	mkdir -p ${OR32_ELF_FOLDER}/or32-elf/lib/boards/ml509_25
	mkdir -p ${OR32_ELF_FOLDER}/or32-elf/lib/boards/ml509_33
	mkdir -p ${OR32_ELF_FOLDER}/or32-elf/lib/boards/ml509_50
	mkdir -p ${OR32_ELF_FOLDER}/or32-elf/lib/boards/ml509_66
	cp ml509_25.a ${OR32_ELF_FOLDER}/or32-elf/lib/boards/ml509_25/libboard.a
	cp ml509_33.a ${OR32_ELF_FOLDER}/or32-elf/lib/boards/ml509_33/libboard.a
	cp ml509_50.a ${OR32_ELF_FOLDER}/or32-elf/lib/boards/ml509_50/libboard.a
	cp ml509_66.a ${OR32_ELF_FOLDER}/or32-elf/lib/boards/ml509_66/libboard.a

install_crt0: crt0.o
	cp $< ${OR32_ELF_FOLDER}/or32-elf/lib/

ml509_%.o: ml509_%.S
	or32-elf-as -o $@ $<

ml509_%.a: ml509_%.o
	or32-elf-ar -q $@ $<

crt0.o: crt0.S
	or32-elf-gcc -nostartfiles -c -o $@ $<

clean:
	rm *.a *.o

