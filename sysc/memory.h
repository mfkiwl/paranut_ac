/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2015 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This file defines the class 'CMemory', which simulates a memory
    environment for the testbench of ParaNut.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

 *************************************************************************/


#ifndef _MEMORY_
#define _MEMORY_

#include "base.h"
#include "config.h"

#define LABEL_LEN 80


extern class CMemory *mainMemory;


class CLabel {
public:
  void Set (TWord _adr, char *_name);

  TWord adr;
  char name[LABEL_LEN+1];
};


class CMemory {
public:
  CMemory () { Init (0, MEM_SIZE); }
  CMemory (TWord _base, TWord _size) { Init (_base, _size); }

  void Init (TWord _base, TWord _size);

  bool IsAdressed (TWord adr) { return adr >= base && adr <= base + size; }

  // Read & Write...
  TByte ReadByte (TWord adr) { return data[adr-base]; }
#if PN_BIG_ENDIAN == 1
  THalfWord ReadHalfWord (TWord adr) {
    return ((THalfWord) data[adr-base] << 8) + data[adr-base+1];
  }
  TWord ReadWord (TWord adr) {
    return ((TWord) data[adr-base] << 24) + ((TWord) data[adr-base+1] << 16)
      + ((TWord) data[adr-base+2] << 8) + ((TWord) data[adr-base+3]) ;
  }
#else
  THalfWord ReadHalfWord (TWord adr) { return ((TWord *) (&data[adr-base])) & 0xffff; }
  TWord ReadWord (TWord adr) { return (TWord *) (&data[adr-base]); }
#endif

  void WriteByte (TWord adr, TByte val) { data[adr-base] = val; }
#if PN_BIG_ENDIAN == 1
  void WriteHalfWord (TWord adr, THalfWord val) {
    data[adr-base] = (TByte) (val >> 8);
    data[adr-base+1] = (TByte) val;
  }
  void WriteWord (TWord adr, TWord val) {
    data[adr-base] = (TByte) (val >> 24);
    data[adr-base+1] = (TByte) (val >> 16);
    data[adr-base+2] = (TByte) (val >> 8);
    data[adr-base+3] = (TByte) val;
  }
#else
#error "Little Endian not implemented"
#endif

  // Read ELF...
  bool ReadFile (char *fileName, bool dumpVHDL);

  // Labels...
  CLabel *FindLabel (TWord adr);

  // Dumping...
  char *GetDumpStr (TWord adr);
  char *GetDumpStrVHDL (TWord adr);
  void Dump (TWord adr0 = 0, TWord adr1 = 0xffffffff);
  void DumpVHDL (char *filename, unsigned size);

protected:
  TByte *data;
  int base, size;

  CLabel *labelList;
  int labels;
};



#endif
