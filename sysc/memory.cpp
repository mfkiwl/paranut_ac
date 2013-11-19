/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

 *************************************************************************/


#include "memory.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <string>

#include "or32-elf.h"



class CMemory *mainMemory = NULL;



// ********************* CLabel ***************************



void CLabel::Set (TWord _adr, char *_name) {
  adr = _adr;
  strncpy (name, _name, LABEL_LEN);
  name[LABEL_LEN] = '\0';
}





// ********************* CMemory **************************


void CMemory::Init (TWord _base, TWord _size) {
  base = _base;
  size = _size;
  data = new TByte [_size];
  memset (data, 0, _size);

  labelList = NULL;
  labels = 0;

  if (!mainMemory) mainMemory = this;
}



// ***** ELF file reading *****


#define PRINTF fprintf
#define PRIx32 "x"


bool CMemory::ReadFile  (char *filename, bool dumpVHDL) {
  FILE *inputfs;
  struct elf32_hdr elfhdr;
  struct elf32_phdr *elf_phdata = NULL;
  struct elf32_shdr *elf_spnt, *elf_shdata;
  struct elf32_sym *sym_tbl = (struct elf32_sym *) 0;
  unsigned syms = 0;
  char *str_tbl = (char *) 0;
  char *s_str = (char *) 0;
  int breakpoint = 0;
  unsigned inputbuf;
  unsigned padd;
  unsigned insn;
  int i, j, sectsize, len;
  TWord adr;

  //printf ("### sizeof (elfhdr) = %i\n", sizeof (elfhdr));

  if (labelList) {
    free (labelList);
    labels = 0;
  }

  if (!(inputfs = fopen (filename, "r")))
    return false;

  if (fread (&elfhdr, sizeof (elfhdr), 1, inputfs) != 1)
    return false;

  if ((elf_shdata =
       (struct elf32_shdr *) malloc (ELF_SHORT_H (elfhdr.e_shentsize) *
                                     ELF_SHORT_H (elfhdr.e_shnum))) == NULL)
    return false;

  if (fseek (inputfs, ELF_LONG_H (elfhdr.e_shoff), SEEK_SET) != 0)
    return false;

  // printf ("# elfhdr.e_shentsize = %i, elfhdr.e_shnum = %i\n", elfhdr.e_shentsize, elfhdr.e_shnum);
  if (fread (elf_shdata, ELF_SHORT_H (elfhdr.e_shentsize) * ELF_SHORT_H (elfhdr.e_shnum), 1, inputfs) != 1)
    return false;

  if (ELF_LONG_H (elfhdr.e_phoff)) {
    if ((elf_phdata =
         (struct elf32_phdr *) malloc (ELF_SHORT_H (elfhdr.e_phnum) *
                                       ELF_SHORT_H (elfhdr.e_phentsize))) == NULL)
      return false;

    if (fseek (inputfs, ELF_LONG_H (elfhdr.e_phoff), SEEK_SET) != 0)
      return false;

    if (fread (elf_phdata, ELF_SHORT_H (elfhdr.e_phnum) * ELF_SHORT_H (elfhdr.e_phentsize), 1, inputfs) != 1)
      return false;
  }

  for (i = 0, elf_spnt = elf_shdata; i < ELF_SHORT_H (elfhdr.e_shnum); i++, elf_spnt++) {
    if (ELF_LONG_H (elf_spnt->sh_type) == SHT_STRTAB) {
      if (NULL != str_tbl)
        free (str_tbl);

      if ((str_tbl = (char *) malloc (ELF_LONG_H (elf_spnt->sh_size))) == NULL)
        return false;

      if (fseek (inputfs, ELF_LONG_H (elf_spnt->sh_offset), SEEK_SET) != 0)
        return false;

      if (fread (str_tbl, ELF_LONG_H (elf_spnt->sh_size), 1, inputfs) != 1)
        return false;
    }
    else if (ELF_LONG_H (elf_spnt->sh_type) == SHT_SYMTAB) {
      if (NULL != sym_tbl)
        free (sym_tbl);

      if ((sym_tbl = (struct elf32_sym *) malloc (ELF_LONG_H (elf_spnt->sh_size))) == NULL)
        return false;

      if (fseek (inputfs, ELF_LONG_H (elf_spnt->sh_offset), SEEK_SET) != 0)
        return false;

      if (fread (sym_tbl, ELF_LONG_H (elf_spnt->sh_size), 1, inputfs) != 1)
        return false;

      syms =
        ELF_LONG_H (elf_spnt->sh_size) /
        ELF_LONG_H (elf_spnt->sh_entsize);
    }
  }

  if (ELF_SHORT_H (elfhdr.e_shstrndx) != SHN_UNDEF) {
    elf_spnt = &elf_shdata[ELF_SHORT_H (elfhdr.e_shstrndx)];

    if ((s_str = (char *) malloc (ELF_LONG_H (elf_spnt->sh_size))) == NULL)
      return false;

    if (fseek (inputfs, ELF_LONG_H (elf_spnt->sh_offset), SEEK_SET) != 0)
      return false;

    if (fread (s_str, ELF_LONG_H (elf_spnt->sh_size), 1, inputfs) != 1)
      return false;
  }

  for (i = 0, elf_spnt = elf_shdata; i < ELF_SHORT_H (elfhdr.e_shnum); i++, elf_spnt++) {
    if ((ELF_LONG_H (elf_spnt->sh_type) & SHT_PROGBITS)
        && (ELF_LONG_H (elf_spnt->sh_flags) & SHF_ALLOC)) {

      padd = ELF_LONG_H (elf_spnt->sh_addr);
      for (j = 0; j < ELF_SHORT_H (elfhdr.e_phnum); j++) {
        if (ELF_LONG_H (elf_phdata[j].p_offset) &&
            ELF_LONG_H (elf_phdata[j].p_offset) <=
            ELF_LONG_H (elf_spnt->sh_offset)
            && (ELF_LONG_H (elf_phdata[j].p_offset) +
                ELF_LONG_H (elf_phdata[j].p_memsz)) >
            ELF_LONG_H (elf_spnt->sh_offset))
          padd =
            ELF_LONG_H (elf_phdata[j].p_paddr) +
            ELF_LONG_H (elf_spnt->sh_offset) -
            ELF_LONG_H (elf_phdata[j].p_offset);
      }

      if (ELF_LONG_H (elf_spnt->sh_name) && s_str)
        PRINTF (stderr, "Section: %s,", &s_str[ELF_LONG_H (elf_spnt->sh_name)]);
      else
        PRINTF (stderr, "Section: noname,");
      PRINTF (stderr, " vaddr: 0x%.8lx,", ELF_LONG_H (elf_spnt->sh_addr));
      PRINTF (stderr, " paddr: 0x%" PRIx32, padd);
      PRINTF (stderr, " offset: 0x%.8lx,", ELF_LONG_H (elf_spnt->sh_offset));
      PRINTF (stderr, " size: 0x%.8lx\n", ELF_LONG_H (elf_spnt->sh_size));

      adr = padd;
      sectsize = ELF_LONG_H (elf_spnt->sh_size);

      if (fseek (inputfs, ELF_LONG_H (elf_spnt->sh_offset), SEEK_SET) != 0) {
        free (elf_phdata);
        return false;
      }

      while (sectsize > 0 && (len = fread (&inputbuf, sizeof (inputbuf), 1, inputfs))) {
        insn = ELF_LONG_H (inputbuf);
        WriteWord (adr, insn); // addprogram (freemem, insn, &breakpoint);
        // printf ("### Write (%08x, %08x)\n", freemem, insn);
        adr += 4;
        sectsize -= 4;
      }
    }
  }

  labelList = new CLabel [syms];
  labels = 0;

  if (str_tbl) {
    i = 0;
    while (syms--) {
      if (sym_tbl[i].st_name && sym_tbl[i].st_info && ELF_SHORT_H (sym_tbl[i].st_shndx) < 0x8000) {
        labelList[labels].Set (ELF_LONG_H (sym_tbl[i].st_value), &str_tbl[ELF_LONG_H (sym_tbl[i].st_name)]);
        labels++;
        // add_label (ELF_LONG_H (sym_tbl[i].st_value),
        //           &str_tbl[ELF_LONG_H (sym_tbl[i].st_name)]);
      }
      i++;
    }
  }

  if (dumpVHDL)
    DumpVHDL(filename, adr);

  if (NULL != str_tbl) free (str_tbl);
  if (NULL != sym_tbl) free (sym_tbl);
  free (s_str);
  free (elf_phdata);
  free (elf_shdata);

  return true;
}


