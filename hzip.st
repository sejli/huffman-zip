#!/afs/cats.ucsc.edu/courses/cse112-wm/usr/smalltalk/bin/gst -f
"$Id: hzip.st,v 1.4 2020-02-18 17:05:02-08 - - $"
execname := '$RCSfile: hzip.st,v $' =~ '.*: (.*),v.*' at: 1.

Character extend [
   isGraph [
      ^ (Character space < self) & (self <= $~)
   ]
   visible [
      self isGraph ifTrue: [^ '$', self asString]
                   ifFalse: [^ self asInteger printStringRadix: 16]
   ]
]

Object subclass: BitStream [
   |bitIndex byte myStream|
   BitStream class >> new: fileStream [
      |result|
      result := super new.
      result init: fileStream.
      ^result
   ]
   init: fileStream [
      myStream := fileStream.
      bitIndex := 1.
   ]
   nextBit [
      bitIndex = 1 ifTrue: [
         byte := myStream next.
         bitIndex := 9.
      ].
      bitIndex := bitIndex - 1.
      ^byte value bitAt: bitIndex
   ]
   atEnd [
      ^bitIndex = 1 and: [myStream atEnd]
   ]
   currByte [
      ^byte
   ]
]

Object subclass: ZeroArray [
   |theArray|

   ZeroArray class >> new [
      self shouldNotImplement.
   ]

   ZeroArray class >> new: size [
      |result|
      result := super new.
      result init: size.
      ^ result
   ]

   init: size [
      theArray := Array new: size.
   ]

   size [ ^ theArray size.  ]

   at: index [
      ^ theArray at: index + 1.
   ]

   at: index put: value [
      ^ theArray at: index + 1 put: value.
   ]

   incr: index [
      (self at: index) isNil
         ifTrue: [ self at: index put: 0].
      self at: index put: (self at: index) + 1.
   ]

   keysAndValuesDo: aBlock [
      (0 to: (self size) - 1) do: [:index |
         aBlock value: index value: (self at: index).
      ]
   ]

]

Object subclass: OutBits [
   |bitIndex currentByte myStream|
   OutBits class >> new [
      self shouldNotImplement.
   ]
   OutBits class >> new: fileStream [
      |result|
      result := super new.
      result init: fileStream.
      ^result
   ]
   clearByte [
      bitIndex := 8.
      currentByte := 0.
   ]
   init: fileStream [
      myStream := fileStream.
      self clearByte.
   ]
   flushByte [
      bitIndex = 8 ifFalse: [
         myStream nextPutByte: currentByte.
         self clearByte.
      ]
   ]
   writeBit: bit [
      currentByte := currentByte bitAt: bitIndex put: bit.
      bitIndex := bitIndex - 1.
      bitIndex = 0 ifTrue: [self flushByte].
   ]
]

Object subclass: Leaf [
   |char count|
   char [ ^ char ]
   count [ ^ count ]

   Leaf class >> new [
      self shouldNotImplement
   ]

   Leaf class >> new: aChar count: aCount [
      |result|
      result := super new.
      result setChar: aChar andCount: aCount.
      ^result
   ]

   setChar: aChar andCount: aCount [
      char := aChar.
      count := aCount.
   ]

   <= other [
      ^ (count < other count)
      | ((count = other count) & (char <= other char))
   ]

   printBase: aStream [
      ^ aStream << self class << '(' << char << ',' << count
   ]

   printOn: aStream [
      (self printBase: aStream) << ')'.
   ]

   depthFirst: visitor prefix: string [
      visitor value: char value: string.
   ]

   postOrder: visitor [
      visitor value: char value: true.
   ]

   isLeaf [
      ^ true
   ]
].


Leaf subclass: Tree [
   |left right|

   Tree class >> new: aChar count: aCount [
      self shouldNotImplement
   ]

   Tree class >> new: aChar count: aCount left: aLeft right: aRight [
      |result|
      result := super new: aChar count: aCount.
      result setLeft: aLeft andRight: aRight.
      ^ result
   ]

   setLeft: aLeft andRight: aRight [
      left := aLeft.
      right := aRight.
   ]

   printOn: aStream [
      (self printBase: aStream) << ',' << left << ',' << right << ')'.
   ]

   depthFirst: visitor prefix: string [
      left depthFirst: visitor prefix: string, '0'.
      right depthFirst: visitor prefix: string, '1'.
   ]

   postOrder: visitor [
      left postOrder: visitor.
      right postOrder: visitor.
      visitor value: char value: false.
   ]

   lLeaf [
      ^ left
   ]

   rLeaf [
      ^ right
   ]

   isLeaf [
      ^ false
   ]
].

