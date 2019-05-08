export @h5savecallback

macro h5savecallback(filename, tend, nsteps, usize, T)
    callback = gensym(:callback)
    nd = eval(:(length($(usize))))
    esc(quote
        let count = 1
            global $(callback)
            accu = Array{$T}(undef, $(usize)..., $(nsteps))
            accusize = tuple($(usize)..., $(nsteps))
            acct = Vector{$T}(undef, $(nsteps))
            acctsize = ($(nsteps),)
            total = 0
            h5open($(filename), "w") do fid
                d = d_create(fid, "u", $(T), (accusize, ntuple(_ -> -1, Val($(nd+1)))), "chunk", accusize)
                d = d_create(fid, "t", $(T), (acctsize, (-1,)), "chunk", acctsize)
            end

            function $(callback)(u, t, integrator)
                if t == $(tend)
                    rest = total % $(nsteps)
                    selectdim(accu, $(nd+1), count) .= u
                    selectdim(acct, 1, count) .= t
                    h5open($filename, "r+") do f
                        d = d_open(f, "u")
                        d[$((:(:) for _ in 1: nd)...), total-rest+1: total+1] = selectdim(accu, $(nd+1), 1: rest+1)
                        set_dims!(d, ($(usize)..., total+1))

                        ht = d_open(f, "t")
                        ht[total-rest+1: total+1] = selectdim(acct, 1, 1: rest+1)
                        set_dims!(ht, (total+1,))
                    end
                elseif count > $(nsteps)
                    h5open($filename, "r+") do f
                        d = d_open(f, "u")
                        d[$((:(:) for _ in 1: nd)...), total-$(nsteps-1): total] = accu
                        set_dims!(d, ($(usize)..., total+$(nsteps)))

                        ht = d_open(f, "t")
                        ht[total-$(nsteps-1): total] = acct
                        set_dims!(ht, (total+$(nsteps),))
                    end
                    selectdim(accu, $(nd+1), 1) .= u
                    selectdim(acct, 1, 1) .= t
                    count = 2
                    total += 1
                else
                    selectdim(accu, $(nd+1), count) .= u
                    selectdim(acct, 1, count) .= t
                    count += 1
                    total += 1
                end
            end

            FunctionCallingCallback($(callback); func_everystep=true)
        end
    end)
end