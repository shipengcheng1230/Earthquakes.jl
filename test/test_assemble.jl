using Test

@testset "Okada Assemble" begin
    @testset "1D fault" begin
        fa = fault(Val(:LineOkada), DIPPING(), 10., 2.0, 45.0)
        p = ElasticRSFProperty([rand(fa.mesh.nξ) for _ in 1: 4]..., rand(6)...)
        u0 = ArrayPartition([rand(fa.mesh.nξ) for _ in 1: 2]...)
        prob, = assemble(fa, p, u0, (0., 1.0); flf=CForm())
        du = similar(u0)
        @inferred prob.f(du, u0, prob.p, 1.0)
    end

    @testset "2D fault" begin
        fa = fault(Val(:RectOkada), STRIKING(), 10., 10., 2., 2.)
        p = ElasticRSFProperty([rand(fa.mesh.nx, fa.mesh.nξ) for _ in 1: 4]..., rand(6)...)
        u0 = ArrayPartition([rand(fa.mesh.nx, fa.mesh.nξ) for _ in 1: 2]...)
        prob, = assemble(fa, p, u0, (0., 1.0); buffer_ratio=1)
        du = similar(u0)
        @inferred prob.f(du, u0, prob.p, 1.0)
    end
end
