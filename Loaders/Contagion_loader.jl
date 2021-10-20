function load_social_contagion(path::String)
    """
    social_contagion

    1 = home
    2 = on the street
    3 = work 
    4 = shopping
    5 = public transport
    6 = classroom
    7 = big events
    8 = hospital
    
    social_contagion_max = 8
"""
    social_contagion = Array{Float64}(undef, 8)
    #Ideally must load from path

    return social_contagion
end

function load_static_correction(path::String, 
    max_housing_area::Int8 = Int8(4), 
    max_social_contagion::Int8 = Int8(8) )
    """
    Matrix of contagion correction based on the demographic characteristics and
    of health condition 

    static_correction[housing_area, social_contagion] represents the 
    correction to the contagion "social_contagion" related to the housing area 
    "housing_area". The new contagion factor will the product between the 
    base factor and the correction. It is called static because it does not 
    depend on goverment choices.
    """
    
    #ToDo: Implement module to import from file.
    static_correction=  Array{Float64}(undef, 
    max_housing_area, max_social_contagion) 

    return static_correction
end

function load_dynamic_correction(path::String,
    max_infection_symptom::Int8,
    max_age_range::Int8 = Int8(5),
    max_group_risk::Int8 = Int8(2),
    max_infection_known::Int8 = Int8(3),
    max_social_contagion::Int8 = Int8(8) )

    """
    Matrix of contagion correction based on the restrictions

    restrictions (index): 

        1 = social restriction
        2 = transport 
        3 = education
        4 = events
        5 = industry
        6 = services
        7 = commerce
        8 = restrictions to other non-essencial economic activities

    Each restriction can assume different values

    1. social_restriction (index)

        1 = no restrictions to population
        2 = higienics reforced
        3 = social distacing
        4 = quarantine
        5 = isolation 
        6 = strong isolation with severe penalties for violations

    The remaining restrictions:

        2. transport_restriction

        3. education_restriction

        4. events_restriction

        5. industry_restriction 

        6. service_restriction

        7. commerce_restriction

        8. other_rescction
    
    Assume only three values:
            
            1 = no restrictions
            2 = partial
            3 = full
    """
    number_restrictions::Int8 = Int8(8)
    max_social_restrictions::Int8 = Int8(6)
    max_restrictions::Int8 = Int8(3)

    social_dynamic_correction = Array{Float64}(undef,
    max_age_range,
    max_group_risk,
    max_infection_known,
    max_infection_symptom,
    max_social_restrictions,
    max_social_contagion)

    #Ideally must load from path

    """
    social_dynamic_correction(age_range, group_risk, infection_known, 
    infection_symptom, social_restriction, social_contagion):
        
        represents the correction to the social contagion "social_contagion" 
        for the group with demography "age_range" and "group_risk", with
        health conditions "infection_known" and "infection_symptom". The 
        social_restriction means the politics adopted.

        See load_demography in Loaders/Demo_grav_loader for further explanations 
        concerning  age_range and group_risk

        See [include reference] for exaplanations about infection_known and
        infection_symptom.
    """

    general_dynamic_correction = Array{Float64}(undef, 
    max_infection_known,
    max_infection_symptom,
    number_restrictions - 1,
    max_restrictions,
    max_social_contagion)

    #Ideally must load from path

   """
    general_dynamic_correction(infection_known, infection_symptom, 
    resctriction -1, resctriction_value, social_contagion):

        represents the correction to the "social_contagion"
        (home, on the street, ..., hospital), applied to the "resctriction" 
        (transport, education,..., commerce, others) with restriction value 
        (no resctriction, partial, full) for the group with 
        health conditions "infection_known" and "infection_symptom".

    Here we have resctriction >= 2.
    """

    """
    Remarks 
    
    a) resctriction = 1 (social resctriction) it is separate from the other
     groups because it can be applied to especific groups.

    b) social_dynamic_correction and general_dynamic_correction are static Matrix,
    but the values used changes dinamically across the time. 
    
        In social_dynamic_correction, the value "social_restrictions" is chosen 
        over time

        In general_dynamic_correction, resctriction_value as well.

    c) We have also some conditions:

        (1) restrictions = 1 (social_restrictions) can only affect 
        social_contagion from 1 up to 7 (that is, hospitals excluded);

        (2) restrictions = 2 (transport_resctrictions) can clearly only affect
        the social_contagion = 5 (public transport);

        (3) restrictions = 3 (education_restrictions) can only affect 
        social_contagion = 5 and 6 (public transport and classroom) -> work?

        (4) restrictions = 4 (events_restriction) can only affect public_transport
        and big_events;

        (5) From restrictions = 5 up to 8 it can only affect social_contagion
         from 3 to 5  work (work, shopping and public_transport).
    """

    return social_dynamic_correction, general_dynamic_correction
end
