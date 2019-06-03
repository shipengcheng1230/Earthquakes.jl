module JuEQ

using Reexport

@reexport using OrdinaryDiffEq
@reexport using DiffEqCallbacks

using Parameters
using Requires
using FFTW
using FFTW: Plan
using PhysicalConstants

using Distributed
using Base.Threads
using LinearAlgebra
using SharedArrays
using ProgressMeter

include("configuration.jl")
include("property.jl")
include("rate_state.jl")
include("rheology.jl")
include("basic_mesh.jl")
include("fault.jl")
include("gf.jl")
include("assemble.jl")

include("tools/maxvelocity.jl")
include("tools/mmapsave.jl")

function __init__()
    @require HDF5="f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f" begin
        using .HDF5
        include("tools/h5savecallback.jl")
        include("tools/h5saveprop.jl")
    end

    @require GmshTools="82e2f556-b1bd-5f1a-9576-f93c0da5f0ee" begin
        using .GmshTools
        include("tools/gmshtools.jl")
    end

    @require PyPlot="d330b81b-6aea-500a-939a-2ce795aea3ee" begin
        using .PyPlot
        include("tools/pyplottools.jl")
    end
end

end # module
