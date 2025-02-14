using ITensors,
      LinearAlgebra, # For tr()
      Random,        # To set a seed
      Test

Random.seed!(12345)

digits(::Type{T},x...) where {T} = T(sum([x[length(x)-k+1]*10^(k-1) for k=1:length(x)]))

@testset "Dense ITensor basic functionality" begin

@testset "ITensor constructors" begin
  i = Index(2,"i")
  j = Index(2,"j")
  k = Index(2,"k")

  @testset "Default" begin
    A = ITensor()
    @test store(A) isa Dense{Nothing}
    @test isNull(A)
  end

  @testset "Undef with index" begin
    A = ITensor(undef, i)
    @test store(A) isa Dense{Float64}
    @test !isNull(A)
  end

  @testset "Default with indices" begin
    A = ITensor(i,j)
    @test store(A) isa Dense{Float64}
    @test !isNull(A)
  end

  @testset "Random" begin
    A = randomITensor(i,j)
    @test store(A) isa Dense{Float64}

    @test ndims(A) == order(A) == 2 == length(inds(A))
    @test size(A) == dims(A) == (2,2)

    @test !isNull(A)

    B = randomITensor(IndexSet(i,j))
    @test store(B) isa Dense{Float64}
    @test ndims(B) == order(B) == 2 == length(inds(B))
    @test size(B) == dims(B) == (2,2)
    @test !isNull(B)
  end

  @testset "From matrix" begin
    M = [1 2; 3 4]
    A = ITensor(M,i,j)
    @test store(A) isa Dense{Float64}

    @test M ≈ matrix(A,i,j)
    @test M' ≈ matrix(A,j,i)
    @test_throws DimensionMismatch vector(A)

    @test size(A,1) == size(M,1) == 2
    @test size(A,3) == size(M,3) == 1
    @test_throws ErrorException size(A,0)
    @test_throws ErrorException size(M,0)

    M = [1 2 3; 4 5 6]
    @test_throws DimensionMismatch ITensor(M,i,j)
  end

  @testset "To Matrix" begin
    TM = randomITensor(i,j)

    M1 = matrix(TM)
    for ni in i, nj in j
      @test M1[ni,nj] ≈ TM[i(ni),j(nj)]
    end

    M2 = matrix(TM,j,i)
    for ni in i, nj in j
      @test M2[nj,ni] ≈ TM[i(ni),j(nj)]
    end

    T3 = randomITensor(i,j,k)
    @test_throws DimensionMismatch matrix(T3,i,j)
  end

  @testset "To Vector" begin
    TV = randomITensor(i)

    V = vector(TV)
    for ni in i
      @test V[ni] ≈ TV[i(ni)]
    end

    T2 = randomITensor(i,j)
    @test_throws DimensionMismatch vector(T2)
  end

  @testset "Complex" begin
    A = ITensor(Complex,i,j)
    @test store(A) isa Dense{ComplexF64}
  end

  @testset "Random complex" begin
    A = randomITensor(Complex,i,j)
    @test store(A) isa Dense{ComplexF64}
  end

  @testset "From complex matrix" begin
    M = [1+2im 2; 3 4]
    A = ITensor(M,i,j)
    @test store(A) isa Dense{ComplexF64}
  end

end

@testset "Convert to complex" begin
  i = Index(2,"i")
  j = Index(2,"j")
  A = randomITensor(i,j)
  B = complex(A)
  for ii ∈ dim(i), jj ∈ dim(j)
    @test complex(A[i(ii),j(jj)]) == B[i(ii),j(jj)]
  end
end

@testset "similar" begin
  i = Index(2,"i")
  j = Index(2,"j")
  A = randomITensor(i,j)
  B = similar(A)
  @test inds(B) == inds(A)
  Ac = similar(A, ComplexF32)
  @test store(Ac) isa Dense{ComplexF32}
end

@testset "fill!" begin
  i = Index(2,"i")
  j = Index(2,"j")
  A = randomITensor(i,j)
  fill!(A, 1.0)
  @test all(data(store(A)) .== 1.0)
