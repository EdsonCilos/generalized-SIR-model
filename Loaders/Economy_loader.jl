function load_economy(path::String)

    """
     Economy info

    The matrix economy(sector, ratio_type) represents the ratio of the
    sector of economy "sector". The type of the ratio is given by "ratio_type".

    sector(index):

        1 = industry
        2 = construction
        3 = services
        4 = commerce
        5 = other activities and services
        6 = informal sector
        7 = presencial education
    
    ratio_type(index):

        1 = ratio related to economy, that is, economic ratio
        2 = ratio related to population, that is, population ratio
    
    Examples:  

        a) economy(7, 2) is the ratio of population that works in the presencial
         education

        b) economy(1,1) is the ratio of economy represented by the industry 
        sector
    """
    #ToDo: Implement module to import from file.
    return ones(7,2)/10
end