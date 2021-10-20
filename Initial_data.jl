include("data_loader.jl") #We shall think how to use it
include("Loaders/Demo_grav_loader.jl")
include("Loaders/Hospital_disease_loader.jl")
include("Loaders/Economy_loader.jl")
include("Loaders/Contagion_loader.jl")
include("Politics/Disease_tests.jl")
include("Politics/Goverment_aid.jl")
include("Politics/Isolation.jl")

struct Dynamic
    static_correction::AbstractArray
    social_dynamic_correction::AbstractArray
    general_dynamic_correction::AbstractArray
    social_isolation::AbstractArray
    general_isolation::AbstractArray
    social_contagion::AbstractArray
    quant::AbstractArray
    infectors_out_hosp::AbstractArray
    infectors_hospital::AbstractArray
    gravity::AbstractArray
    cycles::AbstractArray
    tests::AbstractArray
    test_spare::AbstractArray
    max_day_disease_severity::AbstractArray
    hospital_need::AbstractArray
    hospital_available::AbstractArray
    effective_hospital::AbstractArray
    max_infected_days::Int8
    false_symptom_ratio::Float64
    false_symptoms_days::Int8
end

function initial_data(days::Int16 = Int16(300))

    path_demo::String = "oi" 
    path_grav::String = "oi" 
    path_cycles::String = "oi"
    path_economy::String = "oi"
    path_hospital::String = "oi"
    path_social_contagion::String = "oi"
    path_static_correction::String = "oi"
    path_dinamic_correction::String = "oi"

    demography = load_demography(path_demo)

    max_age_range = Int8(size(demography)[1])
    max_group_risk = Int8(size(demography)[2])
    max_housing_area = Int8(size(demography)[3])

    gravity = load_gravity(path_grav)

    demo_grav = cross_matrix(demography,gravity)

    max_severity = Int8(size(demo_grav)[4])

    cycles, max_infected_days, max_day_disease_severity = (
        load_cycles(path_cycles, max_severity) )

    max_viral_cicle = Int8(size(cycles)[1])
    max_flux = Int8(size(cycles)[2])

    economy = load_economy(path_economy)

    hospital, effective_hospital = load_hospital(path_hospital, days)

    social_contagion = load_social_contagion(path_social_contagion)

    max_social_contagion = Int8(size(social_contagion)[1])

    static_correction = load_static_correction(
        path_static_correction,
        max_housing_area,
        max_social_contagion )
    
    test_expiration = Int8(5)
    false_symptoms_days = Int8(5)

    #Health states
    max_health_condition = Int8(2 + max_infected_days + 3)
    max_hospital_use = Int8(4)
    max_infection_known = Int8(3)
    max_infection_test = Int8(1 + test_expiration)
    max_infection_symptom = Int8(1 + false_symptoms_days)

    social_dynamic_correction, gen_dynamic_correction = load_dynamic_correction(
        path_dinamic_correction,
        max_infection_symptom,
        max_age_range,
        max_group_risk,
        max_infection_known,
        max_social_contagion)

    number_restrictions = Int8(size(gen_dynamic_correction)[3] + 1)

    tests = disease_tests(false_symptoms_days, days) 
    #Must set option to generate a random or by input

    aid = goverment_aid(days) 

    social_isolation, general_isolation =  isolation(
        max_infection_symptom,
        max_age_range,
        max_group_risk, 
        max_infection_known,
        number_restrictions,
        days
    )

    quant = Array{Float64}(undef,
    max_age_range,
    max_group_risk,
    max_housing_area,
    max_severity,
    max_health_condition,
    max_hospital_use,
    max_infection_known,
    max_infection_test,
    max_infection_symptom,
    days )

    """
    Estudar a partir deste ponto!
    """
    false_symptom_ratio = 0.05 #Input data
    death_today = 500/210000000 #Input data
    death_ago = 10/210000000 #Input data - NumeroDeMortosHaNumeroDeDiasInfectado


    death_infected_rate = 0

    for demo in CartesianIndices(demo_grav[:,:,:,6])
        death_infected_rate += demo_grav[demo,6]
    end

    recovered_today = death_today*(1 - death_infected_rate)/death_infected_rate

    initial_infection__ratio = (death_today/(1 - death_infected_rate))^(
        1/max_infected_days
    )

    """
    Vamos assumir que o numero de mortos pode ser dado por C*b^t e, assim, 
    estimar o numero de infectados nos ultimos 'max_infected_days' dias.
    [edson] poderíamos fazer tal conta usando regressão linear com dados "reais"
    """

    infected_k_days_ago = Array{Float64}(undef, max_infected_days)

    susceptible_today = 1 - death_today - recovered_today

    for k in 1:max_infected_days
        
        infected_k_days_ago = ( (death_ago / death_infected_rate) * 
        (initial_infection__ratio^(2 * max_infected_days - k + 1) - 
        initial_infection__ratio^(2 * max_infected_days - k))
        )

        susceptible_today += -infected_k_days_ago[k]
    end

    for demo in CartesianIndices(demography)
    
        quant[demo, 6, 4 + max_infected_days, 1, 1, 1, 1] = (
        death_today*demography[demo] ) #Initial deaths quantity 
    
        for disease_severity in 3:max_severity - 1
            quant[demo, disease_severity, 3 + max_infected_days, 1, 1, 1, 1] = (
            recovered_today * demo_grav[demo, disease_severity] / (
                demo_grav[demo, 1] + demo_grav[demo, 2] + demo_grav[demo, 3] +
                demo_grav[demo, 4] + demo_grav[demo, 5]) ) 
              #Initial recovred quantity
        end

        for disease_severity in 1:2
            quant[demo, disease_severity, 3 + max_infected_days, 1, 1, 1, 1] = (
            recovered_today * (1 - false_symptom_ratio) *
             demo_grav[demo, disease_severity] / (
                demo_grav[demo, 1] + demo_grav[demo, 2] + demo_grav[demo, 3] +
              demo_grav[demo, 4] + demo_grav[demo, 5] ) )
        end

        quant[demo,1,2,1,1,1,1,1] = susceptible_today*(1-false_symptom_ratio)*(
            demo_grav[demo] ) #Initial sucestibles
    
        for infection_symptoms in 2:false_symptoms_days + 1
            quant[demo,1,2,1,1,1,infection_symptoms,1] = (
                susceptible_today*(false_symptom_ratio/max_infected_days)*
                demography[demo] )
        end
    end

    for health_condition in 3:max_infected_days + 2
        
        state_total = 0

        for disease_severity in 1:max_severity
            if max_day_disease_severity[disease_severity] >= health_condition-2
                state_total += sum(demo_grav[:,:,:,disease_severity])
            end
        end

        if state_total != 0
            for demo_g in CartesianIndices(demo_grav)
                #disease_severity = demo_g[4]
                if max_day_disease_severity[demo_g[4]] >= health_condition - 2

                    hospital_use = 1
                    
                    if health_condition - 1 >= cycles[demo_g[4], 3, 1] & 
                        health_condition - 2 <= cycles[demo_g[4], 3, 2] 

                        hospital_use = 2

                    elseif health_condition - 1 >= cycles[demo_g[4], 4, 1] & 
                            health_condition - 2 <= cycles[demo_g[4], 4, 2] 
                        
                        hospital_use = 3

                    elseif  health_condition - 1 >= cycles[demo_g[4], 5, 1] &
                            health_condition - 2 <= cycles[demo_g[4], 5, 2] 

                        hospital_use = 4

                    end

                    #Initial infected

                    quant[demo_g, health_condition, hospital_use, 1, 1, 1, 1]= (
                        infected_k_days_ago[health_condition - 2]*
                        (1- false_symptom_ratio)*demo_grav[demo_g]/state_total)

                    for infection_symptoms in 2:false_symptoms_days + 1
                        quant[demo_g, health_condition, hospital_use, 1, 1, 
                        infection_symptoms, 1] = infected_k_days_ago[
                            health_condition - 2]*(false_symptom_ratio/
                            max_infected_days)*(demo_grav[demo_g]/state_total) 
                    end
                end
            end
        end
    end

    infectors_hospital = Array{Float64}(undef, days)

    infectors_out_hosp = Array{Float64}(undef, 
    max_age_range,
    max_group_risk,
    max_housing_area,
    max_infection_known,
    max_infection_symptom,
    days )

    for demo_g in CartesianIndices(demo_grav), #demo_g[4] = disease_severity
        health_condition in 3:max_infected_days + 2,
        hospital_use in 1:max_hospital_use,
        infection_known in 1:max_infection_known,
        infection_test in 1:max_infection_test,
        infection_symptoms in 1:max_infection_symptom

        if health_condition - 2 >= cycles[demo_g[4], 1 , 1] &
            health_condition - 2 <= cycles[demo_g[4], 1, 2]

            if hospital_use == 1
                infectors_out_hosp[demo_g, infection_known, 
                infection_symptoms, 1] += ( quant[demo_g, health_condition, 1,
                infection_known, infection_test, infection_symptoms] )
            else
                infectors_hospital[1] += ( quant[demo_g, health_condition, 1,
                infection_known, infection_test, infection_symptoms] )
            end
        end
    end

    test_spare = Array{Float64}(undef, 
    max_age_range,
    max_group_risk,
    max_infection_symptom,
    days ) #Only used in the day iterations... remove!

    return  Dynamic(static_correction,
                    social_dynamic_correction,
                    gen_dynamic_correction,
                    social_isolation,
                    general_isolation,
                    social_contagion,
                    quant,
                    infectors_out_hosp,
                    infectors_hospital,
                    gravity,
                    cycles,
                    tests,
                    test_spare,
                    max_day_disease_severity,
                    Array{Float64}(undef,size(hospital)[1]), #hospital_need
                    Array{Float64}(undef,size(hospital)[1]), #hospital_available
                    effective_hospital,
                    max_infected_days,
                    false_symptom_ratio,
                    false_symptoms_days )
end