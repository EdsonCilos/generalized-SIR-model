using DelimitedFiles

function load(file_name::String, format::String = ".csv")
   
    return readdlm(string(joinpath("models","UFSC_SIR","data",file_name),format), 
    ';', 
    Float64)

    """
    We suppose that all file's lines contains the same number of seperators 
    given by ";". That is, it is a regular matrix
    """
end
