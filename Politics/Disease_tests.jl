function disease_tests(false_symptoms_days::Int8 = Int8(5), 
    days::Int16 = Int16(300))
    """
    Disease tests 

    test(age_range, risk_group, infection_symptoms, t)

        Represents the ratio of tests (related to the total population) aplied
        to the population with unkown infected state and with infection symptoms
        "infection_symptoms". 

        age_range and risk_group, see load_demografy in Loader.jl

        infection_symptoms: 
    
        1 = Patient without false symptoms
        2 = with false symptoms since 1 day
        3 = with false symptoms since 2 days
    
        ...
    
        false_symptoms_days + 1 = with false symptoms since false_symptoms_days

        Therefore,

        infection_symptoms_max = false_symptoms_days + 1
    """

    #ToDo: generate "random" array
    return Array{Float64}(undef, 5, 3, false_symptoms_days + 1, days)
     #zeros(age_range_max, risk_group_max, infection_symptoms_max, days);
end