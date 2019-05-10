#-----------------------------------------------------------------------
#  Author: James D. P. Moore (earth@jamesdpmoore.com) - 10 Jun, 2016.
#  Modified: Sylvain Barbot (sbarbot@ntu.edu.sg) -
#  Earth Observatory of Singapore
#  Copyright (c) 2017 James D. P. Moore and Sylvain Barbot
#
#  This code and related code should be cited as:
#    Barbot S., J. D. P. Moore and V. Lambert, Displacement and Stress
#    Associated with Distributed Anelastic Deformation in a Half Space,
#    Bull. Seism. Soc. Am., 107(2), 10.1785/0120160237, 2017.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#-----------------------------------------------------------------------
# Translated by Pengcheng Shi (shipengcheng1230@gmail.com)

# greens function ϵ vs u for tet4 element
export sbarbot_disp_tet4, sbarbot_disp_tet4!
export sbarbot_strain_tet4, sbarbot_strain_tet4!
export sbarbot_stress_tet4, sbarbot_stress_tet4!

function sbarbot_disp_tet4(quadrature::Q,
    x1::R, x2::R, x3::R, A::U, B::U, C::U, D::U,
    e11::R, e12::R, e13::R, e22::R, e23::R, e33::R, nu::R
    ) where {R, U, Q}

    u = Vector{R}(undef, 3)
    sbarbot_disp_tet4!(u, quadrature, x1, x2, x3, A, B, C, D, e11, e12, e13, e22, e23, e33, nu)
    return u
end

