function isolation(max_infection_symptom::Int8,
    max_age_range::Int8 = Int8(5),
    max_group_risk::Int8 = Int8(2), 
    max_infection_known::Int8 = Int8(3),
    number_restrictions::Int8 = Int8(8),
    days::Int16 = Int16(300) )

    social_isolation = ones(Int8,
        max_age_range, 
        max_group_risk,
        max_infection_known, 
        max_infection_symptom, 
        days 
    )

    #This, in the fure, most be a random (o imported) politics.

    """
    s = social_isolation[age_range, group_risk, infection_known, 
    infection_symptom, t] represents the value (beeing from 1 up to 6), of the 
    social restrictionsapplied to the group with demography "age_range" and 
    "group_risk", health conditions "infection_known" and "infection_symptom" 
    at day "t". The value "s = social_isolation(...)" means

        1 = no restrictions to population
        2 = higienics reforced
        3 = social distacing
        4 = quarantine
        5 = isolation 
        6 = strong isolation with severe penalties for violations

    See Contagion_loader for further details.
    """

    general_isolation = ones(Int8, 
        max_infection_known, 
        max_infection_symptom, 
        number_restrictions - 1, days
    )

    """
    general_isolation[infection_known, infection_symptom, restriction - 1, t]
    represents the value (beeing from 1 up to 3), of the "restriction"
    applied to the group with health conditions "infection_known" and 
    "infection_symptom" at day "t". 
    
    The value can be 1 = no restriction, 2 = partial and 3 = full restriction.
    """

    #This, in the fure, most be a random (o imported) politics.

    return social_isolation, general_isolation
end
    