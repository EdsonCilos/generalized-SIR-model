function load_demography(path::String)

    """
    Demography

    The aim of this function is to load the Demografy matrix.

    Demografy[age_range, risk_group, housing_area] is the proportion of people 
    with age range "age_range", with a risk "risk_group" living in 
    "housing_area".

    age_range (index): 

        1 = age range in 0-19
        2 = age range in 20-44
        3 = age range in 45-54
        4 = age range in 55-64
        5 = 65+ age

    risk_group - health sense - (index):

        1 = no risk
        2 = with risk

    housing_area (index):

        1 = comunity or  shantytown
        2 = rural
        3 = urban not urban_crowded
        4 = urban crowded
    """
    max_age::Int8 = 5
    max_risk::Int8 = 1  #No data available
    max_home::Int8 = 4
    #Actualy must depend on the imported data

    demography = ones(max_age, max_risk, max_home)/max_age*max_risk*max_home   
    #biased proportions

    #ToDo: Implement module to import from file.
    return  demography
end

function load_gravity(path::String)

    """
    Infecction characteristics related to age range and risk.

    Gravity[age_range, risk_group, disease_severity] is the proportion of 
    citizens in the age range "age_range", in group risk "risk_group"  with 
    disease severity "disease_severity" after contagion.

    See Load_demografy for informations related to age_range and risk_group

    disease_severity - in case of infection (index): 

        1 = asymptomatic
        2 = mild and moderate symptoms
        3 = severe symptoms, with necessity of hospital bed
        4 = severe symptoms, with necessity of hospital bed and respirator
        5 = severe symptoms, with necessity of ICU
        6 = severe symptoms, group in which will die regardless 
            of hospital structure.

    Fixed an age_range and a risk_group, the vector 
    Gravity[age_range, risk_group, :] has sum equals 1. 
    """
    max_age::Int8 = 5 
    max_risk::Int8 = 1 #No data available
    max_severity::Int8 = 6

    gravity = ones(max_age, max_risk, max_severity)/max_severity
    
    #ToDo: Implement module to import from file.
    return  gravity 
end

function cross_matrix(demography::AbstractArray,gravity::AbstractArray)

    dim = [x for x in size(demography)]
    push!(dim, size(gravity)[end])
    """
    size = (max_age_range, max_risk_group, max_housing_are,max_disease_severity)
    """

    demo_grav = Array{Float64}(undef, Tuple(dim))

    for age_range = 1:dim[1]
        for risk_group = 1:dim[2]
            for housing_area = 1:dim[3]
                for disease_severity = 1:dim[4]
                    demo_grav[age_range, risk_group, housing_area, disease_severity] = 
                    ( demography[age_range, risk_group, housing_area]
                    * gravity[age_range, risk_group, disease_severity] )
                end
            end
        end
    end

    return  demo_grav
end
