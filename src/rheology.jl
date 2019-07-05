## plastic deformation
export DislocationCreep, DiffusionCreep, Peierls

abstract type DeformationMechanism end

# Karato 2008, Deformation of Earth Materials
@doc raw"""
```math
\dot{ϵ} = A σ′ d^{-m} f_{\mathrm{H}_{2}\mathrm{O}} ^{r} \exp{\left(αϕ\right)} \exp{\left(- \frac{Q + PV}{RT}\right)}
```
"""
struct DiffusionCreep <: DeformationMechanism end

@doc raw"""
```math
\dot{ϵ} = A τ^{n-1} σ′ f_{\mathrm{H}_{2}\mathrm{O}} ^{r} \exp{\left(αϕ\right)} \exp{\left(- \frac{Q + PV}{RT}\right)}
```
"""
struct DislocationCreep <: DeformationMechanism end

@doc raw"""
```math
\dot{ϵ} = \dot{ϵ_{P}}\left(\frac{σ}{G}\right)^{2} \exp{\left(-\frac{ΔF_{k}^{o}}{RT}\left(1 - \left(\frac{σ}{σ_{P}}\right)^{r}\right)^{s}\right)}
```
"""
struct Peierls <: DeformationMechanism end # high stress / low temperature

const 𝙍 = float(PhysicalConstants.CODATA2014.R).val # ideal gas constant

# stress driven plastic deformation
function dϵ_dt(::DislocationCreep, A, σ, τ, n, fH₂0, r, α, ϕ, Q, P, Ω, T)
    A * τ^(n-1) * σ * fH₂0^r * exp(α * ϕ) * exp(-(Q + P * Ω) / 𝙍 / T)
end

function dϵ_dt(::DiffusionCreep, A, σ, d, m, fH₂0, r, α, ϕ, Q, P, Ω, T)
    A * σ * d^(-m) * fH₂0^r * exp(α * ϕ) * exp(-(Q + P * Ω) / 𝙍 / T)
end
