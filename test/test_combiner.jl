using ITensors, Test
using Combinatorics: permutations

@testset "Combiner" begin

i = Index(2,"i")
j = Index(3,"j")
k = Index(4,"k")
l = Index(5,"l")

A = randomITensor(i, j, k, l)

@testset "Two index combiner" begin
    for inds_ij ∈ permutations([i,j])
        C,c = combiner(inds_ij...)
        B = A*C
        @test hasinds(B, l, k, c)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
    for inds_il ∈ permutations([i,l])
        C,c = combiner(inds_il...)
        B = A*C
        @test hasinds(B, j, k)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
    for inds_ik ∈ permutations([i,k])
        C,c = combiner(inds_ik...)
        B = A*C
        @test hasinds(B, j, l)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
    for inds_jk ∈ permutations([j,k])
        C,c = combiner(inds_jk...)
        B = A*C
        @test hasinds(B, i, l)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
    for inds_jl ∈ permutations([j,l])
        C,c = combiner(inds_jl...)
        B = A*C
        @test hasinds(B, i, k)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
    for inds_kl ∈ permutations([k,l])
        C,c = combiner(inds_kl...)
        B = A*C
        @test hasinds(B, i, j)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
end

@testset "Three index combiner" begin
    for inds_ijl ∈ permutations([i,j,l])
        C,c = combiner(inds_ijl...)
        B = A*C
        @test hasindex(B, k)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
    for inds_ijk ∈ permutations([i,j,k])
        C,c = combiner(inds_ijk...)
        B = A*C
        @test hasindex(B, l)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
    for inds_jkl ∈ permutations([j,k,l])
        C,c = combiner(inds_jkl...)
        B = A*C
        @test hasindex(B, i)
        @test c == commonindex(B, C)
        D = B*C
        @test hasinds(D, i, j, k, l)
        @test D ≈ A
    end
end

end

