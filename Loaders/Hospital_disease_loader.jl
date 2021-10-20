function load_hospital(path::String, days::Int16 = Int16(300))
    """
    Health System informations
    
    hospital(resource,t) is the quantity of resource "resource" at day "t"

    resource(index) - all values is a ratio quantity/population:

        1 = hospital bed without respirator
        2 = hospital bed with respirator
        3 = ICU

    occupancy_rate  is the  hospital occupancy rate, must be loaded from data.
    """

    hospital = Array{Float64}(undef, 3, days)

    for t=1:days
        hospital[1, t] = 0.002030419
        hospital[2, t] = 0.000048039
        hospital[3, t] = 0.000263443
    end

    occupancy_rate = Array{Float64}(undef, 3)

    effective_hospital = Array{Float64}(undef, 3, days)

    for t=1:days
        effective_hospital[:, t] = hospital[: , t] - occupancy_rate;
    end

    #ToDo: Improve this functions

    return hospital, effective_hospital

end

function load_cycles(path::String, max_disease_severity = Int8(6)) 
    
    """ 
    Viral cycle

    cycles(disease_severity, viral_cicle, flux) means the number of days 
    necessary to cross the viral cicle "viral_cicle" of an individual of 
    potential severity of disease given by disease_severity". The flux is:
    enter ou leave. The number of days starts by the infection day.

    disease_severity: See Load_Gravity() in Demo_grav.jl

    viral_cicle (index): 

        1 - infected and capable of transmission
        2 - infected with symptoms
        3 - necessity of a hospital bed
        4 - necessity of a hospital bed and respirator
        5 - necessity of ICU

    flux (index): 
    
        1 - entering in the cycle
        2 - leaving the cycle

    Integrity condition:

    cycles(disease_severity, vira_cycle, 1) <= 
                                        cycles(disease_severity, viral_cycle, 2)

    for every disease_severity and viral_cycle.

    PS: vira_cycle = 3, ... , viral_cycle = 5 must be in disjunt periods
    """
    cycles = Array{Float64}(undef, max_disease_severity, 5, 2)
    #max_viral_cicle = 5
    #max_flux = 2
    #Ideally it will be loaded from a file

    max_day_disease_severity = Array{Float64}(undef, max_disease_severity)

    for disease_severity = 1:max_disease_severity
        for viral_cycle = 1:5
            if cycles[disease_severity,viral_cycle, 2] > (
                max_day_disease_severity[disease_severity]
            )

                max_day_disease_severity[disease_severity] = (
                    cycles[disease_severity,viral_cycle, 2] 
                )

            end
        end
    end


    max = maximum(max_day_disease_severity)
    
    max_infected_days = Int8(0)

    if(!isnan(max))
        max_infected_days = Int8(floor(max))
    end

    return cycles, max_infected_days, max_day_disease_severity
end

