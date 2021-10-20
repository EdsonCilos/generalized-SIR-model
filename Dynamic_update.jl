include("Initial_data.jl")

function update!(dy::Dynamic, t::Int16)

    dim = size(dy.quant)

    previous_quant = deepcopy(dy.quant[:,:,:,:,:,:,:,:,:,t])

    contagion::Float64 = 0

    #1. Contagion Loop 
    @time begin 
        for demo1 in CartesianIndices(dim[1:3]), 
            infection in CartesianIndices(dim[7:9])
            # infection = (infection_known, infection_test, infection_symptoms)
    
            """
            alterar - desmarcar!
            
            dy.quant[demo1, 1, 3, 1, infection, t + 1] += (
                dy.social_contagion[8] * dy.infectors_hospital[t] *
                previous_quant[demo1, 1, 2, 1, infection] ) #+value
    
        
            dy.quant[demo1, 1, 2, 1, infection, t + 1] -= (
                dy.social_contagion[8] * dy.infectors_hospital[t] *
                previous_quant[demo1, 1, 2, 1, infection] ) #-value 
            """
    
            for demo2 in CartesianIndices(dim[1:3]), 
                infection_kown in 1:dim[7],
                infection_symptom in 1:dim[9],
                social_contagion in 1:1 
                #alterar social_contagion size(dy.social_contagion)[1] - 1
                
                if social_contagion != 1 || demo1[3] == demo2[3]
    
                    contagion = (
                        dy.social_dynamic_correction[
                            demo1[1],
                            demo1[2], 
                            infection[1],
                            infection[3], 
                            dy.social_isolation[
                                demo1[1],
                                demo1[2], 
                                infection[1], 
                                infection[3],
                                t],
                                social_contagion ]*
                        dy.static_correction[demo1[3], social_contagion]*
                        dy.social_contagion[social_contagion]*
                        dy.static_correction[demo2[3], social_contagion]*
                        dy.social_dynamic_correction[
                            demo2[1], 
                            demo2[2], 
                            infection_kown, 
                            infection_symptom,
                            dy.social_isolation[
                                demo2[1],
                                demo2[2], 
                                infection_kown, 
                                infection_symptom,
                                t],
                                social_contagion] )
                    
                    """
                    Primeiramente, usamos o fator de contagio Fatores(i, t) para a 
                    situacao de contato i. Depois multiplicamos pelas correcoes es-
                    taticas, de acordo com caracteristicas intrinsecas do grupo analisa-
                    do. Essa correcao deve afetar os dois grupos, tanto de susceti-
                    veis quanto de infectados. Portanto, o fator é igual ao fator de 
                    base multiplicado pelas correcoes dos dois grupos. Ainda aqui 
                    esta incluida a correcao decorrente da medida governamental p_1.
                    Novamente, a correcao acontece nos dois grupos.
                    """
    
                    for restriction = 1:size(dy.general_dynamic_correction)[3]
                    
                        """
                        Ainda existem as correcoes de acordo com as medidas p_2 a p_8.Se 
                        elas fo-rem medidas desacopladas (isto e, uma nao influencia 
                        na outra), podemos modelar a aplicacao de duasdelas pelo 
                        produto. Como antes, as medidas afetam suscetivel e infecta-
                        do.
                        """
    
                        contagion = dy.general_dynamic_correction[
                                        infection[1], 
                                        infection[3],
                                        restriction,
                                        dy.general_isolation[ 
                                        infection[1], 
                                        infection[3],
                                        restriction,
                                        t ],
                                        social_contagion ]*
                                    contagion*
                                    dy.general_dynamic_correction[
                                        infection_kown, 
                                        infection_symptom,
                                        restriction,
                                        dy.general_isolation[ 
                                            infection_kown, 
                                            infection_symptom,
                                            restriction,
                                            t ],
                                        social_contagion ]
    
                        dy.quant[demo1, 1, 3, 1, infection, t+1 ] += ( 
                            contagion* 
                            dy.infectors_out_hosp[
                                demo2, 
                                infection_kown, 
                                infection_symptom,
                                t ]*
                            previous_quant[ demo1, 1, 2, 1, infection] )
    
                        dy.quant[demo1, 1, 2, 1, infection, t+1 ] -= ( 
                            contagion * 
                            dy.infectors_out_hosp[
                                demo2, 
                                infection_kown, 
                                infection_symptom,
                                t ] * 
                            previous_quant[demo1, 1, 2, 1, infection] )
                    end
                end
            end
        end
    end

    #2. Gravity Loop
    for age_range in 1:dim[1], 
        group_risk in 1:dim[2], 
        disease_severity in dim[3]:-1:1

        dy.quant[
            age_range,
            group_risk,
            :,
            disease_severity,
            3,
            :,
            :,
            :,
            :, 
            t + 1] = (
                 dy.gravity[age_range, group_risk, disease_severity]*
                 dy.quant[
                     age_range, 
                     1 , 
                     :, 
                     disease_severity, 
                     3, 
                     :, 
                     :, 
                     :, 
                     :, 
                     t + 1] )        
    end

    #3. Loop para atualizar estados e testes
    quant_temp = Array{Float64}(undef, size(dy.quant)[1:end-1])

    previous_quant_temp =  Array{Float64}(undef, size(dy.quant)[1:end-1])

    for demo in CartesianIndices(dim[1:3]),
        infection_symptom in 1:dim[9]

        #infection_known = 1  means unknown state... after test expiration...
        #Why not only sum with dy.quant[args..]?
        #Here, move from infection_known = 2 to infection_known = 1
        previous_quant_temp[demo, :, 2, :, 1, 1, infection_symptom] = (
             previous_quant[demo, :, 2, :, 2, dim[8], infection_symptom]
        )

        previous_quant[demo, :, 2, :, 2, dim[8], infection_symptom] .= 0

        """
        bloco 1
        QuantidadeAnteriorTemp(d11, d21, d31, :, 2, :, 1, 1, e51) = 
            QuantidadeAnterior(d11, d21, d31, :, 2, :, 2, e41, e51);

        QuantidadeAnterior(d11, d21, d31, :, 2, :, 2, e41, e51) = 0;
        """

        #Bloco 2
        previous_quant_temp[demo, :, 2, :, 3, 1, infection_symptom] = (
             previous_quant[demo, :, 2, :, 3, dim[8], infection_symptom]
        )
    
        previous_quant[demo, :, 2, :, 3, dim[8], infection_symptom] .= 0

        """
        bloco 2
        QuantidadeAnteriorTemp(d11, d21, d31, :, 2, :, 3, 1, e51) = 
            QuantidadeAnterior(d11, d21, d31, :, 2, :, 3, e41, e51);

            QuantidadeAnterior(d11, d21, d31, :, 2, :, 3, e41, e51) = 0;
        """

        #Bloco 3
        previous_quant_temp[
            demo, :, 3:dy.max_infected_days+ 3 , :, 2, 1, infection_symptom] = (
            previous_quant[
                demo, 
                :, 
                3:dy.max_infected_days + 3 ,
                :, 
                2, 
                dim[8], 
                infection_symptom] 
        )

        previous_quant[ 
            demo, 
            :, 
            3:dy.max_infected_days + 3, 
            :, 
            2, 
            dim[8],
            infection_symptom] .= 0

        """
        bloco 3

        QuantidadeAnteriorTemp(d11, d21, d31, :, 
        3:NumeroDeDiasInfectado+3, :, 2, 1, e51) 
        = 
        QuantidadeAnterior(d11, d21, d31, :, 
        3:NumeroDeDiasInfectado+3, :, 2, e41, e51)

        QuantidadeAnterior(d11, d21, d31, :, 
        3:NumeroDeDiasInfectado+3, :, 2, e41, e51) = 0;
        """
        
        previous_quant_temp[
            demo, :, 3:dy.max_infected_days+3, :, 1, 1, infection_symptom] = (
            previous_quant[
            demo, :, 3:dy.max_infected_days+3, :, 3, dim[8], infection_symptom])
        
            previous_quant[
            demo, :, 3:dy.max_infected_days+3, :, 3, 1, infection_symptom] .= 0


        """
        bloco 4
        QuantidadeAnteriorTemp(d11, d21, d31, :, 
        3:NumeroDeDiasInfectado+3, :, 1, 1, e51) 
        = 
        QuantidadeAnterior(d11, d21, d31, :, 
        3:NumeroDeDiasInfectado+3, :, 3, e41, e51)

        QuantidadeAnterior(d11, d21, d31, :, 
        3:NumeroDeDiasInfectado+3, :, 3, e41, e51) = 0;
        """

        quant_temp[demo, :, 3, :, 1, 1, infection_symptom] = (
          dy.quant[demo, :, 3, :, 2, dim[8], infection_symptom, t + 1] )

        dy.quant[demo, :, 3, :, 2, dim[8], infection_symptom, t + 1] .= 0

        """
        bloco 5
        QuantidadesTemp(d11, d21, d31, :, 3, :, 1, 1, e51)
         =  Quantidades(d11, d21, d31, :, 3, :, 2, e41, e51, t + 1);

        Quantidades(d11, d21, d31, :, 3, :, 2, e41, e51, t + 1) = 0;
        """

        quant_temp[demo, :, 3, :, 2, 1, infection_symptom] = (
          dy.quant[demo, :, 3, :, 3, dim[8], infection_symptom, t+1] )

        dy.quant[demo, :, 3, :, 3, dim[8], infection_symptom, t+1] .= 0

        """
        bloco 6
        QuantidadesTemp(d11, d21, d31, :, 3, :, 2, 1, e51) = 
        Quantidades(d11, d21, d31, :, 3, :, 3, e41, e51, t + 1);

        Quantidades(d11, d21, d31, :, 3, :, 3, e41, e51, t + 1) = 0;
        """

        for infection_test in dim[8] - 1:-1:2

            previous_quant[
                demo,
                 :, 
                 2:dy.max_infected_days+3, 
                 :, 
                 2:3, 
                 infection_test + 1,
                 infection_symptom] =

                previous_quant[
                    demo,
                     :, 
                     2:dy.max_infected_days+3, 
                     :, 
                     2:3, 
                     infection_test,
                     infection_symptom]                


            previous_quant[
                    demo,
                    :, 
                    2:dy.max_infected_days+3, 
                    :, 
                    2:3, 
                    infection_test,
                    infection_symptom] .= 0 
                    #Alocação desnecessária? Sim, no próximo loop será redefinido
                    #Só não é verdade para infection_test = 1
            

            dy.quant[demo,:,3,:,3,infection_test + 1,infection_symptom, t+1] = (
                dy.quant[
                     demo,:,3,:,2,infection_test,    infection_symptom, t+1] )

            dy.quant[demo,:,3,:,2,infection_test, infection_symptom, t+1] .= 0
            #Alocação desnecessária? Sim, a alocação abaixo no próxima iteração 
            #garante... exceto para infection_test = 2

            dy.quant[demo,:,3,:,2,infection_test + 1,infection_symptom, t+1] = (
                dy.quant[
                     demo,:,3,:,3,infection_test,    infection_symptom, t+1] )

            dy.quant[demo,:,3,:,3,infection_test,infection_symptom,t + 1] .= 0
            #Alocação desnecessária? Sim, exceto para infection_test = 2, tal 
            #alocação será feita na próxima iteração pela linha 275
        end

        """
        Para alocações que fo-ram presumidas desnecessárias:

        previous_quant[
                    demo,
                    :, 
                    2:dy.max_infected_days+3, 
                    :, 
                    2:3, 
                    2,
                    infection_symptom] .= 0 

         dy.quant[demo, :, 3, :, 2:3, 2, infection_symptom, t + 1] .= 0
        """

        tests_available = dy.tests[demo[1], demo[2], infection_symptom, t]

        for hospital_use in 1:dim[6]
            if tests_available != 0
                this_state_total = sum(
                    dy.quant[demo, :, 2:dy.max_infected_days+3, hospital_use,
                    1, 1, infection_symptom, t+1] +
                    previous_quant[demo,:,2:dy.max_infected_days+3,hospital_use,
                    1, 1, infection_symptom] 
                )

                test_to_apply = min(
                    minimum(tests_available),
                    this_state_total)

                if this_state_total != 0

                    value = (
                        test_to_apply/this_state_total*
                        dy.quant[
                            demo, 
                            :, 
                            3, 
                            hospital_use, 
                            1, 
                            1,
                            infection_symptom, 
                            t + 1] )

                    dy.quant[
                        demo,
                        :,
                        3,
                        hospital_use,
                        3,
                        2,
                        infection_symptom,
                        t+1] += value
                    
                    dy.quant[
                        demo,
                        :,
                        3,
                        hospital_use,
                        1,
                        1,
                        infection_symptom,
                        t+1] -= value
                    
                    value = (
                        test_to_apply/this_state_total*
                        previous_quant[
                            demo,
                            :,
                            2:dy.max_infected_days+3,
                            hospital_use,
                            1,
                            1,
                            infection_symptom
                            ] )  
                    
                    previous_quant[
                        demo,
                        :,
                        2:dy.max_infected_days+3,
                        hospital_use,
                        2,
                        2,
                        infection_symptom
                    ] += value

                    previous_quant[
                        demo,
                        :,
                        2:dy.max_infected_days+3,
                        hospital_use,
                        2,
                        2,
                        infection_symptom
                    ] -= value

                    tests_available -= test_to_apply
                end
            end
        end

        dy.test_spare[demo[1], demo[2], infection_symptom, t] = tests_available

        dy.quant[demo, :, :, :, :, :, infection_symptom, t + 1] += (
            quant_temp[demo, :, :, :, :, :, infection_symptom] )

        previous_quant[demo, :, :, :, :, :, infection_symptom] += (
            previous_quant_temp[demo, :, :, :, :, :, infection_symptom] )
    end

    #4. Loop para atualizar o ciclo de falso sintomas (e_5 na referência)
    #Os dados continuarao guardados em dy.quant[:, :, :, :, :, :, :, :, :, t +1] 
    # previous_quant[:, :, :, :, :, :, :, :, :]

    previous_quant_temp[:, :, :, :, 2:dy.max_infected_days + 3, :, :, :, 1] = (
         previous_quant[:, :, :, :, 2:dy.max_infected_days + 3, :, :, :, dim[9]]
    )   

    previous_quant[:, :, :, :, 2:dy.max_infected_days + 3, :, :, :, dim[9]] .= 0
    #desnecessário?

    quant_temp[:, :, :, :, 3, :, :, :, 1] = (
      dy.quant[:, :, :, :, 3, :, :, :, dim[9], t+ 1] )

    dy.quant[:, :, :, :, 3, :, :, :, dim[9], t+ 1] .= 0
    #desnecessário?

    for infection_symptom in dim[9] - 1:-1:2
        
        previous_quant[
            :,
            :, 
            :, 
            :, 
            2:dy.max_infected_days+3, 
            :, 
            :, 
            :, 
            infection_symptom + 1] = (
                previous_quant[
                    :,
                    :, 
                    :, 
                    :, 
                    2:dy.max_infected_days+3, 
                    :, 
                    :, 
                    :, 
                    infection_symptom]
        )

        previous_quant[
            :,
            :, 
            :, 
            :, 
            2:dy.max_infected_days+3, 
            :, 
            :, 
            :, 
            infection_symptom] .= 0 #desnecessário?
        
        dy.quant[
            :,
            :,
            :,
            :,
            2:dy.max_infected_days+3, 
            :, 
            :, 
            :, 
            infection_symptom + 1,
            t + 1 ] = (
                dy.quant[
                    :,
                    :,
                    :,
                    :,
                    2:dy.max_infected_days+3, 
                    :, 
                    :, 
                    :, 
                    infection_symptom,
                    t + 1]
        )

        dy.quant[
            :,
            :,
            :,
            :,
            2:dy.max_infected_days+3, 
            :, 
            :, 
            :, 
            infection_symptom,
            t + 1] .= 0 # desnecessário
    end

    """
    Após remover as alocações desnecessárias, fazer:

    previous_quant[
        :,
        :, 
        :, 
        :, 
        2:dy.max_infected_days+3, 
        :, 
        :, 
        :, 
        2] .= 0

    dy.quant[
            :,
            :,
            :,
            :,
            2:dy.max_infected_days+3, 
            :, 
            :, 
            :, 
            2,
            t + 1] .= 0 

    """

    value = dy.false_symptom_ratio/dy.false_symptoms_days*
        dy.quant[:, :, :, :, 3, :, :, :, 1, t+1]

    dy.quant[:, :, :, :, 3, :, :, :, 1, t+1] -= value

    dy.quant[:, :, :, :, 3, :, :, :, 2, t+1] = value 

    value = dy.false_symptom_ratio/dy.false_symptoms_days*
        previous_quant[:, :, :, :, 2:dy.max_infected_days + 3, :, :, :, 1]

    previous_quant[:, :, :, :, 2:dy.max_infected_days + 3, :, :, :, 1] -= value
    previous_quant[:, :, :, :, 2:dy.max_infected_days + 3, :, :, :, 2] = value

    dy.quant[:,:,:,:,3,:,:,:,1,t+1] += quant_temp[:,:,:,:,3,:,:,:,1]

    previous_quant[:,:,:,:,2:dy.max_infected_days+3, :,:,:,1] += 
    previous_quant_temp[:,:,:,:,2:dy.max_infected_days+3, :,:,:,1]

    #5. Loop para transição de estados

    for health_condition in dy.max_infected_days + 2: -1: 3, 
        disease_severity in dim[4]

        if dy.max_day_disease_severity[disease_severity] == health_condition -2
            if disease_severity == dim[4]

                previous_quant[
                    :, 
                    :, 
                    :, 
                    disease_severity, 
                    dy.max_infected_days + 4,
                    :,
                    :,
                    :,
                    :] += previous_quant[
                        :, 
                        :, 
                        :, 
                        disease_severity, 
                        health_condition, 
                        :, 
                        :, 
                        :, 
                        :]
                        
            else

                previous_quant[
                    :, 
                    :, 
                    :, 
                    disease_severity, 
                    dy.max_infected_days + 3,
                    :,
                    :,
                    :,
                    :] += previous_quant[
                        :, 
                        :, 
                        :, 
                        disease_severity, 
                        health_condition, 
                        :, 
                        :, 
                        :, 
                        : ]
            end

            previous_quant[
                        :, 
                        :, 
                        :, 
                        disease_severity, 
                        health_condition, 
                        :, 
                        :, 
                        :, 
                        :] .= 0
        end

        if dy.max_day_disease_severity[disease_severity] > health_condition - 2

            hospital_use_new = 1
            hospital_use_old = 1
        
            if health_condition - 1 == dy.cycles[disease_severity, 3, 1]
                hospital_use_new = 2
            end
            
            if health_condition - 2 >= dy.cycles[disease_severity, 3, 1] &
                health_condition - 2 < dy.cycles[disease_severity, 3, 2]

                hospital_use_new = 2
                hospital_use_old = 2
            end

            if health_condition - 2 == dy.cycles[disease_severity, 3, 2]

                hospital_use_new = 3
                hospital_use_old = 2
            end

            if health_condition - 2 >= dy.cycles[disease_severity, 4, 1] &
                health_condition - 2 < dy.cycles[disease_severity, 4, 2]

                hospital_use_new = 3
                hospital_use_old = 3
            end

            if health_condition - 2 == dy.cycles[disease_severity, 4, 2] 

                hospital_use_new = 4
                hospital_use_old = 3
            end

            if health_condition - 2 >= dy.cycles[disease_severity, 5, 1] &
               health_condition - 2 < dy.cycles[disease_severity, 5, 2]


               hospital_use_new = 4
               hospital_use_old = 4
            end

            previous_quant[
                :, 
                :, 
                :, 
                disease_severity, 
                health_condition + 1,
                hospital_use_new,
                :,
                :,
                : ] += previous_quant[
                    :,
                    :,
                    :,
                    disease_severity,
                    hospital_use_old,
                    :,
                    :,
                    : ]

            previous_quant[
                :,
                :,
                :,
                disease_severity,
                hospital_use_old,
                :,
                :,
                : ] .= 0

        end
    end

    #6. Loop to update the status of the deads due to lake of hospital resources
    
    for hospital_use in 2:dim[6]

        dy.hospital_need[hospital_use - 1] = (
            sum(previous_quant[
                    :,
                    :,
                    :,
                    :, 
                    3:dy.max_infected_days + 3,
                    hospital_use,
                    :,
                    :,
                    : ]
                )
        )
        
    end

    for i in length(dy.hospital_available):-1:1

        dy.hospital_available[i] = max(
            dy.effective_hospital[i] - dy.hospital_need[i], 0 
        )
        
        availability = sum(
            dy.hospital_available[i:length(dy.hospital_available)] 
        )

        deficit = max(dy.hospital_need[i] - availability, 0)

        for cycle_day in 1:dy.max_infected_days

            this_day_total = 0

            for disease_severity in 3:dim[4]

                if dy.cycles[disease_severity, i + 2, 1] != -1 &
                    dy.cycles[disease_severity, i + 2, 1] + cycle_day - 1 <=
                    dy.cycles[disease_severity, i + 2, 2]

                    this_day_total += sum(
                        previous_quant[
                            :,
                            :,
                            :,
                            disease_severity,
                            2 + dy.cycles[disease_severity,i+2,1] + cycle_day-1,
                            i + 1,
                            :,
                            :,
                            :]
                    )
                end
            end

            today_death = min(this_day_total, deficit)

            if this_day_total != 0

                for disease_severity in 3:dim[4]

                    if dy.cycles[disease_severity, i+2, 1] != -1 &
                        dy.cycles[disease_severity, i+2, 1] + cycle_day - 1 <=
                        dy.cycles[disease_severity, i+2, 2]

                        value = today_death/this_day_total*previous_quant[
                                :,
                                :,
                                :,
                                disease_severity,
                                2+dy.cycles[disease_severity,i+2,1]+cycle_day-1,
                                i + 1,
                                :,
                                :,
                                :]

                        previous_quant[
                            :,
                            :,
                            :,
                            disease_severity, 
                            dy.max_infected_days + 5,
                            1,
                            :,
                            :,
                            :] += value

                        previous_quant[
                            :,
                            :,
                            :,
                            disease_severity,
                            2 + dy.cycles[disease_severity,i+2,1] + cycle_day-1,
                            i + 1,
                            :,
                            :,
                            :] -= value

                    end
                end
            end

        deficit -= today_death

        end
    end

    dy.quant[:, :, :, :, :, :, :, :, :, t + 1] += previous_quant

    for demo in CartesianIndices(dim[1:3]), 
        disease_severity in 1:dim[4],
        health_condition in 1:dim[5],
        state in CartesianIndices(dim[6:9]) 
        #state: 
        #1 = hospital_use, 2 = infectown_known, 3 = test, 4 = infection_symptom

        if (health_condition - 2 >= dy.cycles[disease_severity, 1 , 1]) & 
            (health_condition - 2 <= dy.cycles[disease_severity, 1 , 2])

            if state[1] == 1

                dy.infectors_out_hosp[demo, state[2], state[3], t+1] +=
                    dy.quant[demo,disease_severity,health_condition,state,t+1]
                
            else

                dy.infectors_hospital[t+1] += 
                    dy.quant[demo,disease_severity,health_condition,state,t+1]
            end
        end
    end
end
