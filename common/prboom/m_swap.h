/* Emacs style mode select   -*- C++ -*-
 *-----------------------------------------------------------------------------
 *
 *
 *  PrBoom: a Doom port merged with LxDoom and LSDLDoom
 *  based on BOOM, a modified and improved DOOM engine
 *  Copyright (C) 1999 by
 *  id Software, Chi Hoang, Lee Killough, Jim Flynn, Rand Phares, Ty Halderman
 *  Copyright (C) 1999-2000 by
 *  Jess Haas, Nicolas Kalkhof, Colin Phipps, Florian Schulze
 *  Copyright 2005, 2006 by
 *  Florian Schulze, Colin Phipps, Neil Stevens, Andrey Budko
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 *  02111-1307, USA.
 *
 * DESCRIPTION:
 *      Endianess handling, swapping 16bit and 32bit.
 *
 *-----------------------------------------------------------------------------*/


#ifndef __M_SWAP__
#define __M_SWAP__


/* CPhipps - now the endianness handling, converting input or output to/from 
 * the machine's endianness to that wanted for this type of I/O
 *
 * To find our own endianness, use config.h
 */

#include <stdint.h>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

/* Endianess handling. */

/* cph - First the macros to do the actual byte swapping */

/* leban
 * rather than continue the confusing tradition of redefining the
 * stardard macro, we now present the doom_ntoh and doom_hton macros....
 * might as well use the xdoom macros.
 */

/* Try to use superfast macros on systems that support them */
#ifdef HAVE_ASM_BYTEORDER_H
#include <asm/byteorder.h>
#ifdef __arch__swab16
#define doom_swap_int16  (int16_t)__arch__swab16
#endif
#ifdef __arch__swab32
#define doom_swap_int32  (int32_t)__arch__swab32
#endif
#endif /* HAVE_ASM_BYTEORDER_H */

#ifdef HAVE_LIBKERN_OSBYTEORDER_H
#include <libkern/OSByteOrder.h>

#define doom_swap_int16 (int16_t)OSSwapInt16
#define doom_swap_int32 (int32_t)OSSwapInt32
#endif

#ifndef doom_swap_int32
#define doom_swap_int32(x) \
        ((int32_t)((((unsigned long int)(x) & 0x000000ffU) << 24) | \
                             (((unsigned long int)(x) & 0x0000ff00U) <<  8) | \
                             (((unsigned long int)(x) & 0x00ff0000U) >>  8) | \
                             (((unsigned long int)(x) & 0xff000000U) >> 24)))
#endif

#ifndef doom_swap_int16
#define doom_swap_int16(x) \
        ((short int)((((unsigned short int)(x) & 0x00ff) << 8) | \
                              (((unsigned short int)(x) & 0xff00) >> 8))) 
#endif

/* Macros are named doom_XtoYT, where 
 * X is thing to convert from, Y is thing to convert to, chosen from 
 * n for network, h for host (i.e our machine's), w for WAD (Doom data files)
 * and T is the type, l or s for long or short
 *
 * CPhipps - all WADs and network packets will be little endian for now
 * Use separate macros so network could be converted to big-endian later.
 */

#ifdef WORDS_BIGENDIAN

#define doom_wtoh_int32(x) doom_swap_int32(x)
#define doom_htow_int32(x) doom_swap_int32(x)
#define doom_wtoh_int16(x) doom_swap_int16(x)
#define doom_htow_int16(x) doom_swap_int16(x)

#define doom_ntoh_int32(x) doom_swap_int32(x)
#define doom_hton_int32(x) doom_swap_int32(x)
#define doom_ntoh_int16(x) doom_swap_int16(x)
#define doom_hton_int16(x) doom_swap_int16(x)

#else

#define doom_wtoh_int32(x) (int32_t)(x)
#define doom_htow_int32(x) (int32_t)(x)
#define doom_wtoh_int16(x) (int16_t)(x)
#define doom_htow_int16(x) (int16_t)(x)

#define doom_ntoh_int32(x) (int32_t)(x)
#define doom_hton_int32(x) (int32_t)(x)
#define doom_ntoh_int16(x) (int16_t)(x)
#define doom_hton_int16(x) (int16_t)(x)

#endif

/* CPhipps - Boom's old LONG and SHORT endianness macros are for WAD stuff */

#define INT32(x) doom_wtoh_int32(x)
#define INT16(x) doom_htow_int16(x)

#endif
