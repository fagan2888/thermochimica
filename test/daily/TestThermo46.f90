

    !-------------------------------------------------------------------------------------------------------------
    !
    ! DISCLAIMER
    ! ==========
    ! 
    ! All of the programming herein is original unless otherwise specified.  Details of contributions to the 
    ! programming are given below.
    !
    !
    ! Revisions:
    ! ==========
    ! 
    !
    !    Date          Programmer          Description of change
    !    ----          ----------          ---------------------
    !    05/14/2013    M.H.A. Piro         Original code
    !    08/31/2018    B.W.N. Fitzpatrick  Modification to use Kaye's Pd-Ru-Tc-Mo system
    !
    ! Purpose:
    ! ========
    !    The purpose of this application test is to ensure that Thermochimica computes the correct results for
    !    the Pd-Ru-Tc-Mo system.
    !-----------------------------------------------------------------------------------------------------------


program TestThermo46

    USE ModuleThermoIO
    USE ModuleThermo 

    implicit none


    ! Specify units:
    cInputUnitTemperature  = 'K'
    cInputUnitPressure     = 'atm'
    cInputUnitMass         = 'moles'
    cThermoFileName        = '../data/Kaye_NobleMetals.dat'

    ! Specify values:
    dPressure              = 1D0
    dTemperature           = 2250D0
    dElementMass(43)       = 0.55D0        ! Tc
    dElementMass(44)       = 0.45D0        ! Ru



    ! Parse the ChemSage data-file:
    call ParseCSDataFile(cThermoFileName)
                
    ! Call Thermochimica:
    call Thermochimica



    ! Check results:
    if (INFOThermo == 0) then
        if (((DABS(dMolFraction(3) - 0.547816D0)/0.547816D0) < 1D-3).AND. &
        ((DABS(dMolFraction(4) - 0.4521839D0)/0.4521839D0) < 1D-3).AND. &
        ((DABS(dGibbsEnergySys - (-1.54452D5))/(-1.54452D5)) < 1D-3))  then
            ! The test passed: 
            print *, 'TestThermo46: PASS'
        else
            ! The test failed.
            print *, 'TestThermo46: FAIL <---'
        end if
    else
        ! The test failed.
        print *, 'TestThermo46: FAIL <---'
    end if



! Reset Thermochimica:
call ResetThermo


end program TestThermo46
