Medo.IO.Hashing
===============

This is a versatile hashing library using .NET 6 NonCryptographicHashAlgorithm
base.

It provides support for various CRC-8, CRC-16, CRC-32, and CRC-64 error
detection algorithms. These algorithms are widely used to detect errors in data
transmission and storage and are known for their high accuracy and reliability.

In addition to custom-defined CRC parameters, the following variants are
supported:
* CRC-8/AUTOSAR
* CRC-8/BLUETOOTH
* CRC-8/CCITT
* CRC-8/CDMA2000
* CRC-8/DALLAS
* CRC-8/DARC
* CRC-8/DVB-S2
* CRC-8/GSM-A
* CRC-8/GSM-B
* CRC-8/HITAG
* CRC-8/I-432-1
* CRC-8/I-CODE
* CRC-8/ITU
* CRC-8/LTE
* CRC-8/MAXIM
* CRC-8/MAXIM-DOW
* CRC-8/MIFARE
* CRC-8/MIFARE-MAD
* CRC-8/NRSC-5
* CRC-8/OpenSAFETY
* CRC-8/ROHC
* CRC-8/SAE-J1850
* CRC-8/SMBUS
* CRC-8/TECH-3250
* CRC-8/WCDMA2000
* CRC-16/ACORN
* CRC-16/ARC
* CRC-16/AUG-CCITT
* CRC-16/AUTOSAR
* CRC-16/BUYPASS
* CRC-16/CDMA2000
* CRC-16/CCITT
* CRC-16/CCITT-FALSE
* CRC-16/CCITT-TRUE
* CRC-16/CMS
* CRC-16/DARC
* CRC-16/DDS-110
* CRC-16/DECT-R
* CRC-16/DECT-X
* CRC-16/DNP
* CRC-16/EN-13757
* CRC-16/EPC
* CRC-16/EPC-C1G2
* CRC-16/GENIBUS
* CRC-16/GSM
* CRC-16/I-CODE
* CRC-16/IBM-3740
* CRC-16/ISO-HDLD
* CRC-16/IBM-SDLC
* CRC-16/IEC-61158-2
* CRC-16/IEEE 802.3
* CRC-16/ISO-IEC-14443-3-A
* CRC-16/ISO-IEC-14443-3-B
* CRC-16/KERMIT
* CRC-16/LHA
* CRC-16/LJ1200
* CRC-16/LTE
* CRC-16/MAXIM
* CRC-16/MAXIM-DOW
* CRC-16/MCRF4XX
* CRC-16/MODBUS
* CRC-16/NRSC-5
* CRC-16/OPENSAFETY-A
* CRC-16/OPENSAFETY-B
* CRC-16/PROFIBUS
* CRC-16/RIELLO
* CRC-16/SPI-FUJITSU
* CRC-16/T10-DIF
* CRC-16/TELEDISK
* CRC-16/TMS37157
* CRC-16/UMTS
* CRC-16/USB
* CRC-16/V-41-LSB
* CRC-16/V-41-MSB
* CRC-16/VERIFONE
* CRC-16/X-25
* CRC-16/XMODEM
* CRC-16/ZMODEM
* CRC-32/AAL5
* CRC-32/ADCCP
* CRC-32/AIXM
* CRC-32/AUTOSAR
* CRC-32/BASE91-C
* CRC-32/BASE91-D
* CRC-32/BZIP2
* CRC-32/CASTAGNOLI
* CRC-32/CD-ROM-EDC
* CRC-32/CKSUM
* CRC-32/DECT-B
* CRC-32/IEEE-802.3
* CRC-32/INTERLAKEN
* CRC-32/ISCSI
* CRC-32/ISO-HDLC
* CRC-32/JAMCRC
* CRC-32/MPEG-2
* CRC-32/PKZIP
* CRC-32/POSIX
* CRC-32/V-42
* CRC-32/XFER
* CRC-32/XZ
* CRC-64/ECMA-182
* CRC-64/GO-ECMA
* CRC-64/GO-ISO
* CRC-64/MS
* CRC-64/REDIS
* CRC-64/WE
* CRC-64/XZ

Furthermore, library supports Damm, Fletcher-16, and ISO 7064 checksum
algorithms.


You can find packaged library at [NuGet][nuget] and add it you your application
using the following command:

    dotnet add package Medo.IO.Hashing



[nuget]: https://www.nuget.org/packages/Medo.IO.Hashing