FileStream extend [
   nl := Character nl.
   catFile [
      |count|
      count := 0.
      [self atEnd not] whileTrue: [
         |padded|
         count := count + 1.
         padded := count printPaddedWith: Character space to: 6.
         stdout << padded << ': ' << self nextLine << nl.
      ]
   ]
].

| d t c u filename outfilename|
d := false.
t := false.
c := false.
u := false.
filename := '-'.
outfilename := '-'.
nl := Character nl.

(Smalltalk arguments size) < 2
   ifTrue: [
      stderr << 'Usage: hzip.st -dctu inputfile [outputfile]' << nl.
      ObjectMemory quit.
   ]
   ifFalse: [
      | option |
      option := (Smalltalk arguments at: 1).
      (option includes: $-)
         ifTrue: [
            (option includes: $d)
               ifTrue: [d := true.].
            (option includes: $t)
               ifTrue: [t := true.].
            (option includes: $c)
               ifTrue: [c := true.].
            (option includes: $u)
               ifTrue: [u := true.].
         ]
         ifFalse:[
            stderr << 
            'Usage: hzip.st -dctu inputfile [outputfile]' << nl.
            ObjectMemory quit.
         ].
      filename := (Smalltalk arguments at: 2).
      (Smalltalk arguments size) > 2
         ifTrue: [
            [outfilename := (Smalltalk arguments at: 3).]
            on: SystemExceptions.FileError do: [:signal |
                  |errno|
                  errno := File errno.
                  stdout flush.
                  stderr << execname << ': ' << filename << ': '
                         << signal messageText << nl.
                  stderr flush.
               ].
            ].
   ].

[infile := FileStream open: filename
                     mode: FileStream read.]
on: SystemExceptions.FileError do: [:signal |
                  |errno|
                  errno := File errno.
                  stdout flush.
                  stderr << execname << ': ' << filename << ': '
                         << signal messageText << nl.
                  stderr flush.
               ].

d ifTrue: [
   stdout << 'Debug information for applicant author' << nl.
].

t | c ifTrue: [
   | freqtable priorityQueue huffmanTree encodingTable |
   freqtable := ZeroArray new: 257.
   [infile atEnd not] whileTrue: [
      | ordChar |
      ordChar := (infile next) asInteger.
      freqtable incr: ordChar.
   ].
   freqtable incr: 256.
   priorityQueue := SortedCollection new.
   freqtable keysAndValuesDo: [:key :value |
      (value notNil and: [value > 0]) ifTrue: [
         a := Leaf new: key count: value.
         priorityQueue add: a.
         ]
      ].
   
   [priorityQueue size > 1] whileTrue:[
         | tree leftLeaf rightLeaf name sum|
         leftLeaf := priorityQueue removeFirst.
         rightLeaf := priorityQueue removeFirst.
         name := leftLeaf char.
         sum := leftLeaf count + rightLeaf count.
         tree := Tree new: name count: sum 
         left: leftLeaf right: rightLeaf.
         priorityQueue add: tree.
      ].
   encodingTable := ZeroArray new: 257.
   huffmanTree := priorityQueue removeFirst.

   d ifTrue: [
      stdout << 'Huffman Tree' << nl.
      huffmanTree inspect.
   ].

   huffmanTree depthFirst: [:char :string |
      encodingTable at: char put: string.
      ] prefix: ''.

   d ifTrue: [
      stdout << 'Encoding Table' << nl.
      encodingTable inspect.
   ].

   c not ifTrue: [
         freqtable keysAndValuesDo: [:key :value |
            (value notNil and: [value > 0]) ifTrue: [
               | character |
               character := key asCharacter.
               key = 256 ifTrue: [stdout << 'EOF'.].
               character isGraph not ifTrue: [ 
                  (key = 256) not ifTrue: [
                     stdout << 'x'
                     << (key printPaddedWith: $0 to: 2 base: 16).
                  ]
               ]
               ifFalse: [
                  key < 256 ifTrue: [
                     stdout << ' ' << character asCharacter << ' '.
                  ]
               ].
               stdout << (value printPaddedWith: Character space to: 6).
               stdout << ' ' << (encodingTable at: key) << nl.
            ].
         ].
      ]
      ifFalse: [
         | output |
         (Smalltalk arguments size = 3) ifTrue:[
         [outfile := FileStream open: outfilename 
                                mode: FileStream write.]
                  on: SystemExceptions.FileError do: [:signal |
                  |errno|
                  errno := File errno.
                  stdout flush.
                  stderr << execname << ': ' << filename << ': '
                         << signal messageText << nl.
                  stderr flush.
               ].
         ]
         ifFalse: [outfile := stdout].
         outBytes := OutBits new: outfile.

         huffmanTree postOrder: [:cha :value |
            char := cha asInteger.
            (value = true) ifTrue: [
               outBytes writeBit: 0.
               8 to: 1 by: -1 do:[:index |
                  (char < 256) ifTrue: [
                     outBytes writeBit: (char bitAt: index).
                  ].
               ].
               (char = 0) ifTrue: [
                  outBytes writeBit: 0.
               ].
               (char = 256) ifTrue: [
                  8 to: 1 by: -1 do: [:index |
                     outBytes writeBit: 0.
                  ].
                  outBytes writeBit: 1.
               ].
            ]
            ifFalse: [
               outBytes writeBit: 1.
            ].
         ].
         outBytes writeBit: 1.
         infile reset.
         [infile atEnd not] whileTrue: [
            character := (infile next) asInteger.
            encodingString := encodingTable at: character.
            encodingString do: [:i |
               outBytes writeBit: (i asInteger).
            ].
         ].
         encodingString := encodingTable at: 256.
         encodingString do: [:i |
            outBytes writeBit: (i asInteger).
         ].
      outBytes flushByte.
      outfile close.
   ].
].

