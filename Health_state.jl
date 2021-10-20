    """

     Health state definitions
    
    test_expiration = 5
    false_symptoms_days = 5
    max_infected_days (from load_cycles in Hospital_disease_loader.jl) 

    1.health_condition:

        1 = previous immunity
        2 = susceptible
        3 = infected since 1 day
        4 = infected since 2 days

         .
         .
         .

        max_infected_days + 2 = represents infected since 'max_infected_days' days
        max_infected_days + 3 = recovered patient
        max_infected_days + 4 = patient dead due to the severity of infection
        max_infected_days + 5 = patient dead due to the lack of health resources

      
    2.hospital_use:

        1 = not beeing using any health resource
        2 = be occupying hospital bed without respirator
        3 = be occupying hospital bed and respirator
        4 = be occupying ICU

    3.infection_known:

        1 = patient with infection condition unknown 
        2 = patient with infection condition known (due to test)
        3 = patient with infection condition wrongly known 
        (a posteriori determination ?)
        

    4.infection_test:

        1 = patient not tested or not applicable
        2 = tested 1 day ago
        3 = tested 2 days ago
        
        .
        .
        .

        test_expiration + 1 = tested "test_expiration" days ago

    5.infection_symptoms: 
    
        1 = Patient without false symptoms
        2 = with false symptoms 1 day ago
        3 = with false symptoms 2 days ago

        .
        .
        .

        false_symptoms_days + 1 = with false symptoms "false_symptoms_days" 
                                  days ago



    max_health_condition = 2 + max_infected_days + 3
    max_hospital_use = 4
    max_infection_known = 3;
    max_infection_test = 1 + test_expiration
    max_infection_symptoms = 1 + false_symptoms_days
    """

    