using PhyloPickMe
using Test
using CSV
using Mmap

@test 1 + 2 == 3

PickMe("sampletrees.txt", "testoutput.txt")
# Function to compare non-header lines in two files with tolerance

# Function to compare non-header lines in two files with tolerance
function compare_files(file1::String, file2::String; tolerance=1e-10)
    data1 = readlines(file1)[3:end]  # Read from the 3rd line to the end
    data2 = readlines(file2)[3:end]  # Read from the 3rd line to the end

    # Initialize a flag for matching
    match = true
    differences = []

    for (line1, line2) in zip(data1, data2)
        # Split lines into fields
        fields1 = split(line1, ",")  # Split CSV string into fields
        fields2 = split(line2, ",")  # Split CSV string into fields

        # Check if the first and third columns are the same (strings)
        if fields1[1] != fields2[1] || fields1[3] != fields2[3]
            match = false
            push!(differences, ("String mismatch", fields1[1], fields2[1], fields1[3], fields2[3]))
        end

        # Compare the second and fourth columns with tolerance
        if length(fields1) >= 4 && length(fields2) >= 4
            num1_col2 = parse(Float64, fields1[2])  # Parse second column to Float64
            num2_col2 = parse(Float64, fields2[2])  # Parse second column to Float64

            num1_col4 = parse(Float64, fields1[4])  # Parse fourth column to Float64
            num2_col4 = parse(Float64, fields2[4])  # Parse fourth column to Float64

            # Compare second column
            if abs(num1_col2 - num2_col2) > tolerance
                match = false
                push!(differences, (num1_col2, num2_col2))
            end

            # Compare fourth column
            if abs(num1_col4 - num2_col4) > tolerance
                match = false
                push!(differences, (num1_col4, num2_col4))
            end
        else
            match = false
            push!(differences, ("Line length mismatch", line1, line2))
        end
    end

    return match, differences  # Return whether they match and any differences found
end

# Test case to compare the two output files
@testset "File comparison tests" begin
    file1 = "CheckOutput.txt"
    file2 = "testoutput.txt"

    match, differences = compare_files(file1, file2)

    @test match  # This will pass if the files match
    if !match
        println("The files do not match:")
        for diff in differences
            println("Difference: $diff")
        end
    end
end