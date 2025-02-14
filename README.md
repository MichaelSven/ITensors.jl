[![Build Status](https://travis-ci.org/ITensor/ITensors.jl.svg?branch=master)](https://travis-ci.org/ITensor/ITensors.jl) [![codecov](https://codecov.io/gh/ITensor/ITensors.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ITensor/ITensors.jl)

PLEASE NOTE THIS IS PRE-RELEASE SOFTWARE FOR PREVIEW PURPOSES ONLY

THIS SOFTWARE IS SUBJECT TO BREAKING CHANGES AND NOT YET OFFICIALLY SUPPORTED

ITensors is a library for rapidly creating correct and efficient
tensor network algorithms. 

An ITensor is a tensor whose interface 
is independent of its memory layout. ITensor indices are
objects which carry extra information and which
'recognize' each other (compare equal to each other).

The ITensor library also includes composable and extensible 
algorithms for optimizing and transforming tensor networks, such as 
matrix product state and matrix product operators, such as
the DMRG algorithm.

Development of ITensor is supported by the Flatiron Institute, a division of the Simons Foundation.

## Code Examples

### Basic Overview

Here is a basic intro overview of making 
ITensors, setting some elements, contracting, and adding
ITensors. See further examples below for detailed
detailed examples of these operations and more.

```Julia
using ITensors
let
  i = Index(3)
  j = Index(5,"MyTag")
  k = Index(4,"Link,n=1")
  l = Index(7,"Site")

  A = ITensor(i,j,k)
  B = ITensor(j,l)

  A[i(1),j(1),k(1)] = 11.1
  A[i(2),j(1),k(2)] = 21.2
  A[k(1),i(3),j(1)] = 31.1  # can provide Index values in any order
  # ...

  # contract over index j
  C = A * B

  @show hasinds(C,i,k,l) # == true

  D = randomITensor(k,j,i)

  # add two ITensors
  R = A + D

end

```

### Making Tensor Indices

Before making an ITensor, you have to define its indices.
Tensor indices in ITensors.jl are themselves objects that 
carry extra information beyond just their dimension.

```Julia
using ITensors
let
  i = Index(3)     # Index of dimension 3
  @show dim(i)     # dim(i) = 3

  j = Index(5,"j") # Index with a tag "j"

  s = Index(2,"n=1,Site") # Index with two tags,
                          # "Site" and "n=1"
  @show hastags(s,"Site") # hastags(s,"Site") = true
  @show hastags(s,"n=1")  # hastags(s,"n=1") = true
end
```

### Singular Value Decomposition (SVD) of a Matrix

In this example, we create a random 10x20 matrix 
and compute its SVD. The resulting factors can 
be simply multiplied back together using the
ITensor `*` operation, which automatically recognizes
the matching indices between U and S, and between S and V
and contracts (sums over) them.

```Julia
using ITensors
let
  i = Index(10)           # index of dimension 10
  j = Index(20)           # index of dimension 20
  M = randomITensor(i,j)  # random matrix, indices i,j
  U,S,V = svd(M,i)        # compute SVD
  @show norm(M - U*S*V)   # ≈ 0.0
end
```

### Singular Value Decomposition (SVD) of a Tensor

In this example, we create a random 4x4x4x4 tensor 
and compute its SVD, temporarily treating the first
and third indices (i and k) as the "row" index and the second
and fourth indices (j and l) as the "column" index for the purposes
of the SVD. The resulting factors can 
be simply multiplied back together using the
ITensor `*` operation, which automatically recognizes
the matching indices between U and S, and between S and V
and contracts (sums over) them.

```Julia
using ITensors
let
  i = Index(4,"i")
  j = Index(4,"j")
  k = Index(4,"k")
  l = Index(4,"l")
  T = randomITensor(i,j,k,l)
  U,S,V = svd(T,i,k)
  @show hasinds(U,i,k) # == true
  @show hasinds(V,j,l) # == true
  @show norm(T - U*S*V)   # ≈ 0.0
end
```

### DMRG Calculation

DMRG is an iterative algorithm for finding the dominant
eigenvector of an exponentially large, Hermitian matrix.
It originates in physics with the purpose of finding
eigenvectors of Hamiltonian (energy) matrices which model
the behavior of quantum systems.

```Julia
using ITensors

let
  # Create 100 spin-one (dimension 3) indices
  N = 100
  sites = spinOneSites(N)

  # Input operator terms which define 
  # a Hamiltonian matrix, and convert
  # these terms to an MPO tensor network
  ampo = AutoMPO()
  for j=1:N-1
    add!(ampo,"Sz",j,"Sz",j+1)
    add!(ampo,0.5,"S+",j,"S-",j+1)
    add!(ampo,0.5,"S-",j,"S+",j+1)
  end
  H = MPO(ampo,sites)

  # Create an initial random matrix product state
  psi0 = randomMPS(sites)

  # Plan to do 5 passes or 'sweeps' of DMRG,
  # setting maximum MPS internal dimensions 
  # for each sweep and maximum truncation cutoff
  # used when adapting internal dimensions:
  sweeps = Sweeps(5)
  maxdim!(sweeps, 10,20,100,100,200)
  cutoff!(sweeps, 1E-10)
  @show sweeps

  # Run the DMRG algorithm, returning energy 
  # (dominant eigenvalue) and optimized MPS
  energy, psi = dmrg(H,psi0, sweeps)
  println("Final energy = $energy")
end
```
