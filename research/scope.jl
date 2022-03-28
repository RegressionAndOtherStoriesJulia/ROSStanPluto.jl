k = 0
k |> display

function inc_k(k)
    k = 0
    for i = 1:10
        k += 1
    end
    k
end

inc_k(k) |> display
k |> display