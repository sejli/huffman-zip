# Huffman Zip
hzip.st is a file compression and decompression utility written in Smalltalk using Huffman coding.
# Options
**-d** : Debug information is printed for the benefit of the application author
**-t** : The compression algorithm is activated, and the decoding tree is printed
         to the standard output. The output filename may not be specified.
**-c** : The input file is compressed and written to the output file, if specified, or
         to the standard output, if not.
**-u** : The input file is assumed to be compressed, and is uncompressed, written
         to the output file, if specified, or to the standard output, if not.