void CMemory::DumpVHDL (char *filename, unsigned size) {
  TWord adr;
  FILE *outputfs;

  std::string fname = std::string(filename);
  std::string ofname(fname, fname.find_last_of('/')+1);
  if (!(outputfs = fopen ((ofname + "_mem_dump.vhd").c_str(), "w"))) {
    printf ("\nError: Unable to open file '%s_mem_dump.vhd' for writing.\n", ofname.c_str());
    return;
  }

  size += 4;
  PRINTF (outputfs, "library ieee;\n");
  PRINTF (outputfs, "use ieee.std_logic_1164.all;\n\n");
  PRINTF (outputfs, "library paranut;\n");
  PRINTF (outputfs, "use paranut.types.all;\n\n");
  PRINTF (outputfs, "package prog_mem is\n\n");
  PRINTF (outputfs, "\tconstant PROG_SIZE : integer := %u;\n\n", size);
  PRINTF (outputfs, "\tconstant PROG_DATA : mem_type(0 to PROG_SIZE/4-1) := (\n");
  for (adr = base; adr < base + size; adr += 4) {
    PRINTF (outputfs, "\t\t%s\n", GetDumpStrVHDL (adr));
  }
  PRINTF (outputfs, "\t\tothers => X\"00000000\"\n");
  PRINTF (outputfs, "\t);\n\n");
  PRINTF (outputfs, "end package;");

  fclose(outputfs);
  printf ("\nDumped program memory content to '%s_mem_dump.vhd'\n", ofname.c_str());
}


