

    !-------------------------------------------------------------------------------------------------------------
    !
    !> \file    ParseCSDataBlockSUBG.f90
    !> \brief   Parse the data block section corresponding to a SUBG phase of a ChemSage data-file.
    !> \author  M.H.A. Piro
    !> \date    Mar. 4, 2018
    !> \sa      ParseCSDataFile.f90
    !> \sa      ParseCSDataBlock.f90
    !> \sa      ParseCSDataBlockGibbs.f90
    !> \todo    There are a number of lines in SUBG phases that I do not yet understand.
    !!           I've asked some experts and they don't know either, which tells me that
    !!           they're not important. Once I
    !!           gain more experience with these models, this will likely become more clear.
    !
    !
    ! DISCLAIMER
    ! ==========
    !
    ! All of the programming herein is original unless otherwise specified and is completely
    ! independent of ChemApp and related products, including Solgas, Solgasmix, Fact, FactSage
    ! and ChemSage.
    !
    !
    ! Revisions:
    ! ==========
    !
    !   Date            Programmer      Description of change
    !   ----            ----------      ---------------------
    !   03/04/2018      M.H.A. Piro     Original code
    !
    !
    ! Purpose:
    ! ========
    !
    !> \details The purpose of this subroutine is to parse the "data block" section of a ChemSage data-file
    !! containing a "SUBG" phase, which represents the modified quasichemical model. This phase differs
    !! from many other types of thermodynamic models in that it attempts to capture Short Range Order (SRO)
    !! in liquid or solid solutions. This is achieved by focusing on pairs of species, rather than the species
    !! themselves. For more information, see the following paper:
    !!
    !! A.D. Pelton, S.A. Degterov, G. Eriksson, C. Roberlin, Y. Dessureault, "The Modified Quasichemical
    !! Model I -- Binary Solutions", Metallurgical and Materials Transactions B, 31B (2000) 651-659.
    !!
    !
    !
    ! Pertinent variables:
    ! ====================
    !
    ! INFO                      A scalar integer that indicates a successful exit or identifies an error.
    ! nSpeciesCS                Number of species in the system (combined solution species and pure
    !                            separate phases).
    ! nGibbsEqSpecies           Number of Gibbs energy equations for a particular species.
    ! iSpeciesAtomsCS           Integer matrix representing the number of atoms of a particular
    !                            elements in a species.
    ! iParticlesPerMoleCS       An integer vector containing the number of particles per mole of the
    !                            constituent species formula mass.  The default value is 1.
    ! cSolnPhaseNameCS          The name of a solution phase.
    ! cSolnPhaseTypeCS          The type of a solution phase.
    ! cSolnPhaseTypeSupport     A character array representing solution phase types that are supported.
    ! iRegularParamCS           An integer matrix representing the parameter index for the first dimension
    !                            and the mixing terms on the second dimension.  For the second dimension, the
    !                            first coefficient indicates whether the parameter is a binary or ternary term (n),
    !                            the next n coefficients correspond to the constituent indices, and the last
    !                            coefficient corresponds to the exponent.
    !
    !-------------------------------------------------------------------------------------------------------------


