## assemble the system derivative function

export assemble

## single degree of freedom

"Just Hook's law."
@inline dτ_dt(K::T, v::T, vpl::T) where {T<:Number} = K * (vpl - v)

"Derivative of velocity in quai-dynamic rate-and-state governing equation."
@inline dv_dt(dτdt::T, dμdv::T, dμdθ::T, dθdt::T, η::T) where {T<:Number} = (dτdt - dμdθ * dθdt) / (dμdv + η)

"""
Out-place version of derivative of *velocity* (or you may call it slip rate)
and *state* (the *state* in rate-and-state friction) for single degree of freedom system.
This for now only support single *state* variable, which is most-widely used.
"""
@inline function dv_dθ_dt(::CForm, se::SE, v::T, θ::T, a::T, b::T, L::T, k::T, σ::T, η::T, vpl::T, ::Vararg{T},
    ) where {T<:Number, SE<:StateEvolutionLaw}
    dμdθ = σ * b / θ
    dμdv = σ * a / v
    dθdt = dθ_dt(se, v, θ, L)
    dτdt = dτ_dt(k, v, vpl)
    return dv_dt(dτdt, dμdv, dμdθ, dθdt, η), dθdt
end

@inline function dv_dθ_dt(::RForm, se::SE, v::T, θ::T, a::T, b::T, L::T, k::T, σ::T, η::T, vpl::T, f0::T, v0::T,
    ) where {T<:Number, SE<:StateEvolutionLaw}
    ψ1 = exp((f0 + b * log(v0 * clamp(θ, zero(T), Inf) / L)) / a) / 2v0
    ψ2 = σ * ψ1 / sqrt(1 + (v * ψ1)^2)
    dμdv = a * ψ2
    dμdθ = b / θ * v * ψ2
    dθdt = dθ_dt(se, v, θ, L)
    dτdt = dτ_dt(k, v, vpl)
    return dv_dt(dτdt, dμdv, dμdθ, dθdt, η), dθdt
end

"""
    assemble(p::SingleDofRSFProperty, u0::AbstractArray, tspan::NTuple; flf::FrictionLawForm=CForm(), se::StateEvolutionLaw=DieterichStateLaw())

Assemble the `ODEProblem` for single degree of freedom system.

## Arguments
- `p::SingleDofRSFProperty`: all system properties
- `u0::AbstractArray`: initial condition
- `tspan::NTuple`: time span for simulation
- `flf::FrictionLawForm`: form of friction law, either [`CForm`](@ref) or [`RForm`](@ref)
- `se::StateEvolutionLaw`: state evolutional law, see [`StateEvolutionLaw`](@ref)
"""
function assemble(p::SingleDofRSFProperty, u0::AbstractArray, tspan::NTuple;
    flf::FrictionLawForm=CForm(), se::StateEvolutionLaw=DieterichStateLaw()) where T<:Real
    (typeof(flf) == RForm && p.η ≈ 0) && @warn "Regularized form requires nonzero `η` to avoid `Inf` in dv/dt."
    op! = (du, u, p, t) -> du .= dv_dθ_dt(flf, se, u[1], u[2], p.a, p.b, p.L, p.k, p.σ, p.η, p.vpl, p.f0, p.v0)
    return ODEProblem(op!, u0, tspan, p)
end

## elastic okada system
"""
In-place version of derivative of *velocity* and *state* for a block of fault
patches. This only supports single *state* variable.
"""
@inline function dv_dθ_dt!(::CForm, se::StateEvolutionLaw,
    dv::T, dθ::T, v::T, θ::T, p::ElasticRSFProperty, alloc::OkadaGFAllocation
    ) where {T<:AbstractVecOrMat}
    @fastmath @inbounds @threads for i = 1: prod(alloc.dims)
        dμ_dθ = p.σ[i] * p.b[i] / θ[i]
        dμ_dv = p.σ[i] * p.a[i] / v[i]
        dθ[i] = dθ_dt(se, v[i], θ[i], p.L[i])
        dv[i] = dv_dt(alloc.dτ_dt[i], dμ_dv, dμ_dθ, dθ[i], p.η)
    end
end

@inline function dv_dθ_dt!(::RForm, se::StateEvolutionLaw,
    dv::T, dθ::T, v::T, θ::T, p::ElasticRSFProperty, alloc::OkadaGFAllocation
    ) where {T<:AbstractVecOrMat}
    @fastmath @inbounds @threads for i = 1: prod(alloc.dims)
        ψ1 = exp((p.f0 + p.b[i] * log(p.v0 * θ[i] / p.L[i])) / p.a[i]) / 2p.v0
        ψ2 = p.σ[i] * ψ1 / hypot(1, v[i] * ψ1)
        dμ_dv = p.a[i] * ψ2
        dμ_dθ = p.b[i] / θ[i] * v[i] * ψ2
        dθ[i] = dθ_dt(se, v[i], θ[i], p.L[i])
        dv[i] = dv_dt(alloc.dτ_dt[i], dμ_dv, dμ_dθ, dθ[i], p.η)
    end
end

@generated function (∂u∂t)(du::AbstractArray{T}, u::AbstractArray{T}, p::ElasticRSFProperty, alloc::OkadaGFAllocation{N}, gf::AbstractArray, flf::FrictionLawForm, se::StateEvolutionLaw
    ) where {T, N}
    quote
        v = selectdim(u, $(N+1), 1)
        θ = selectdim(u, $(N+1), 2)
        dv = selectdim(du, $(N+1), 1)
        dθ = selectdim(du, $(N+1), 2)
        clamp!(θ, zero(T), Inf)
        dτ_dt!(gf, alloc, p.vpl, v)
        dv_dθ_dt!(flf, se, dv, dθ, v, θ, p, alloc)
    end
end
"""
    assemble(fs::OkadaFaultSpace, p::ElasticRSFProperty, u0::AbstractArray, tspan::NTuple{2}; flf::FrictionLawForm=RForm(), se::StateEvolutionLaw=DieterichStateLaw(), kwargs...)

Assemble the `ODEProblem` for elastic fault using okada's green's function.

## Arguments
- `fs::OkadaFaultSpace`: fault space containing fault plane mesh and fault type
- `p::ElasticRSFProperty`: all system properties
- `u0::AbstractArray`: initial condition
- `tspan::NTuple`: time span for simulation
- `flf::FrictionLawForm`: form of friction law, either [`CForm`](@ref) or [`RForm`](@ref)
- `se::StateEvolutionLaw`: state evolutional law, see [`StateEvolutionLaw`](@ref)
"""
function assemble(
    fs::OkadaFaultSpace, p::ElasticRSFProperty, u0::AbstractArray, tspan::NTuple{2};
    flf::FrictionLawForm=RForm(), se::StateEvolutionLaw=DieterichStateLaw(), kwargs...
    )
    gf = okada_disp_gf_tensor(fs.mesh, p.λ, p.μ, fs.ft; kwargs...)
    return assemble(gf, fs, p, u0, tspan; flf=flf, se=se), gf
end

"""Assemble the homogeneous elastic system, given green's function `gf::AbstractArray` without recomputing."""
function assemble(
    gf::AbstractArray, fs::OkadaFaultSpace, p::ElasticRSFProperty, u0::AbstractArray, tspan::NTuple{2};
    flf::FrictionLawForm=RForm(), se::StateEvolutionLaw=DieterichStateLaw(),
    )
    alloc = gen_alloc(fs.mesh)
    f! = (du, u, p, t) -> ∂u∂t(du, u, p, alloc, gf, flf, se)
    return ODEProblem(f!, u0, tspan, p)
end