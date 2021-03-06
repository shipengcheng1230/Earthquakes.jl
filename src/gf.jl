export compose_stress_greens_func

## Static Green's Function
"Obtain mapping from local linear index to cartesian index."
function get_subs(A::SharedArray)
    i2s = CartesianIndices(A)
    inds = localindices(A)
    subs = i2s[inds]
end

"A general pattern parallel SharedArray computation. See [here](https://docs.julialang.org/en/v1/manual/parallel-computing/#man-shared-arrays-1) for an example."
macro gen_shared_chunk_call(name::Symbol)
    namestr = String(name) * "!"
    chunkstr = Symbol(namestr[1:end-1] * "_chunk!")
    namestr = Symbol(namestr)
    esc(quote
        function $(namestr)(st::S, args...; kwargs...) where S<:Union{SharedArray, NTuple{N, <:SharedArray}} where N
            pcs = typeof(st) <: SharedArray ? procs(st) : procs(st[1])
            @sync begin
                for p in pcs
                    @async remotecall_wait($(chunkstr), p, st, args...; kwargs...)
                end
            end
        end
        function $(chunkstr)(st::SharedArray, args...; kwargs...)
            subs = get_subs(st)
            $(chunkstr)(st, subs, args...; kwargs...)
        end
        function $(chunkstr)(st::NTuple{N, <:SharedArray}, args...; kwargs...) where N
            subs = get_subs(st[1]) # all SharedArray shall have the same dims
            $(chunkstr)(st, subs, args...; kwargs...)
        end
    end)
end

## helper function
heaviside(x::T) where T = x ≤ zero(T) ? zero(T) : one(T)
xlogy(x::T, y::T) where T = isapprox(x, zero(T)) ? zero(T) : x * log(y)
xlogy(x, y) = xlogy(promote(x, y)...)
omega(x::T) where T = heaviside(x + 1/2) - heaviside(x - 1/2)
S(x::T) where T = omega(x - 1/2)

## kernel function
const KERNELDIR = joinpath(@__DIR__, "gf")
foreach(x -> include(joinpath(KERNELDIR, x)), filter!(x -> endswith(x, ".jl") && !startswith(x, "_"), readdir(KERNELDIR)))

## concrete greens function
export stress_greens_func
@gen_shared_chunk_call stress_greens_func

include("gf_dislocation.jl")
include("gf_strain.jl")

## composite green's function
@with_kw struct ViscoelasticCompositeGreensFunction{T<:AbstractMatrix, U<:AbstractArray, I<:Integer, V1<:NTuple, V2<:NTuple}
    ee::U # elastic ⟷ elastic
    ev::T # elastic ⟷ inelastic
    ve::T # inelastic ⟷ elastic
    vv::T # inelastic ⟷ inelastic
    nume::I
    numϵ::I
    numσ::I
    ϵcomp::V1
    σcomp::V2
    hint::Symbol=:general

    @assert ϵcomp ⊆ σcomp "Strain components must be a subset of stress components."
end

"""
    compose_stress_greens_func(ee::AbstractArray, ev::NTuple, ve::NTuple, vv::NTuple{N, <:Tuple},
        ϵcomp::NTuple, σcomp::NTuple) where N

Concatenate tuple of matrix or tuple of tuple of matrix which arrange them in
    a way to update traction/stress rate using only one BLAS call. It does nothing
    to the elastic Green's function and specifically used for the outputs from
    [`stress_greens_func`](@ref) and [`stress_greens_func`](@ref).

## Arguments
- `ee::AbstractArray`: traction Green's function within the elastic fault
- `ev::NTuple`: stress Green's function from elastic fault to inelastic asthenosphere
- `ve::NTuple`: traction Green's function inelastic asthenosphere to elastic fault
- `vv::NTuple`: stress Green's function within inelastic asthenosphere
- `ϵcomp`: strain component to be considered, must be a subset of `σcomp`
- `σcomp`: stress component to be considered
"""
function compose_stress_greens_func(ee::AbstractArray, ev::NTuple, ve::NTuple, vv::NTuple{N, <:Tuple}, ϵcomp::NTuple, σcomp::NTuple, hint::Symbol=:general) where N
    # TODO this only applies for tuple-style, need to make adaption for singleton array
    numσ, numϵ = length(ev), length(ve)
    σindex, ϵindex = Base.OneTo(numσ), Base.OneTo(numϵ)
    m1, n1 = size(ev[1]) # number of inelastic elements, number of fault patches
    m2, n2 = size(ve[1]) # in case of antiplane case, `m2` would be different than `n1`
    ev′ = PseudoBlockArray{eltype(ev[1])}(undef, [m1 for _ in σindex], [n1])
    ve′ = PseudoBlockArray{eltype(ve[1])}(undef, [m2], [n2 for _ in ϵindex])
    vv′ = PseudoBlockArray{eltype(vv[1][1])}(undef, [m1 for _ in σindex], [m1 for _ in ϵindex])
    foreach(i -> setblock!(ev′, ev[i], i, 1), σindex)
    foreach(i -> setblock!(ve′, ve[i], 1, i), ϵindex)
    foreach(x -> setblock!(vv′, vv[x[2]][x[1]], x[1], x[2]), Iterators.product(σindex, ϵindex))
    ViscoelasticCompositeGreensFunction(ee, Array(ev′), Array(ve′), Array(vv′), m1, numϵ, numσ, ϵcomp, σcomp, hint)
end

"""
    compose_stress_greens_func(mf::OkadaMesh, me::SBarbotMeshEntity,
        λ::T, μ::T, ft::PlaneFault, comp::NTuple{N, <:Symbol}) where {T, N}

Shortcut function for computing all 4 Green's function for viscoelastic relaxation.
    Arguments stays the same as [`stress_greens_func`](@ref).
"""
function compose_stress_greens_func(mf::AbstractMesh{2}, me::SBarbotMeshEntity, λ::T, μ::T, ft::PlaneFault, ϵcomp::NTuple, σcomp::NTuple, hint::Symbol=:general) where T
    ee = stress_greens_func(mf, λ, μ, ft)
    ev = stress_greens_func(mf, me, λ, μ, ft, σcomp)
    ve = stress_greens_func(me, mf, λ, μ, ft, ϵcomp)
    vv = stress_greens_func(me, λ, μ, ϵcomp, σcomp)
    return compose_stress_greens_func(ee, ev, ve, vv, ϵcomp, σcomp, hint)
end

function compose_stress_greens_func(mf::AbstractMesh{2}, me::SBarbotHex8AntiplaneMeshEntity, λ::T, μ::T, ft::PlaneFault, ϵcomp::NTuple, σcomp::NTuple) where T
    compose_stress_greens_func(mf, me, λ, μ, ft, ϵcomp, σcomp, :antiplane)
end

include("gf_operator.jl")