subroutine ParseCSDataBlockSUBG( i )

    USE ModuleParseCS

    implicit none

    integer                     :: i, j, k, l, n, x, y, p, a, b, nA2X2, nChar
    integer                     :: iaaxy, ibbxy, iabxx, iabyy
    integer,     dimension(10)  :: iTempVec
    integer,     dimension(15)  :: iNumPos
    real(8)                     :: qa, qb, qx, qy, za, zb, zx, zy, dF
    real(8),     dimension(20)  :: dTempVec
    character(8),dimension(20)  :: cConstituentNames1, cConstituentNames2
    logical, dimension(:), allocatable :: lPairSet

    real(8), dimension(nSpeciesCS,nElementsCS) :: dStoichSpeciesOld

    ! Initialize variables:
    dTempVec = 0D0
    iTempVec = 0

    ! SUBG phases appear to be represented as multi-sublattice phases; however,
    ! they don't appear to make use of any sublattice information. I'm going to
    ! to read these lines for now, but it may need to be revised at a later time.

    ! This line contains N integers (where N is the number of sublattices)
    ! where each integer represents the number of constituents on the respective
    ! sublattice. I think there are always two sublattices for SUBG phases.
    read (1,*,IOSTAT = INFO) nSublatticeElementsCS(nCountSublatticeCS,1:2)
    nSublatticePhaseCS(nCountSublatticeCS) = 2

    ! Read in names of constituents on first sublattice:
    ! NOTE: THIS LINE MAY NEED TO BE REVISED IF THERE ARE A LARGE # OF CONSTITUENTS:
    read (1,*,IOSTAT = INFO) cConstituentNames1(1:nSublatticeElementsCS(nCountSublatticeCS,1))
    ! Match elements on 1st sublattice with elements in dat file order
    LOOP_Sub1Names: do k = 1, nSublatticeElementsCS(nCountSublatticeCS,1)
        ! Find numbers or +/- in name if they are there
        iNumPos = 3
        if (INDEX(cConstituentNames1(k),'1') > 0) iNumPos(1)  = INDEX(cConstituentNames1(k),'1')
        if (INDEX(cConstituentNames1(k),'2') > 0) iNumPos(2)  = INDEX(cConstituentNames1(k),'2')
        if (INDEX(cConstituentNames1(k),'3') > 0) iNumPos(3)  = INDEX(cConstituentNames1(k),'3')
        if (INDEX(cConstituentNames1(k),'4') > 0) iNumPos(4)  = INDEX(cConstituentNames1(k),'4')
        if (INDEX(cConstituentNames1(k),'5') > 0) iNumPos(5)  = INDEX(cConstituentNames1(k),'5')
        if (INDEX(cConstituentNames1(k),'6') > 0) iNumPos(6)  = INDEX(cConstituentNames1(k),'6')
        if (INDEX(cConstituentNames1(k),'7') > 0) iNumPos(7)  = INDEX(cConstituentNames1(k),'7')
        if (INDEX(cConstituentNames1(k),'8') > 0) iNumPos(8)  = INDEX(cConstituentNames1(k),'8')
        if (INDEX(cConstituentNames1(k),'9') > 0) iNumPos(9)  = INDEX(cConstituentNames1(k),'9')
        if (INDEX(cConstituentNames1(k),'0') > 0) iNumPos(10) = INDEX(cConstituentNames1(k),'0')
        if (INDEX(cConstituentNames1(k),'+') > 0) iNumPos(11) = INDEX(cConstituentNames1(k),'+')
        if (INDEX(cConstituentNames1(k),'-') > 0) iNumPos(12) = INDEX(cConstituentNames1(k),'-')
        if (INDEX(cConstituentNames1(k),'[') > 0) iNumPos(13) = INDEX(cConstituentNames1(k),'[')
        if (INDEX(cConstituentNames1(k),']') > 0) iNumPos(14) = INDEX(cConstituentNames1(k),']')
        nChar = MINVAL(iNumPos) - 1
        ! Check for vacancy
        if (cConstituentNames1(k)(1:nChar) == 'Va') then
            iSublatticeElementsCS(nCountSublatticeCS, 1, k) = -1
            cycle LOOP_Sub1Names
        end if
        do j = 1, nElementsCS
            if (cConstituentNames1(k)(1:nChar) == cElementNameCS(j)(1:2)) then
                iSublatticeElementsCS(nCountSublatticeCS, 1, k) = j
                cycle LOOP_Sub1Names
            end if
        end do
    end do LOOP_Sub1Names

    ! Read in names of constituents on second sublattice: (ignore for now):
    read (1,*,IOSTAT = INFO) cConstituentNames2(1:nSublatticeElementsCS(nCountSublatticeCS,2))
    ! Match elements on 2nd sublattice with elements in dat file order
    LOOP_Sub2Names: do k = 1, nSublatticeElementsCS(nCountSublatticeCS,2)
        ! Find numbers or +/- in name if they are there
        iNumPos = 3
        if (INDEX(cConstituentNames2(k),'1') > 0) iNumPos(1)  = INDEX(cConstituentNames2(k),'1')
        if (INDEX(cConstituentNames2(k),'2') > 0) iNumPos(2)  = INDEX(cConstituentNames2(k),'2')
        if (INDEX(cConstituentNames2(k),'3') > 0) iNumPos(3)  = INDEX(cConstituentNames2(k),'3')
        if (INDEX(cConstituentNames2(k),'4') > 0) iNumPos(4)  = INDEX(cConstituentNames2(k),'4')
        if (INDEX(cConstituentNames2(k),'5') > 0) iNumPos(5)  = INDEX(cConstituentNames2(k),'5')
        if (INDEX(cConstituentNames2(k),'6') > 0) iNumPos(6)  = INDEX(cConstituentNames2(k),'6')
        if (INDEX(cConstituentNames2(k),'7') > 0) iNumPos(7)  = INDEX(cConstituentNames2(k),'7')
        if (INDEX(cConstituentNames2(k),'8') > 0) iNumPos(8)  = INDEX(cConstituentNames2(k),'8')
        if (INDEX(cConstituentNames2(k),'9') > 0) iNumPos(9)  = INDEX(cConstituentNames2(k),'9')
        if (INDEX(cConstituentNames2(k),'0') > 0) iNumPos(10) = INDEX(cConstituentNames2(k),'0')
        if (INDEX(cConstituentNames2(k),'+') > 0) iNumPos(11) = INDEX(cConstituentNames2(k),'+')
        if (INDEX(cConstituentNames2(k),'-') > 0) iNumPos(12) = INDEX(cConstituentNames2(k),'-')
        if (INDEX(cConstituentNames2(k),'[') > 0) iNumPos(13) = INDEX(cConstituentNames2(k),'[')
        if (INDEX(cConstituentNames2(k),']') > 0) iNumPos(14) = INDEX(cConstituentNames2(k),']')
        nChar = MINVAL(iNumPos) - 1
        ! Check for vacancy
        if (cConstituentNames2(k)(1:nChar) == 'Va') then
            iSublatticeElementsCS(nCountSublatticeCS, 2, k) = -1
            cycle LOOP_Sub2Names
        end if
        do j = 1, nElementsCS
            if (cConstituentNames2(k)(1:nChar) == cElementNameCS(j)(1:2)) then
                iSublatticeElementsCS(nCountSublatticeCS, 2, k) = j
                cycle LOOP_Sub2Names
            end if
        end do
    end do LOOP_Sub2Names

    ! Read in the charge of each constituent on the first sublattice.
    ! This seems unnecessary so I'm going to ignore it for now:
    read (1,*,IOSTAT = INFO) dSublatticeChargeCS(nCountSublatticeCS,1,1:nSublatticeElementsCS(nCountSublatticeCS,1))

    ! I think that this entry represents the constituent IDs on the first sublattice (ignore for now):
    read (1,*,IOSTAT = INFO) iChemicalGroupCS(nCountSublatticeCS,1,1:nSublatticeElementsCS(nCountSublatticeCS,1))

    ! Read in the charge of each constituent on the second sublattice.
    ! This seems unnecessary so I'm going to ignore it for now:
    read (1,*,IOSTAT = INFO) dSublatticeChargeCS(nCountSublatticeCS,2,1:nSublatticeElementsCS(nCountSublatticeCS,2))

    ! I think that this entry represents the constituent IDs on the second sublattice (ignore for now):
    read (1,*,IOSTAT = INFO) iChemicalGroupCS(nCountSublatticeCS,2,1:nSublatticeElementsCS(nCountSublatticeCS,2))

    ! This entry appears to represent the IDs matching constituents on the first sublattice to species:
    nA2X2 = nSublatticeElementsCS(nCountSublatticeCS,1) * nSublatticeElementsCS(nCountSublatticeCS,2)
    read (1,*,IOSTAT = INFO) iConstituentSublatticeCS(nCountSublatticeCS, 1, 1:nA2X2)

    ! This entry appears to represent the IDs matching constituents on the second sublattice to species:
    read (1,*,IOSTAT = INFO) iConstituentSublatticeCS(nCountSublatticeCS, 2, 1:nA2X2)

    ! Set up default pair IDs and coordination numbers
    ! dCoordinationNumberCS(nCountSublatticeCS,1:nMaxSpeciesPhaseCS,1:4) = 6D0
    dCoordinationNumberCS(nCountSublatticeCS,1:nMaxSpeciesPhaseCS,1:4) = 0D0
    do y = 1, nSublatticeElementsCS(nCountSublatticeCS,2)
        LOOP_sroPairsOuter: do x = 1, nSublatticeElementsCS(nCountSublatticeCS,2)
            if (x == y) then
                p = (x - 1) * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
            else if (x > y) then
                cycle LOOP_sroPairsOuter
            else
                p = (nSublatticeElementsCS(nCountSublatticeCS,2) + (x - 1) + ((y-2)*(y-1)/2)) &
                  * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
            end if
            do k = 1, nSublatticeElementsCS(nCountSublatticeCS,1)
                LOOP_sroPairsInner: do j = 1, nSublatticeElementsCS(nCountSublatticeCS,1)
                    if (j == k) then
                        l = j
                    else if (j > k) then
                        cycle LOOP_sroPairsInner
                    else
                        l = nSublatticeElementsCS(nCountSublatticeCS,1) + j + ((k-2)*(k-1)/2)
                    end if
                    iPairIDCS(nCountSublatticeCS, l + p, 1) = j
                    iPairIDCS(nCountSublatticeCS, l + p, 2) = k
                    iPairIDCS(nCountSublatticeCS, l + p, 3) = x + nSublatticeElementsCS(nCountSublatticeCS,1)
                    iPairIDCS(nCountSublatticeCS, l + p, 4) = y + nSublatticeElementsCS(nCountSublatticeCS,1)
                    end do LOOP_sroPairsInner
            end do
        end do LOOP_sroPairsOuter
    end do

    ! Parse the co-ordination numbers corresponding to all pairs in the phase.
    ! Note that since these lines correspond to pairs, there will always be the same number of
    ! integers and reals on a line, but the number of lines corresponds to the number of pairs.
    ! The SUBG model considers quadruplets, which is why there are four sets.
    ! Note that a quadruplet must satisfy the following constraint:
    ! q(i)/Z(i) + q(j)/Z(j) =  q(x)/Z(x) + q(y)/Z(y)
    allocate(lPairSet(nSpeciesPhaseCS(i) - nSpeciesPhaseCS(i-1)))
    lPairSet = .FALSE.
    LOOP_readPairs: do n = 1, nPairsSROCS(nCountSublatticeCS,2)
        read (1,*,IOSTAT = INFO) j, k, x, y, dTempVec(1:4)
        x = x - nSublatticeElementsCS(nCountSublatticeCS,1)
        y = y - nSublatticeElementsCS(nCountSublatticeCS,1)
        if (x == y) then
            p = (x - 1) * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
        else if (x > y) then
            cycle LOOP_readPairs
        else
            p = (nSublatticeElementsCS(nCountSublatticeCS,2) + (x - 1) + ((y-2)*(y-1)/2)) &
              * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
        end if
        if (j == k) then
            l = j
        else if (j > k) then
            cycle LOOP_readPairs
        else
            l = nSublatticeElementsCS(nCountSublatticeCS,1) + j + ((k-2)*(k-1)/2)
        end if
        dCoordinationNumberCS(nCountSublatticeCS, l + p, 1) = dTempVec(1)
        dCoordinationNumberCS(nCountSublatticeCS, l + p, 2) = dTempVec(2)
        dCoordinationNumberCS(nCountSublatticeCS, l + p, 3) = dTempVec(3)
        dCoordinationNumberCS(nCountSublatticeCS, l + p, 4) = dTempVec(4)
        lPairSet(l + p) = .TRUE.
    end do LOOP_readPairs

    ! Increase pairs counter to include default pairs
    nPairsSROCS(nCountSublatticeCS,2) = nSpeciesPhaseCS(i) - nSpeciesPhaseCS(i-1)

    ! This loop sets default coordination numbers for quadruplets not explicitly listed in data file
    LOOP_allSROPairs: do k = 1, nPairsSROCS(nCountSublatticeCS,2)

        ! If coordinations already set, skip rest
        if (lPairSet(k)) cycle LOOP_allSROPairs

        ! Constituent indices:
        a = iPairIDCS(nCountSublatticeCS,k,1)
        b = iPairIDCS(nCountSublatticeCS,k,2)
        x = iPairIDCS(nCountSublatticeCS,k,3) - nSublatticeElementsCS(nCountSublatticeCS,1)
        y = iPairIDCS(nCountSublatticeCS,k,4) - nSublatticeElementsCS(nCountSublatticeCS,1)

        ! Constituent charges
        qa = dSublatticeChargeCS(nCountSublatticeCS,1,a)
        qb = dSublatticeChargeCS(nCountSublatticeCS,1,b)
        qx = dSublatticeChargeCS(nCountSublatticeCS,2,x)
        qy = dSublatticeChargeCS(nCountSublatticeCS,2,y)

        if ((a /= b) .AND. (x == y)) then
            p = (x - 1) * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
            za = dCoordinationNumberCS(nCountSublatticeCS, p + a, 1)
            zb = dCoordinationNumberCS(nCountSublatticeCS, p + b, 1)

            dCoordinationNumberCS(nCountSublatticeCS, k, 1) = za
            dCoordinationNumberCS(nCountSublatticeCS, k, 2) = zb
            dCoordinationNumberCS(nCountSublatticeCS, k, 3) = (qx + qy) / ((qa / za) + (qb / zb))
            dCoordinationNumberCS(nCountSublatticeCS, k, 4) = (qx + qy) / ((qa / za) + (qb / zb))
        else if ((a == b) .AND. (x /= y)) then
            p = (x - 1) * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
            zx = dCoordinationNumberCS(nCountSublatticeCS, p + a, 3)
            p = (y - 1) * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
            zy = dCoordinationNumberCS(nCountSublatticeCS, p + a, 3)

            dCoordinationNumberCS(nCountSublatticeCS, k, 1) = (qa + qb) / ((qx / zx) + (qy / zy))
            dCoordinationNumberCS(nCountSublatticeCS, k, 2) = (qa + qb) / ((qx / zx) + (qy / zy))
            dCoordinationNumberCS(nCountSublatticeCS, k, 3) = zx
            dCoordinationNumberCS(nCountSublatticeCS, k, 4) = zy
        else if ((a /= b) .AND. (x /= y)) then
            ! Indices for AA/XY and BB/XY
            p = (nSublatticeElementsCS(nCountSublatticeCS,2) + (x - 1) + ((y-2)*(y-1)/2)) &
              * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
            iaaxy = a + p
            ibbxy = b + p
            ! Indices for AB/XX and AB/YY
            l = nSublatticeElementsCS(nCountSublatticeCS,1) + a + ((b-2)*(b-1)/2)
            p = (x - 1) * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
            iabxx = l + p
            p = (y - 1) * (nSublatticeElementsCS(nCountSublatticeCS,1) * (nSublatticeElementsCS(nCountSublatticeCS,1) + 1) / 2)
            iabyy = l + p
            ! Coordinations of specific species for the above quadruplets
            za = dCoordinationNumberCS(nCountSublatticeCS,iaaxy,1)
            zb = dCoordinationNumberCS(nCountSublatticeCS,ibbxy,1)
            zx = dCoordinationNumberCS(nCountSublatticeCS,iabxx,3)
            zy = dCoordinationNumberCS(nCountSublatticeCS,iabyy,3)
            ! Equation 24 from part iv paper
            dF = (1D0/8D0)*((qa/za)+(qb/zb)+(qx/zx)+(qy/zy))
            ! Equation 23 from part iv paper
            dCoordinationNumberCS(nCountSublatticeCS, k, 1) = &
                                  1D0 / (((zx/(qx*dCoordinationNumberCS(nCountSublatticeCS,iabxx,1))) &
                                        + (zy/(qy*dCoordinationNumberCS(nCountSublatticeCS,iabyy,1)))) * dF)
            dCoordinationNumberCS(nCountSublatticeCS, k, 2) = &
                                  1D0 / (((zx/(qx*dCoordinationNumberCS(nCountSublatticeCS,iabxx,2))) &
                                        + (zy/(qy*dCoordinationNumberCS(nCountSublatticeCS,iabyy,2)))) * dF)
            dCoordinationNumberCS(nCountSublatticeCS, k, 3) = &
                                  1D0 / (((za/(qa*dCoordinationNumberCS(nCountSublatticeCS,iaaxy,3))) &
                                        + (zb/(qb*dCoordinationNumberCS(nCountSublatticeCS,ibbxy,3)))) * dF)
            dCoordinationNumberCS(nCountSublatticeCS, k, 4) = &
                                  1D0 / (((za/(qa*dCoordinationNumberCS(nCountSublatticeCS,iaaxy,4))) &
                                        + (zb/(qb*dCoordinationNumberCS(nCountSublatticeCS,ibbxy,4)))) * dF)
        end if
    end do LOOP_allSROPairs

    ! Copy previously-read end member info into appropriate variables before it gets overwritten by
    ! quadruplet data calculated below.
    cPairNameCS(nCountSublatticeCS,1:nPairsSROCS(nCountSublatticeCS,1)) = &
                cSpeciesNameCS((nSpeciesPhaseCS(i-1)+1):(nSpeciesPhaseCS(i-1)+nPairsSROCS(nCountSublatticeCS,1)))
    dStoichSpeciesOld = dStoichSpeciesCS(1:nSpeciesCS,1:nElementsCS)
    dStoichPairsCS(nCountSublatticeCS,1:nPairsSROCS(nCountSublatticeCS,2),1:nElementsCS) &
                  = dStoichSpeciesCS((nSpeciesPhaseCS(i-1) + 1):nSpeciesPhaseCS(i),1:nElementsCS)
    dStoichSpeciesCS((nSpeciesPhaseCS(i-1) + 1):nSpeciesPhaseCS(i),1:nElementsCS) = 0D0

    ! Loop through all pairs to calculate stoichiometry entries for quadruplets:
    do j = 1, nPairsSROCS(nCountSublatticeCS,2)
        a = iSublatticeElementsCS(nCountSublatticeCS,1,iPairIDCS(nCountSublatticeCS, j, 1))
        b = iSublatticeElementsCS(nCountSublatticeCS,1,iPairIDCS(nCountSublatticeCS, j, 2))
        x = iSublatticeElementsCS(nCountSublatticeCS,2,iPairIDCS(nCountSublatticeCS, j, 3) &
          - nSublatticeElementsCS(nCountSublatticeCS,1))
        y = iSublatticeElementsCS(nCountSublatticeCS,2,iPairIDCS(nCountSublatticeCS, j, 4) &
          - nSublatticeElementsCS(nCountSublatticeCS,1))

        ! Matching 4 pairs version
        l = j + nSpeciesPhaseCS(i-1)

        ! Just get the quads directly version
        if (a > 0) dStoichSpeciesCS(l,a) = dStoichSpeciesCS(l,a) + (1D0 / dCoordinationNumberCS(nCountSublatticeCS, j, 1))
        if (b > 0) dStoichSpeciesCS(l,b) = dStoichSpeciesCS(l,b) + (1D0 / dCoordinationNumberCS(nCountSublatticeCS, j, 2))
        if (x > 0) dStoichSpeciesCS(l,x) = dStoichSpeciesCS(l,x) + (1D0 / dCoordinationNumberCS(nCountSublatticeCS, j, 3))
        if (y > 0) dStoichSpeciesCS(l,y) = dStoichSpeciesCS(l,y) + (1D0 / dCoordinationNumberCS(nCountSublatticeCS, j, 4))

        ! Create quadruplet names
        cSpeciesNameCS(j + nSpeciesPhaseCS(i-1)) = TRIM(cConstituentNames1(iPairIDCS(nCountSublatticeCS, j, 1))) // '-' &
                                                // TRIM(cConstituentNames1(iPairIDCS(nCountSublatticeCS, j, 2))) // '-' &
                                                // TRIM(cConstituentNames2(iPairIDCS(nCountSublatticeCS, j, 3) &
                                                - nSublatticeElementsCS(nCountSublatticeCS,1)))                  // '-' &
                                                // TRIM(cConstituentNames2(iPairIDCS(nCountSublatticeCS, j, 4) &
                                                - nSublatticeElementsCS(nCountSublatticeCS,1)))

    end do

    ! Loop through excess mixing parameters:
    j = 0
    LOOP_ExcessMixingSUBG: do
        j = j + 1
        ! Read in number of constituents involved in parameter:
        read (1,*,IOSTAT = INFO) iRegularParamCS(nParamCS+1,1)

        ! The end of the parameter listing is marked by "0":
        if (iRegularParamCS(nParamCS+1,1) == 0) exit LOOP_ExcessMixingSUBG

        ! Check if the parameter is binary or ternary:
        if ((iRegularParamCS(nParamCS+1,1) == 3) .OR. (iRegularParamCS(nParamCS+1,1) == 4)) then

            ! Count the number of parameters:
            nParamCS = nParamCS + 1

            ! Mixing terms:
            read (1,*,IOSTAT = INFO) cRegularParamCS(nParamCS), iRegularParamCS(nParamCS,2:9)
            if (.NOT.((cRegularParamCS(nParamCS) == 'G') &
                .OR. (cRegularParamCS(nParamCS) == 'Q') .OR. (cRegularParamCS(nParamCS) == 'R') &
                 .OR. (cRegularParamCS(nParamCS) == 'B'))) then
                INFO = 10000 + 1000*j + i
                return
            end if

            ! According to Patrice Chartrand, he has no idea what these two lines mean. Ignore.
            read (1,*,IOSTAT = INFO) dTempVec(1:6)
            read (1,*,IOSTAT = INFO) dTempVec(1:6)

            ! Read in the excess gibbs energy of mixing terms.
            read (1,*,IOSTAT = INFO) iRegularParamCS(nParamCS,10:11), dRegularParamCS(nParamCS,1:6)

        else
            !! This parameter is not recognized; record an error.
            INFO = 10000 + 1000*j + i
            return
        end if

    end do LOOP_ExcessMixingSUBG

    ! Report an error if necessary:
    if (INFO /= 0) INFO = 1600 + i

    deallocate(lPairSet)

    return

end subroutine ParseCSDataBlockSUBG
