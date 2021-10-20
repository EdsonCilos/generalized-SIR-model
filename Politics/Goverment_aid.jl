function goverment_aid(days::Int16 = Int16(300))

    """
    Goverment aid

    The 3-dimensional array Aid(sector,target,t) represents the money amount
     given to "target" of sector "sector" in day "t".

     target(index):

        1 = people
        2 = company

     sector(index):

        1 = industry
        2 = construction
        3 = services
        4 = commerce
        5 = other activities and services
        6 = informal sector
        7 = presencial education
    """

    #ToDo: Implement routine to calculate Aid(2,7,t) based on inputs.
    return rand(2,7,days)
end