end

@testset "copyto!" begin
  i = Index(2,"i")
  j = Index(2,"j")
  M = [1 2; 3 4]
  A = ITensor(M,i,j)
  N = 2*M
  B = ITensor(N,i,j)
  copyto!(A, B)
  @test A == B
  @test data(store(A)) == vec(N)
  A = ITensor(M,i,j)
  B = ITensor(N,j,i)
  copyto!(A, B)
  @test A == B
  @test data(store(A)) == vec(transpose(N))
end

@testset "Unary -" begin
  i = Index(2,"i")
  j = Index(2,"j")
  M = [1 2; 3 4]
  A = ITensor(M,i,j)
  @test -A == ITensor(-M, i, j)
end

@testset "dot" begin
  i = Index(2,"i")
  a = [1.0; 2.0]
  b = [3.0; 4.0]
  A = ITensor(a,i)
  B = ITensor(b,i)
  @test dot(A, B) == 11.0
end

@testset "exponentiate" begin
  s1 = Index(2,"s1")
  s2 = Index(2,"s2")
  i1 = Index(2,"i1")
  i2 = Index(2,"i2")
  Amat = rand(2,2,2,2)
  A = ITensor(Amat,i1,i2,s1,s2)

  Aexp = exp(A,(i1,i2),(s1,s2))
  Amatexp = reshape(exp(reshape(Amat,4,4)),2,2,2,2)
  Aexp_from_mat = ITensor(Amatexp,i1,i2,s1,s2)
  @test Aexp ≈ Aexp_from_mat

  #test that exponentiation works when indices need to be permuted
  Aexp = exp(A,(s1,s2),(i1,i2))
  Amatexp = Matrix(exp(reshape(Amat,4,4))')
  Aexp_from_mat = ITensor(reshape(Amatexp,2,2,2,2),s1,s2,i1,i2)
  @test Aexp ≈ Aexp_from_mat

  #test exponentiation when hermitian=true is used
  Amat = reshape(Amat, 4,4)
  Amat = reshape(Amat+Amat'+randn(4,4)*1e-10,2,2,2,2)
  A = ITensor(Amat,i1,i2,s1,s2)
  Aexp = exp(A,(i1,i2),(s1,s2),ishermitian=true)
  Amatexp = reshape(parent(exp(Hermitian(reshape(Amat,4,4)))),
                    2,2,2,2)
  Aexp_from_mat = ITensor(Amatexp,i1,i2,s1,s2)
  @test Aexp ≈ Aexp_from_mat
end


@testset "add and axpy" begin
  i = Index(2,"i")
  a = [1.0; 2.0]
  b = [3.0; 4.0]
  A = ITensor(a,i)
  B = ITensor(b,i)
  c = [5.0; 8.0]
  @test A + B == ITensor([4.0; 6.0], i)
  @test axpy!(2.0, A, B) == ITensor(c, i) 
  a = [1.0; 2.0]
  b = [3.0; 4.0]
  A = ITensor(a,i)
  B = ITensor(b,i)
  c = [8.0; 12.0]
  @test add!(A, 2.0, 2.0, B) == ITensor(c, i) 
  
end

@testset "mul! and rmul!" begin
  i = Index(2,"i")
  a = [1.0; 2.0]
  b = [2.0; 4.0]
  A = ITensor(a,i)
  A2, A3 = copy(A), copy(A)
  B = ITensor(b,i)
  @test mul!(A2, A, 2.0) == B == ITensors.add!(A2, 0, 2, A)
  @test rmul!(A, 2.0) == B == ITensors.scale!(A3, 2)

  i = Index(2,"i")
  j = Index(2,"j")
  M = [1 2; 3 4]
  A = ITensor(M,i,j)
  N = 2*M 
  B = ITensor(N,j,i)
  @test data(store(mul!(B, A, 2.0))) == 2.0*vec(transpose(M))
end

@testset "show" begin
  i = Index(2,"i")
  a = [1.0; 2.0]
  A = ITensor(a,i)
  s = split(sprint(show, A), '\n')
  @test s[1] == "ITensor ord=1 " * sprint(show, i) * " "
  @test s[2] == "Dense{Float64}"
  @test s[3] == " 1.0"
  @test s[4] == " 2.0"
end

@testset "Test isapprox for ITensors" begin
  m,n = rand(0:20,2)
  i = Index(m)
  j = Index(n)
  realData = rand(m,n)
  complexData = complex(realData)
  A = ITensor(realData, i,j)
  B = ITensor(complexData, i,j)
  @test A≈B
  @test B≈A
  A = permute(A,j,i)
  @test A≈B
  @test B≈A
end

@testset "ITensor tagging and priming" begin
  s1 = Index(2,"Site,s=1")
  s2 = Index(2,"Site,s=2")
  l = Index(3,"Link")
  A1 = randomITensor(s1,l,l')
  A2 = randomITensor(s2,l',l'')
  @testset "findindex(::ITensor,::String)" begin
    @test s1==findindex(A1,"Site")
    @test s1==findindex(A1,"s=1")
    @test s1==findindex(A1,"s=1,Site")
    @test l==findindex(A1,("Link",0))
    @test l'==findindex(A1,("",1))
    @test l'==findindex(A1,("Link",1))
    @test s2==findindex(A2,"Site")
    @test s2==findindex(A2,"s=2")
    @test s2==findindex(A2,"Site")
    @test s2==findindex(A2,("",0))
    @test s2==findindex(A2,("s=2",0))
    @test s2==findindex(A2,("Site",0))
    @test s2==findindex(A2,("s=2,Site",0))
    @test l'==findindex(A2,("",1))
    @test l'==findindex(A2,("Link",1))
    @test l''==findindex(A2,("",2))
    @test l''==findindex(A2,("Link",2))
  end
  @testset "addtags(::ITensor,::String,::String)" begin
    s1u = addtags(s1,"u")
    lu = addtags(l,"u")

    A1u = addtags(A1,"u")
    @test hasinds(A1u,s1u,lu,lu')

    A1u = addtags(A1,"u","Link")
    @test hasinds(A1u,s1,lu,lu')

    A1u = addtags(A1,"u",("",0))
    @test hasinds(A1u,s1u,lu,l')

    A1u = addtags(A1,"u",("Link",0))
    @test hasinds(A1u,s1,lu,l')

    A1u = addtags(A1,"u",("Link",1))
    @test hasinds(A1u,s1,l,lu')
  end
  @testset "removetags(::ITensor,::String,::String)" begin
    A2r = removetags(A2,"Site")
    @test hasinds(A2r,removetags(s2,"Site"),l',l'')

    A2r = removetags(A2,"Link",("",1))
    @test hasinds(A2r,s2,removetags(l,"Link")',l'')
  end
  @testset "replacetags(::ITensor,::String,::String)" begin
    s2tmp = replacetags(s2,"Site","Temp")
    ltmp = replacetags(l,"Link","Temp")

    A2r = replacetags(A2,"Site","Temp")
    @test hasinds(A2r,s2tmp,l',l'')

    A2r = replacetags(A2,"Link","Temp")
    @test hasinds(A2r,s2,ltmp',ltmp'')

    A2r = replacetags(A2,"Link","Temp",("",1))
    @test hasinds(A2r,s2,ltmp',l'')

    A2r = replacetags(A2,("Link",2),("Temp",3))
    @test hasinds(A2r,s2,l',ltmp''')

    A2r = replacetags(A2,("",1),("",5))
    @test hasinds(A2r,s2,prime(l,5),l'')

    #In-place version
    cA2 = copy(A2)
    replacetags!(cA2,("",1),("",5))
    @test hasinds(cA2,s2,prime(l,5),l'')
  end
  @testset "prime(::ITensor,::String)" begin
    A2p = prime(A2)
    @test A2p==A2'
    @test hasinds(A2p,s2',l'',l''')

    A2p = prime(A2,2)
    A2p = A2''
    @test hasinds(A2p,s2'',l''',l'''')

    A2p = prime(A2,"s=2")
    @test hasinds(A2p,s2',l',l'')
  end

  @testset "mapprime" begin
    @test hasinds(mapprime(A2,1,7),s2,l^7,l'')
    @test hasinds(mapprime(A2,0,1),s2',l',l'')
  end
  @testset "setprime" begin
    @test hasinds(setprime(A2,2,s2),s2'',l',l'')
    @test hasinds(setprime(A2,0,l''),s2,l',l)
  end
  @testset "swapprime" begin
    @test hasinds(swapprime(A2,1,3),l''',s2,l'')
  end
end

@testset "Converting Real and Complex Storage" begin

  @testset "Add Real and Complex" begin
    i = Index(2,"i")
    j = Index(2,"j")
    TC = randomITensor(ComplexF64,i,j)
    TR = randomITensor(Float64,i,j)

    S1 = TC+TR
    S2 = TR+TC
    @test typeof(S1.store) == Dense{ComplexF64}
    @test typeof(S2.store) == Dense{ComplexF64}
    for ii=1:dim(i),jj=1:dim(j)
      @test S1[i(ii),j(jj)] ≈ TC[i(ii),j(jj)]+TR[i(ii),j(jj)]
      @test S2[i(ii),j(jj)] ≈ TC[i(ii),j(jj)]+TR[i(ii),j(jj)]
    end
  end

end


@testset "ITensor, Dense{$SType} storage" for SType ∈ (Float64,ComplexF64)
  mi,mj,mk,ml,mα = 2,3,4,5,6,7
  i = Index(mi,"i")
  j = Index(mj,"j")
  k = Index(mk,"k")
  l = Index(ml,"l")
  α = Index(mα,"alpha")
  @testset "Set and get values with IndexVals" begin
    A = ITensor(SType,i,j,k)
    for ii ∈ 1:dim(i), jj ∈ 1:dim(j), kk ∈ 1:dim(k)
      A[k(kk),j(jj),i(ii)] = digits(SType,ii,jj,kk)
    end
    for ii ∈ 1:dim(i), jj ∈ 1:dim(j), kk ∈ 1:dim(k)
      @test A[j(jj),k(kk),i(ii)]==digits(SType,ii,jj,kk)
    end
    @test_throws MethodError A[1]
  end
  @testset "Test permute(ITensor,Index...)" begin
    A = randomITensor(SType,i,k,j)
    permA = permute(A,k,j,i)
    @test k==inds(permA)[1]
    @test j==inds(permA)[2]
    @test i==inds(permA)[3]
    for ii ∈ 1:dim(i), jj ∈ 1:dim(j), kk ∈ 1:dim(k)
      @test A[k(kk),i(ii),j(jj)]==permA[i(ii),j(jj),k(kk)]
    end
    for ii ∈ 1:dim(i), jj ∈ 1:dim(j), kk ∈ 1:dim(k)
      @test A[k(kk),i(ii),j(jj)]==permA[i(ii),j(jj),k(kk)]
    end
    # TODO: I think this was doing slicing, but what is the output
    # of slicing an ITensor?
    #@testset "getindex and setindex with vector of IndexVals" begin
    #    k_inds = [k(kk) for kk ∈ 1:dim(k)]
    #    for ii ∈ 1:dim(i), jj ∈ 1:dim(j)
    #      @test A[k_inds,i(ii),j(jj)]==permA[i(ii),j(jj),k_inds...]
    #    end
    #    for ii ∈ 1:dim(i), jj ∈ 1:dim(j)
    #        A[k_inds,i(ii),j(jj)]=collect(1:length(k_inds))
    #    end
    #    permA = permute(A,k,j,i)
    #    for ii ∈ 1:dim(i), jj ∈ 1:dim(j)
    #      @test A[k_inds,i(ii),j(jj)]==permA[i(ii),j(jj),k_inds...]
    #    end
    #end
  end
  @testset "Set and get values with Ints" begin
    A = ITensor(SType,i,j,k)
    A = permute(A,k,i,j)
    for ii ∈ 1:dim(i), jj ∈ 1:dim(j), kk ∈ 1:dim(k)
      A[kk,ii,jj] = digits(SType,ii,jj,kk)
    end
    A = permute(A,i,j,k)
    for ii ∈ 1:dim(i), jj ∈ 1:dim(j), kk ∈ 1:dim(k)
      @test A[ii,jj,kk]==digits(SType,ii,jj,kk)
    end
  end
  @testset "Test scalar(ITensor)" begin
    x = SType(34)
    A = ITensor(x)
    @test x==scalar(A)
    A = ITensor(SType,i,j,k)
    @test_throws BoundsError scalar(A)
  end
  @testset "Test norm(ITensor)" begin
    A = randomITensor(SType,i,j,k)
    @test norm(A)≈sqrt(scalar(dag(A)*A))
  end
  @testset "Test add ITensors" begin
    A = randomITensor(SType,i,j,k)
    B = randomITensor(SType,k,i,j)
    C = A+B
    for ii ∈ 1:dim(i), jj ∈ 1:dim(j), kk ∈ 1:dim(k)
      @test C[i(ii),j(jj),k(kk)]==A[j(jj),i(ii),k(kk)]+B[i(ii),k(kk),j(jj)]
    end
    @test array(permute(C,i,j,k))==array(permute(A,i,j,k))+array(permute(B,i,j,k))
  end

  @testset "Test factorizations of an ITensor" begin

    A = randomITensor(SType,i,j,k,l)

    @testset "Test SVD of an ITensor" begin
      U,S,V,u,v = svd(A,(j,l))
      @test store(S) isa Diag{Vector{Float64}}
      @test A≈U*S*V
      @test U*dag(prime(U,u))≈δ(SType,u,u') atol=1e-14
      @test V*dag(prime(V,v))≈δ(SType,v,v') atol=1e-14
    end

    @testset "Test SVD truncation" begin
        ii = Index(4)
        jj = Index(4)
        T = randomITensor(ComplexF64,ii,jj)
        U,S,V = svd(T,ii;maxdim=2)
        u,s,v = svd(matrix(T))
        @test norm(U*S*V-T)≈sqrt(s[3]^2+s[4]^2)
    end

    @testset "Test QR decomposition of an ITensor" begin
      Q,R,q = qr(A,(i,l))
      q = commonindex(Q,R)
      @test A≈Q*R
      @test Q*dag(prime(Q,q))≈δ(SType,q,q') atol=1e-14
    end

    @testset "Test polar decomposition of an ITensor" begin
      U,P,u = polar(A,(k,l))
      @test A≈U*P
      #Note: this is only satisfied when left dimensions
      #are greater than right dimensions
      UUᵀ =  U*dag(prime(U,u))

      # TODO: use a combiner to combine the u indices to make
      # this test simpler
      for ii ∈ 1:dim(u[1]), jj ∈ 1:dim(u[2]), iip ∈ 1:dim(u[1]), jjp ∈ 1:dim(u[2])
        val = UUᵀ[u[1](ii),u[2](jj),u[1]'(iip),u[2]'(jjp)]
        if ii==iip && jj==jjp
          @test val≈one(SType) atol=1e-14
        else
          @test val≈zero(SType) atol=1e-14
        end
      end
    end

    @testset "Test Hermitian eigendecomposition of an ITensor" begin
      is = IndexSet(i,j)
      T = randomITensor(is...,prime(is)...)
      T = T + swapprime(dag(T),0,1)
      U,D,u = eigenHermitian(T)
      @test T ≈ U*D*prime(dag(U))
      UUᴴ =  U*prime(dag(U),u)
      @test UUᴴ ≈ δ(u,u') atol=1e-14
    end

  end # End ITensor factorization testset

end # End Dense storage test

end # End Dense ITensor basic functionality