u ifTrue: [
   | treeByte decodeTree endOfFile |
   readInfile := BitStream new: infile.
   finished := false.
   stack := OrderedCollection new.
   (Smalltalk arguments size = 3) ifTrue:[
      [outfile := FileStream open: outfilename mode: FileStream write.]
         on: SystemExceptions.FileError do: [:signal |
                  |errno|
                  errno := File errno.
                  stdout flush.
                  stderr << execname << ': ' << filename << ': '
                         << signal messageText << nl.
                  stderr flush.
               ].
   ]
   ifFalse: [outfile := stdout].

   currentByte := 0.
   [finished] whileFalse: [
      isLeafByte := readInfile nextBit.
      isLeafByte = 0 ifTrue: [
         8 to: 1 by: -1 do: [:index |
            currentBit := readInfile nextBit.
            currentByte := currentByte bitAt: index put: currentBit.
         ].
         byte := currentByte.
         byte = 0 ifTrue:[
            temp := readInfile nextBit.
            temp = 0 ifTrue:[
               leafByte := Leaf new: 0 count: 0.
            ]
            ifFalse:[
               leafByte := Leaf new: 256 count: 0.
            ].
         ]
         ifFalse:[
            leafByte := Leaf new: (byte asInteger) count: 0.
         ].
         stack addFirst: leafByte.
         currentByte := 0.
      ]
      ifFalse: [
         (stack size) > 1 ifTrue: [
            rightLeafByte := stack removeFirst.
            leftLeafByte := stack removeFirst.
            treeByte := Tree new: ('-') count: 0
               left: leftLeafByte right: rightLeafByte.
            stack addFirst: treeByte.
         ]
         ifFalse: [
            finished := true.
            decodeTree := stack removeFirst.
         ].
      ].
   ].

   pointer := decodeTree.
   endOfFile := readInfile atEnd.
   pointer isLeaf ifTrue: [
      outfile close.
      infile close.
      ObjectMemory quit.
   ].
   d ifTrue: [
      stdout << 'Decode Tree' << nl.
      decodeTree inspect.
   ].

   [endOfFile = true] whileFalse: [
      pointer := decodeTree.
      [pointer isLeaf = true] whileFalse: [
         readInfile atEnd ifTrue:[
            outfile close.
            infile close.
            ObjectMemory quit.
         ].
         currBit := readInfile nextBit.
            currBit = 0 ifTrue: [
               pointer := pointer lLeaf.
            ].
            currBit = 1 ifTrue: [
               pointer := pointer rLeaf.
            ].
            pointer isLeaf ifTrue: [
               corrByte := pointer char.
               (corrByte = 256) ifTrue: [
                  endOfFile := true.
               ]
               ifFalse: [
                  outfile nextPutByte: corrByte.
               ].
            ].
         ].
      ].
   outfile close.
].
infile close.
