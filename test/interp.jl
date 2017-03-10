cases = ["B-splines","Cheb","Lin"]

# construct basis
holder = (
    Basis(SplineParams(15,-1, 1, 1),SplineParams(20,-5, 2, 3)),
    Basis(ChebParams(15,-1, 1),ChebParams(20,-5, 2)),
    Basis(LinParams(15,-1, 1),LinParams(20,-5, 2))
)

@testset for (i, case) in enumerate(cases)
    basis = holder[i]

    # get nodes
    X, x12 = nodes(basis)

    # function to interpolate
    f(x1, x2) = cos.(x1) ./ exp.(x2)
    f(X::Matrix) = f(X[:, 1], X[:, 2])

    # function at nodes
    y = f(X)

    # benchmark coefficients
    c_direct, bs_direct = funfitxy(basis, X, y)

    @testset "test funfitxy for tensor and direct agree on coefs" begin
        c_tensor, bs_tensor = funfitxy(basis, x12, y)
        @test maximum(abs, c_tensor -  c_direct) <=  1e-12
    end

    @testset "test funfitf" begin
        c = funfitf(basis, f)
        @test maximum(abs, c -  c_direct) <=  1e-12
    end

    @testset "test funeval methods" begin
        # single point
        sp = @inferred funeval(c_direct, basis, X[5:5, :])[1]
        @test maximum(abs, sp -  y[5]) <= 1e-12

        # multiple points using tensor directly
        mp = @inferred funeval(c_direct, basis, x12)
        @test maximum(abs, mp -  y) <=  1e-12

        # multiple points using direct
        mp = @inferred funeval(c_direct, basis, X)
        @test maximum(abs, mp -  y) <=  1e-12

        # multiple points giving basis in direct form
        mpd = @inferred funeval(c_direct, bs_direct)
        @test maximum(abs, mpd -  y) <=  1e-12

        # multiple points giving basis in expanded form
        Phiexp = Base.convert(Expanded, bs_direct)
        mpe = @inferred funeval(c_direct, Phiexp)
        @test maximum(abs, mpe -  y) <=  1e-12

    end

    @testset "test interpoland methods" begin
        # (Basis, BasisMatrix,..)
        intp1 = Interpoland(basis, y)
        @test maximum(abs, intp1(X) - y) <= 1e-12

        # (Basis, Array,..)
        intp2 = Interpoland(basis, y)
        @test maximum(abs, intp2(X) - y) <= 1e-12

        # (BasisParams, Function)
        intp3 = Interpoland(basis, f)
        @test maximum(abs, intp3(X) - y) <= 1e-12
    end

    @testset "Printing" begin
        iob = IOBuffer()
        show(iob, Interpoland(basis, y))
    end

end # testset
