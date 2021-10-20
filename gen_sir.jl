include("Initial_data.jl")
include("Dynamic_update.jl")

function main(days::Int16 = Int16(300))
   
    dynamic = initial_data(days)
    
    return dynamic
end
