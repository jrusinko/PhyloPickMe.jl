using PhyloPickMe
using Test
using CSV
using Mmap

@test 1 + 2 == 3

PickMe("sampletrees.txt", "testoutput.txt")
#checkout = open("sampleoutput.txt")
testout = open("testoutput.txt")
checkout = open("CheckOutput.txt")
@test Mmap.mmap(checkout) == Mmap.mmap(testout)