"""
                      / North (x1)
                     /
        surface     /
      -------------+-------------- East (x2)
                  /|
                 / |     + A
                /  |    /  .
                   |   /     .
                   |  /        .
                   | /           .
                   |/              + B
                   /            .  |
                  /|          /    |
                 / :       .       |
                /  |    /          |
               /   : .             |
              /   /|               |
             / .   :               |
            +------|---------------+
          C        :                 D
"""
function sbarbot_disp_tet4!(u::W, quadrature::Q,
    x1::R, x2::R, x3::R, A::U, B::U, C::U, D::U,
    e11::R, e12::R, e13::R, e22::R, e23::R, e33::R, nu::R
    ) where {R, U, Q, W}

    lambda = 2 * nu / (1 - 2 * nu)
    ekk = e11 + e22 + e33

    nA = cross(C - B, D - B)
    nB = cross(D - C, A - C)
    nC = cross(A - D, B - D)
    nD = cross(B - A, C - A)

    nA /= norm(nA)
    nB /= norm(nB)
    nC /= norm(nC)
    nD /= norm(nD)

    if nA' * (A .- (B .+ C .+ D) ./ 3) > zero(R); nA *= -one(R) end
    if nB' * (B .- (A .+ C .+ D) ./ 3) > zero(R); nB *= -one(R) end
    if nC' * (C .- (B .+ A .+ D) ./ 3) > zero(R); nC *= -one(R) end
    if nD' * (D .- (B .+ C .+ A) ./ 3) > zero(R); nD *= -one(R) end

    ABC = norm(cross(C .- A, B .- A)) / 2
    BCD = norm(cross(D .- B, C .- B)) / 2
    CDA = norm(cross(A .- C, D .- C)) / 2
    DAB = norm(cross(B .- D, A .- D)) / 2

    m11 = lambda * ekk + 2 * e11
    m12 = 2 * e12
    m13 = 2 * e13
    m22 = lambda * ekk + 2 * e22
    m23 = 2 * e23
    m33 = lambda * ekk + 2 * e33

    let lambda=lambda, x1=x1, x2=x2, x3=x3, A=A, B=B, C=C, D=D, e11=e11, e12=e12, e13=e13, e22=e22, e23=e23, e33=e33, nu=nu, nA=nA, nB=nB, nC=nC, ABC=ABC, BCD=BCD, CDA=CDA, DAB=DAB, m11=m11, m12=m12, m13=m13, m22=m22, m23=m23, m33=m33

        function r1(y1::R, y2::R, y3::R) where R
            hypot(x1 - y1, x2 - y2, x3 - y3)
        end

        function r2(y1::R, y2::R, y3::R) where R
            hypot(x1 - y1, x2 - y2, x3 + y3)
        end

        function G11(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            (3 - 4 * nu) / r1(y1, y2, y3) + 1 / r2(y1, y2, y3) + (x1 - y1) ^ 2 / r1(y1, y2, y3) ^ 3
            + (3 - 4 * nu) * (x1 - y1) ^ 2 / r2(y1, y2, y3) ^ 3 + 2 * x3 * y3 * (r2(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 5
            + 4 * (1 - 2 * nu) * (1 - nu) * (r2(y1, y2, y3) ^ 2 - (x1 - y1) ^ 2 + r2(y1, y2, y3) * (x3 + y3)) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)))
        end

        function G12(y1::R, y2::R, y3::R) where R
            ((x1 - y1) * (x2 - y2) / (16 * π * (1 - nu)) * (
            1  / r1(y1, y2, y3) ^ 3 + (3 - 4 * nu) / r2(y1, y2, y3) ^ 3 - 6 * x3 * y3 / r2(y1, y2, y3) ^ 5
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)))
        end

        function G13(y1::R, y2::R, y3::R) where R
            ((x1 - y1) /(16*π*(1-nu)) *(
              (x3 - y3) / r1(y1, y2, y3) ^ 3 + (3 - 4 * nu) * (x3 - y3) / r2(y1, y2, y3) ^ 3
            -6 * x3 * y3 * (x3 + y3) / r2(y1, y2, y3) ^ 5 + 4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))))
        end

        function G21(y1::R, y2::R, y3::R) where R
            ((x1 - y1) * (x2 - y2) / (16 * π * (1 - nu)) * (
            1  / r1(y1, y2, y3) ^ 3 + (3 - 4 * nu) / r2(y1, y2, y3) ^ 3 - 6 * x3 * y3 / r2(y1, y2, y3) ^ 5
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)))
        end

        function G22(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            (3 - 4 * nu) / r1(y1, y2, y3) + 1  / r2(y1, y2, y3) + (x2 - y2) ^ 2  / r1(y1, y2, y3) ^ 3
            +(3 - 4 * nu) * (x2 - y2) ^ 2  / r2(y1, y2, y3) ^ 3 + 2 * x3 * y3 * (r2(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 5
            +4 * (1 - 2 * nu) * (1 - nu) * (r2(y1, y2, y3) ^ 2 - (x2 - y2) ^ 2 + r2(y1, y2, y3) * (x3 + y3)) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)))
        end

        function G23(y1::R, y2::R, y3::R) where R
            ((x2 - y2) /(16*π*(1-nu)) *(
              (x3 - y3) / r1(y1, y2, y3) ^ 3 + (3 - 4 * nu) * (x3 - y3) / r2(y1, y2, y3) ^ 3
            -6 * x3 * y3 * (x3 + y3) / r2(y1, y2, y3) ^ 5 + 4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))))
        end

        function G31(y1::R, y2::R, y3::R) where R
            ((x1 - y1) /(16*π*(1-nu)) *(
              (x3 - y3) / r1(y1, y2, y3) ^ 3 + (3 - 4 * nu) * (x3 - y3) / r2(y1, y2, y3) ^ 3
            +6 * x3 * y3 * (x3 + y3) / r2(y1, y2, y3) ^ 5 - 4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))))
        end

        function G32(y1::R, y2::R, y3::R) where R
            ((x2 - y2) /(16*π*(1-nu)) *(
              (x3 - y3) / r1(y1, y2, y3) ^ 3 + (3 - 4 * nu) * (x3 - y3) / r2(y1, y2, y3) ^ 3
            +6 * x3 * y3 * (x3 + y3) / r2(y1, y2, y3) ^ 5 - 4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))))
        end

        function G33(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            (3 - 4 * nu) / r1(y1, y2, y3) + (5 - 12 * nu + 8 * nu ^ 2) / r2(y1, y2, y3) + (x3 - y3) ^ 2  / r1(y1, y2, y3) ^ 3
            +6 * x3 * y3 * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 5 + ((3 - 4 * nu) * (x3 + y3) ^ 2 - 2 * x3 * y3) / r2(y1, y2, y3) ^ 3))
        end

        function y(u::R, v::R, A::R, B::R, C::R) where R
            A * (1 - u) * (1 - v) / 4 + B * (1 + u) * (1 - v) / 4 + C * (1 + v) / 2
        end

        function IU1(u::R, v::R) where R
            (ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G11(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G21(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G31(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G11(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G21(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G31(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G11(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G21(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G31(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G11(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
                + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G21(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
                + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G31(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU2(u::R, v::R) where R
            (ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G12(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G22(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G32(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G12(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G22(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G32(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G12(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G22(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G32(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G12(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
                + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G22(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
                + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G32(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU3(u::R, v::R) where R
            (ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G13(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G23(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G33(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
                + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G13(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G23(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G33(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
                + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G13(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G23(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G33(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
                + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G13(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
                + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G23(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
                + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G33(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        fill!(u, zero(R))
        x, w = quadrature
        @inbounds @fastmath for k = 1: length(x)
            @simd for j = 1: length(x)
                u[1] += w[j] * w[k] * (1 - x[k]) * IU1(x[j], x[k])
                u[2] += w[j] * w[k] * (1 - x[k]) * IU2(x[j], x[k])
                u[3] += w[j] * w[k] * (1 - x[k]) * IU3(x[j], x[k])
            end
        end

        return nothing
    end
end

function sbarbot_stress_tet4(quadrature::Q,
    x1::R, x2::R, x3::R, A::U, B::U, C::U, D::U,
    e11::R, e12::R, e13::R, e22::R, e23::R, e33::R, G::R, nu::R
    ) where {R, U, Q}

    u = Vector{R}(undef, 6)
    sbarbot_stress_tet4!(u, quadrature, x1, x2, x3, A, B, C, D, e11, e12, e13, e22, e23, e33, G, nu)
    return u
end

function sbarbot_stress_tet4!(u::W, quadrature::Q,
    x1::R, x2::R, x3::R, A::U, B::U, C::U, D::U,
    e11::R, e12::R, e13::R, e22::R, e23::R, e33::R, G::R, nu::R
    ) where {R, U, Q, W}

    sbarbot_strain_tet4!(u, quadrature, x1, x2, x3, A, B, C, D, e11, e12, e13, e22, e23, e33, G, nu)

    lambda = 2 * nu / (1 - 2 * nu)
    ekk = u[1] + u[4] + u[6]
    u[1] = 2G * u[1] + G * lambda * ekk
    u[2] *= 2G
    u[3] *= 2G
    u[4] = 2G * u[4] + G * lambda * ekk
    u[5] *= 2G
    u[6] = 2G * u[6] + G * lambda * ekk

    return nothing
end

function sbarbot_strain_tet4(quadrature::Q,
    x1::R, x2::R, x3::R, A::U, B::U, C::U, D::U,
    e11::R, e12::R, e13::R, e22::R, e23::R, e33::R, G::R, nu::R
    ) where {R, U, Q}

    u = Vector{R}(undef, 6)
    sbarbot_strain_tet4!(u, quadrature, x1, x2, x3, A, B, C, D, e11, e12, e13, e22, e23, e33, G, nu)
    return u
end

function sbarbot_strain_tet4!(u::W, quadrature::Q,
    x1::R, x2::R, x3::R, A::U, B::U, C::U, D::U,
    e11::R, e12::R, e13::R, e22::R, e23::R, e33::R, G::R, nu::R
    ) where {R, U, Q, W}

    lambda = 2 * nu / (1 - 2 * nu)
    ekk = e11 + e22 + e33

    nA = cross(C - B, D - B)
    nB = cross(D - C, A - C)
    nC = cross(A - D, B - D)
    nD = cross(B - A, C - A)

    nA /= norm(nA)
    nB /= norm(nB)
    nC /= norm(nC)
    nD /= norm(nD)

    if nA' * (A .- (B .+ C .+ D) ./ 3) > zero(R); nA *= -one(R) end
    if nB' * (B .- (A .+ C .+ D) ./ 3) > zero(R); nB *= -one(R) end
    if nC' * (C .- (B .+ A .+ D) ./ 3) > zero(R); nC *= -one(R) end
    if nD' * (D .- (B .+ C .+ A) ./ 3) > zero(R); nD *= -one(R) end

    ABC = norm(cross(C .- A, B .- A)) / 2
    BCD = norm(cross(D .- B, C .- B)) / 2
    CDA = norm(cross(A .- C, D .- C)) / 2
    DAB = norm(cross(B .- D, A .- D)) / 2

    m11 = lambda * ekk + 2 * e11
    m12 = 2 * e12
    m13 = 2 * e13
    m22 = lambda * ekk + 2 * e22
    m23 = 2 * e23
    m33 = lambda * ekk + 2 * e33

    let lambda=lambda, x1=x1, x2=x2, x3=x3, A=A, B=B, C=C, D=D, e11=e11, e12=e12, e13=e13, e22=e22, e23=e23, e33=e33, G=G, nu=nu, nA=nA, nB=nB, nC=nC, ABC=ABC, BCD=BCD, CDA=CDA, DAB=DAB, m11=m11, m12=m12, m13=m13, m22=m22, m23=m23, m33=m33

        function r1(y1::R, y2::R, y3::R) where R
            hypot(x1 - y1, x2 - y2, x3 - y3)
        end

        function r2(y1::R, y2::R, y3::R) where R
            hypot(x1 - y1, x2 - y2, x3 + y3)
        end

        function y(u::R, v::R, A::R, B::R, C::R) where R
            A * (1 - u) * (1 - v) / 4 + B * (1 + u) * (1 - v) / 4 + C * (1 + v) / 2
        end

        function G11d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (
            -(3 - 4 * nu) / r1(y1, y2, y3) ^ 3
            -1  / r2(y1, y2, y3) ^ 3
            +(2 * r1(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (2 * r2(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (3 * r2(y1, y2, y3) ^ 2 - 5 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            -8 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +4 * (1 - 2 * nu) * (1 - nu) * (x1 - y1) ^ 2  / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +8 * (1 - 2 * nu) * (1 - nu) * (x1 - y1) ^ 2  / (r2(y1, y2, y3) ^ 2  * (r2(y1, y2, y3) + x3 + y3) ^ 3) );)
        end

        function G11d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x2 - y2) * (
            -(3 - 4 * nu) / r1(y1, y2, y3) ^ 3
            -1  / r2(y1, y2, y3) ^ 3
            -3 * (x1 - y1) ^ 2  / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x1 - y1) ^ 2  / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (r2(y1, y2, y3) ^ 2 - 5 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +4 * (1 - 2 * nu) * (1 - nu) * (x1 - y1) ^ 2  * (3 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 3) ))
        end

        function G11d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            -(3 - 4 * nu) * (x3 - y3) / r1(y1, y2, y3) ^ 3
            -(x3 + y3) / r2(y1, y2, y3) ^ 3
            -3 * (x1 - y1) ^ 2  * (x3 - y3) / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x1 - y1) ^ 2  * (x3 + y3) / r2(y1, y2, y3) ^ 5
            +2 * y3 * (r2(y1, y2, y3) ^ 2 - 3 * x3 * (x3 + y3)) / r2(y1, y2, y3) ^ 5
            -6 * y3 * (x1 - y1) ^ 2  * (r2(y1, y2, y3) ^ 2 - 5 * x3 * (x3 + y3)) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))
            +4 * (1 - 2 * nu) * (1 - nu) * (x1 - y1) ^ 2  * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G21d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x2 - y2) * (
            +(r1(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (r2(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (r2(y1, y2, y3) ^ 2 - 5 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +4 * (1 - 2 * nu) * (1 - nu) * (x1 - y1) ^ 2  * (3 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 3) ))
        end

        function G21d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (
            +(r1(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (r2(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (r2(y1, y2, y3) ^ 2 - 5 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +4 * (1 - 2 * nu) * (1 - nu) * (x2 - y2) ^ 2  * (3 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 3) ))
        end

        function G21d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (x2 - y2) * (
            -3 * (x3 - y3) / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x3 + y3) / r2(y1, y2, y3) ^ 5
            -6 * y3 * (r2(y1, y2, y3) ^ 2 - 5 * x3 * (x3 + y3)) / r2(y1, y2, y3) ^ 7
            +4 * (1 - 2 * nu) * (1 - nu) * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G31d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            +(x3 - y3) * (r1(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (x3 - y3) * (r2(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 5
            +6 * y3 * x3 * (x3 + y3) * (r2(y1, y2, y3) ^ 2 - 5 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))
            +4 * (1 - 2 * nu) * (1 - nu) * (x1 - y1) ^ 2  * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G31d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (x2 - y2) * (
            -3 * (x3 - y3) / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x3 - y3) / r2(y1, y2, y3) ^ 5
            -30 * y3 * x3 * (x3 + y3) / r2(y1, y2, y3) ^ 7
            +4 * (1 - 2 * nu) * (1 - nu) * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G31d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (
            +(r1(y1, y2, y3) ^ 2 - 3 * (x3 - y3) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (r2(y1, y2, y3) ^ 2 - 3 * (x3 ^ 2 - y3 ^ 2)) / r2(y1, y2, y3) ^ 5
            +6 * y3 * (2 * x3 + y3) / r2(y1, y2, y3) ^ 5
            -30 * y3 * x3 * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 7
            +4 * (1 - 2 * nu) * (1 - nu) / r2(y1, y2, y3) ^ 3 ))
        end

        function G12d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x2 - y2) * (
            +(r1(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (r2(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (r2(y1, y2, y3) ^ 2 - 5 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - nu) * (1 - 2 * nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +4 * (1 - nu) * (1 - 2 * nu) * (x1 - y1) ^ 2  * (3 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 3) ))
        end

        function G12d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (
            +(r1(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (r2(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (r2(y1, y2, y3) ^ 2 - 5 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - nu) * (1 - 2 * nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +4 * (1 - nu) * (1 - 2 * nu) * (x2 - y2) ^ 2  * (3 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 3) ))
        end

        function G12d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (x2 - y2) * (
            -3 * (x3 - y3) / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x3 + y3) / r2(y1, y2, y3) ^ 5
            -6 * y3 * (r2(y1, y2, y3) ^ 2 - 5 * x3 * (x3 + y3)) / r2(y1, y2, y3) ^ 7
            +4 * (1 - 2 * nu) * (1 - nu) * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G22d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (
            -(3 - 4 * nu) / r1(y1, y2, y3) ^ 3
            -1  / r2(y1, y2, y3) ^ 3
            -3 * (x2 - y2) ^ 2  / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x2 - y2) ^ 2  / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (r2(y1, y2, y3) ^ 2 - 5 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +4 * (1 - 2 * nu) * (1 - nu) * (x2 - y2) ^ 2  * (3 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 3) ))
        end

        function G22d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x2 - y2) * (
            -(3 - 4 * nu) / r1(y1, y2, y3) ^ 3
            -1  / r2(y1, y2, y3) ^ 3
            +(2 * r1(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (2 * r2(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (3 * r2(y1, y2, y3) ^ 2 - 5 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 7
            -12 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3) ^ 2)
            +4 * (1 - 2 * nu) * (1 - nu) * (x2 - y2) ^ 2  * (3 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 3) ))
        end

        function G22d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            -(3 - 4 * nu) * (x3 - y3) / r1(y1, y2, y3) ^ 3
            -(x3 + y3) / r2(y1, y2, y3) ^ 3
            -3 * (x2 - y2) ^ 2  * (x3 - y3) / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x2 - y2) ^ 2  * (x3 + y3) / r2(y1, y2, y3) ^ 5
            +2 * y3 * (r2(y1, y2, y3) ^ 2 - 3 * x3 * (x3 + y3)) / r2(y1, y2, y3) ^ 5
            -6 * y3 * (x2 - y2) ^ 2  * (r2(y1, y2, y3) ^ 2 - 5 * x3 * (x3 + y3)) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))
            +4 * (1 - 2 * nu) * (1 - nu) * (x2 - y2) ^ 2  * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G32d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (x2 - y2) * (
            -3 * (x3 - y3) / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x3 - y3) / r2(y1, y2, y3) ^ 5
            -30 * y3 * x3 * (x3 + y3) / r2(y1, y2, y3) ^ 7
            +4 * (1 - 2 * nu) * (1 - nu) * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G32d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            +(x3 - y3) * (r1(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (x3 - y3) * (r2(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 5
            +6 * y3 * x3 * (x3 + y3) * (r2(y1, y2, y3) ^ 2 - 5 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))
            +4 * (1 - 2 * nu) * (1 - nu) * (x2 - y2) ^ 2  * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G32d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x2 - y2) * (
            +(r1(y1, y2, y3) ^ 2 - 3 * (x3 - y3) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (r2(y1, y2, y3) ^ 2 - 3 * (x3 ^ 2 - y3 ^ 2)) / r2(y1, y2, y3) ^ 5
            +6 * y3 * (2 * x3 + y3) / r2(y1, y2, y3) ^ 5
            -30 * y3 * x3 * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 7
            +4 * (1 - 2 * nu) * (1 - nu) / r2(y1, y2, y3) ^ 3 ))
        end

        function G13d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            +(x3 - y3) * (r1(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (x3 - y3) * (r2(y1, y2, y3) ^ 2 - 3 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (x3 + y3) * (r2(y1, y2, y3) ^ 2 - 5 * (x1 - y1) ^ 2) / r2(y1, y2, y3) ^ 7
            +4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))
            -4 * (1 - 2 * nu) * (1 - nu) * (x1 - y1) ^ 2  * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G13d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (x2 - y2) * (
            -3 * (x3 - y3) / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x3 - y3) / r2(y1, y2, y3) ^ 5
            +30 * y3 * x3 * (x3 + y3) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G13d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (
            +(r1(y1, y2, y3) ^ 2 - 3 * (x3 - y3) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (r2(y1, y2, y3) ^ 2 - 3 * (x3 ^ 2 - y3 ^ 2)) / r2(y1, y2, y3) ^ 5
            -6 * y3 * (2 * x3 + y3) / r2(y1, y2, y3) ^ 5
            +30 * y3 * x3 * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / r2(y1, y2, y3) ^ 3 ))
        end

        function G23d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (x2 - y2) * (
            -3 * (x3 - y3) / r1(y1, y2, y3) ^ 5
            -3 * (3 - 4 * nu) * (x3 - y3) / r2(y1, y2, y3) ^ 5
            +30 * y3 * x3 * (x3 + y3) / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G23d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            +(x3 - y3) * (r1(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (x3 - y3) * (r2(y1, y2, y3) ^ 2 - 3 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 5
            -6 * y3 * x3 * (x3 + y3) * (r2(y1, y2, y3) ^ 2 - 5 * (x2 - y2) ^ 2) / r2(y1, y2, y3) ^ 7
            +4 * (1 - 2 * nu) * (1 - nu) / (r2(y1, y2, y3) * (r2(y1, y2, y3) + x3 + y3))
            -4 * (1 - 2 * nu) * (1 - nu) * (x2 - y2) ^ 2  * (2 * r2(y1, y2, y3) + x3 + y3) / (r2(y1, y2, y3) ^ 3  * (r2(y1, y2, y3) + x3 + y3) ^ 2) ))
        end

        function G23d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x2 - y2) * (
            +(r1(y1, y2, y3) ^ 2 - 3 * (x3 - y3) ^ 2) / r1(y1, y2, y3) ^ 5
            +(3 - 4 * nu) * (r2(y1, y2, y3) ^ 2 - 3 * (x3 ^ 2 - y3 ^ 2)) / r2(y1, y2, y3) ^ 5
            -6 * y3 * (2 * x3 + y3) / r2(y1, y2, y3) ^ 5
            +30 * y3 * x3 * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 7
            -4 * (1 - 2 * nu) * (1 - nu) / r2(y1, y2, y3) ^ 3 ))
        end

        function G33d1(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x1 - y1) * (
            -(3 - 4 * nu) / r1(y1, y2, y3) ^ 3
            -(5 - 12 * nu + 8 * nu ^ 2) / r2(y1, y2, y3) ^ 3
            -3 * (x3 - y3) ^ 2  / r1(y1, y2, y3) ^ 5
            -30 * y3 * x3 * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 7
            -3 * (3 - 4 * nu) * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 5
            +6 * y3 * x3 / r2(y1, y2, y3) ^ 5 ))
        end

        function G33d2(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (x2 - y2) * (
            -(3 - 4 * nu) / r1(y1, y2, y3) ^ 3
            -(5 - 12 * nu + 8 * nu ^ 2) / r2(y1, y2, y3) ^ 3
            -3 * (x3 - y3) ^ 2  / r1(y1, y2, y3) ^ 5
            -30 * y3 * x3 * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 7
            -3 * (3 - 4 * nu) * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 5
            +6 * y3 * x3 / r2(y1, y2, y3) ^ 5 ))
        end

        function G33d3(y1::R, y2::R, y3::R) where R
            (1 / (16 * π * (1 - nu)) * (
            -(3 - 4 * nu) * (x3 - y3) / r1(y1, y2, y3) ^ 3
            -(5 - 12 * nu + 8 * nu ^ 2) * (x3 + y3) / r2(y1, y2, y3) ^ 3
            +(x3 - y3) * (2 * r1(y1, y2, y3) ^ 2 - 3 * (x3 - y3) ^ 2) / r1(y1, y2, y3) ^ 5
            +6 * y3 * (x3 + y3) ^ 2  / r2(y1, y2, y3) ^ 5
            +6 * y3 * x3 * (x3 + y3) * (2 * r2(y1, y2, y3) ^ 2 - 5 * (x3 + y3) ^ 2) / r2(y1, y2, y3) ^ 7
            +(3 - 4 * nu) * (x3 + y3) * (2 * r2(y1, y2, y3) ^ 2 - 3 * (x3 + y3) ^ 2) / r2(y1, y2, y3) ^ 5
            -2 * y3 * (r2(y1, y2, y3) ^ 2 - 3 * x3 * (x3 + y3)) / r2(y1, y2, y3) ^ 5 ))
        end

        function IU11(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G11d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G21d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G31d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G11d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G21d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G31d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G11d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G21d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G31d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G11d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G21d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G31d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU12(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G11d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G21d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G31d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G11d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G21d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G31d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G11d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G21d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G31d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G11d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G21d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G31d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU13(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G11d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G21d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G31d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G11d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G21d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G31d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G11d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G21d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G31d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G11d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G21d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G31d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU21(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G12d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G22d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G32d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G12d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G22d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G32d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G12d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G22d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G32d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G12d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G22d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G32d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU22(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G12d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G22d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G32d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G12d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G22d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G32d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G12d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G22d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G32d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G12d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G22d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G32d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU23(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G12d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G22d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G32d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G12d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G22d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G32d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G12d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G22d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G32d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G12d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G22d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G32d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU31(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G13d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G23d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G33d1(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G13d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G23d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G33d1(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G13d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G23d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G33d1(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G13d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G23d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G33d1(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU32(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G13d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G23d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G33d2(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G13d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G23d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G33d2(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G13d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G23d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G33d2(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G13d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G23d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G33d2(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        function IU33(u::R, v::R) where R
            (+ ABC / 4 * (m11 * nD[1] + m12 * nD[2] + m13 * nD[3]) * G13d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m12 * nD[1] + m22 * nD[2] + m23 * nD[3]) * G23d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + ABC / 4 * (m13 * nD[1] + m23 * nD[2] + m33 * nD[3]) * G33d3(y(u, v, A[1], B[1], C[1]), y(u, v, A[2], B[2], C[2]), y(u, v, A[3], B[3], C[3]))
            + BCD / 4 * (m11 * nA[1] + m12 * nA[2] + m13 * nA[3]) * G13d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m12 * nA[1] + m22 * nA[2] + m23 * nA[3]) * G23d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + BCD / 4 * (m13 * nA[1] + m23 * nA[2] + m33 * nA[3]) * G33d3(y(u, v, B[1], C[1], D[1]), y(u, v, B[2], C[2], D[2]), y(u, v, B[3], C[3], D[3]))
            + CDA / 4 * (m11 * nB[1] + m12 * nB[2] + m13 * nB[3]) * G13d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m12 * nB[1] + m22 * nB[2] + m23 * nB[3]) * G23d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + CDA / 4 * (m13 * nB[1] + m23 * nB[2] + m33 * nB[3]) * G33d3(y(u, v, C[1], D[1], A[1]), y(u, v, C[2], D[2], A[2]), y(u, v, C[3], D[3], A[3]))
            + DAB / 4 * (m11 * nC[1] + m12 * nC[2] + m13 * nC[3]) * G13d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m12 * nC[1] + m22 * nC[2] + m23 * nC[3]) * G23d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3]))
            + DAB / 4 * (m13 * nC[1] + m23 * nC[2] + m33 * nC[3]) * G33d3(y(u, v, D[1], A[1], B[1]), y(u, v, D[2], A[2], B[2]), y(u, v, D[3], A[3], B[3])))
        end

        u11, u12, u13, u21, u22, u23, u31, u32, u33 = zero(R), zero(R), zero(R), zero(R), zero(R), zero(R), zero(R), zero(R), zero(R)

        x, w = quadrature
        @inbounds @fastmath for k = 1: length(x)
            @simd for j = 1: length(x)
                c = w[j] * w[k] * (1 - x[k])
                u11 += c * IU11(x[j], x[k])
                u12 += c * IU12(x[j], x[k])
                u13 += c * IU13(x[j], x[k])
                u21 += c * IU21(x[j], x[k])
                u22 += c * IU22(x[j], x[k])
                u23 += c * IU23(x[j], x[k])
                u31 += c * IU31(x[j], x[k])
                u32 += c * IU32(x[j], x[k])
                u33 += c * IU33(x[j], x[k])
            end
        end

        omega =
            (heaviside(((A[1] + B[1] + C[1]) / 3 - x1) * nD[1] + ((A[2] + B[2] + C[2]) / 3 - x2) * nD[2] + ((A[3] + B[3] + C[3]) / 3 - x3) * nD[3])
            * heaviside(((B[1] + C[1] + D[1]) / 3 - x1) * nA[1] + ((B[2] + C[2] + D[2]) / 3 - x2) * nA[2] + ((B[3] + C[3] + D[3]) / 3 - x3) * nA[3])
            * heaviside(((C[1] + D[1] + A[1]) / 3 - x1) * nB[1] + ((C[2] + D[2] + A[2]) / 3 - x2) * nB[2] + ((C[3] + D[3] + A[3]) / 3 - x3) * nB[3])
            * heaviside(((D[1] + A[1] + B[1]) / 3 - x1) * nC[1] + ((D[2] + A[2] + B[2]) / 3 - x2) * nC[2] + ((D[3] + A[3] + B[3]) / 3 - x3) * nC[3]))

        u[1] = u11 - omega * e11
        u[2] = (u12 + u21) / 2 - omega * e12
        u[3] = (u13 + u31) / 2 - omega * e13
        u[4] = u22 - omega * e22
        u[5] = (u23 + u32) / 2 - omega * e23
        u[6] = u33 - omega * e33

        return nothing
    end
end