// ***** Labels *****


CLabel *CMemory::FindLabel (TWord adr) {
  int n;

  for (n = 0; n < labels; n++)
    if (labelList[n].adr == adr) return &labelList[n];
  return NULL;
}



// ***** Dump *****


static char Printable (TByte byte) {
  return isprint(byte) ? byte : '.';
}


char *CMemory::GetDumpStr (TWord adr) {
  static char ret[200];

  CLabel *label;
  TByte *bytes;
  bytes = &data[adr-base];
  label = FindLabel (adr);
  sprintf (ret, "%-20s %08x: %02x %02x %02x %02x   %c%c%c%c   %s",
           label ? label->name : "",
           adr,
           bytes[0], bytes[1], bytes[2], bytes[3],
           Printable (bytes[0]), Printable (bytes[1]), Printable (bytes[2]), Printable (bytes[3]),
           DisAss (ReadWord (adr)));
  return ret;
}

char *CMemory::GetDumpStrVHDL (TWord adr) {
  static char ret[200];

  TByte *bytes;
  bytes = &data[adr-base];
  sprintf (ret, "16#%04x# => X\"%02x%02x%02x%02x\",",
           adr/4,
           bytes[0], bytes[1], bytes[2], bytes[3]
           );
  return ret;
}

void CMemory::Dump (TWord adr0, TWord adr1) {
  TWord val, lastVal, adr, i;
  bool printPeriod;

  /*
  for (int n = 0; n < labels; n++) {
    label = &labelList[n];
    printf ("%-16s = %08x\n", label->name, label->adr);
  }
  */

  lastVal = 0;
  printPeriod = false;
  for (adr = MAX (base, adr0); adr < MIN (base + size, adr1); adr += 4) {
    val = ReadWord (adr);
    if (val != lastVal /*/ val != 0 */) {
      if (printPeriod) printf ("%21s...\n", "");
      printf ("%s\n", GetDumpStr (adr));
      printPeriod = false;
      }
    else
      printPeriod = true;
    lastVal = val;
  }
  if (printPeriod) printf ("%21s...\n", "");
}
