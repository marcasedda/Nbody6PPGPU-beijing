      SUBROUTINE MODIFY
*
*
*       Parameter modification at restart.
*       ----------------------------------
*
      INCLUDE 'common6.h'
      EXTERNAL VERIFY
*
#ifdef PARALLEL
#define MPIINIT 1
#else
#define MPIINIT 0
#endif
*
*       Read first, second or both lines (KSTART = 3, 4, 5).
      IF (KSTART.EQ.4) GO TO 10
*       Only control output RSp March 2019 (KSTART = 2)
      IF (KSTART.EQ.2) GO TO 11
*       Read new DTADJ, DELTAT, TADJ, TNEXT, TCRIT, QE & KZ(J), NCOMM (if > 0).
      if(rank.eq.0)then
      READ (5,*)  DTA, DT, TA, TN, TC, QE1, J, K, NCOM1
      end if
*
#if MPIINIT
      CALL MPI_BCAST(DTA,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(DT,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(TA,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(TN,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(TC,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(QE1,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(J,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(K,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(NCOM1,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
#endif
*
*       Set new parameters if corresponding input is non-zero.
      IF (DTA.LE.0.0) THEN
          DTA = DTADJ
      ELSE
          DTA = DTA
      END IF
*
      IF (DT.LE.0.0) THEN
          DT = DELTAT
      ELSE
          DT = DT
      END IF
*
      IF (TA.LE.0.0) THEN
          TADJ = MAX(TADJ - DTADJ + DTA,TIME)
      ELSE
          TADJ = MAX(TA-TOFF,TIME)
      END IF
*
      IF (TN.LE.0.0) THEN
          TNEXT = MAX(TNEXT - DELTAT + DT,TIME)
      ELSE
          TNEXT = MAX(TN-TOFF,TIME)
      END IF
*
      DTADJ = DTA
      DELTAT = DT
      IF (TC.GT.0.0) TCRIT = TC
      IF (QE1.GT.0.0) QE = QE1
*
*       See whether any options should be changed.
      IF (J.GT.0) THEN
         KZ(J) = K
         KZ273 = 0
         IF(J.EQ.27.AND.KZ(J).GT.2) THEN
            KZ273 = 3
            KZ(J) = KZ(J) - 2
         END IF
      END IF
*
      IF (NCOM1.GT.0) NCOMM = NCOM1
*
      if(rank.eq.0)WRITE (6,5)  J, K
    5 FORMAT (///,7X,'RESTART CHANGE OPTION KZ(',I2,') =',I2,/)
*
*       Read new ETAI, ETAR, ETAU, DTMIN, RMIN (IF > 0 & KSTART = 4 or 5).
   10 IF (KSTART.GE.4) THEN
          if(rank.eq.0)then
          READ (5,*)  ETA1, ETA2, ETA3, DTM, RM, NEWCR, NNBO, SMAX0, 
     &     GMN,GMX
          end if
#if MPIINIT
      CALL MPI_BCAST(ETA1,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(ETA2,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(ETA3,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(DTM,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(RM,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(NEWCR,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(NNBO,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(SMAX0,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(GMN,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
      CALL MPI_BCAST(GMX,1,MPI_REAL8,0,MPI_COMM_WORLD,ierr)
#endif
*
*       Check modification of integration parameters.
          IF (ETA1.GT.0.0) ETAI = ETA1
          IF (ETA2.GT.0.0) ETAR = ETA2
          IF (ETA3.GT.0.0) ETAU = ETA3
          IF (DTM.GT.0.0) THEN
              DTMIN = DTM
              SMIN = 2.0*DTM
          END IF
          IF (GMN.GT.0.0) GMIN = GMN
          IF (GMX.GT.0.0) GMAX = GMX
          IF (RM.GT.0.0) THEN
              RMIN = RM
              RMIN2 = RM**2
              RMIN22 = 4.0*RMIN2
          END IF
          IF (NEWCR.GT.0) NCRIT = NEWCR
          IF (NNBO.GT.0) NNBOPT = NNBO
          IF (SMAX0.GT.0) THEN
*     Check SMAX to make sure it have correct value
*     Allow step for HDF5 files to be larger than one. (R.Sp. Sep. 2021)
             HDFMAX = SMAX0
             IF(SMAX0.GT.1) THEN
                print*, 'Warning! SMAX > 1.0, reduce to 1.0.'
                SMAX = 1.0
             else
                DTNSMAX = 1.0
 99             IF(SMAX0/DTNSMAX.LE.0.75) THEN
                   DTNSMAX = 0.5D0*DTNSMAX
                   IF(DTNSMAX.GT.1E-19) GO TO 99
                END IF
                SMAX = DTNSMAX
             END IF
          END IF
*
      END IF
#ifdef TT
*** FlorentR - restart with new tensors
      IF (KZ(14).EQ.9) THEN
        CALL TTINIT
      ENDIF
*** FRenaud
#endif
 11   CONTINUE
      if (rank.eq.0) then
*       If no explicit new TCRIT given just go for another TCRIT of
*       common block.
          TTOT = TIME + TOFF
          TCRIT = TTOT + TCRIT
          if(rank.eq.0)then
             WRITE (6,12) TTOT/TCR0, TIME/TCR0, TCRIT/TCR0, TTOT, TIME,
     &            TCRIT
             WRITE (6,13) DTADJ, DELTAT, TADJ, TNEXT, TCRIT, QE, NCOMM
             WRITE (6,14) ETAI, ETAR, ETAU, DTMIN, RMIN, NNBOPT, SMAX,
     &            GMIN, GMAX
 12          FORMAT (' START AT TTOT/TIME ',2F16.8,' STOP INTENDED AT ',
     &            F16.8,' TCR0',/,' START AT TTOT/TIME ',2F16.8,
     &            ' STOP INTENDED AT ',F16.8,' NBODY-UNITS ',/)
 13          FORMAT (/,7X,'RESTART PARAMETERS:   DTADJ =',F7.3,
     &            '  DELTAT =',F7.3,'   TADJ =',F10.3,'   TNEXT =',
     &            F10.3,' TCRIT =',F10.3,' QE =',1P,E11.3,' NCOMM=',I4)
 14          FORMAT (/,7X,'                      ETAI =',F7.3,
     &            '  ETAR =',F7.3,'  ETAU =',F7.3,'  DTMIN =',1P,E11.3,
     &            '  RMIN =',E11.3,' NNBOPT =',I5,' SMAX =',E11.3,
     &            '  GMIN =',E11.3,' GMAX = ',E11.3,/)
          end if
*
   22    FORMAT (/,12X,'OPTIONS')
         WRITE (6,24)  (J,J=1,50),273
   24    FORMAT (9X,50I3,I4)
         WRITE (6,26)  (KZ(J),J=1,50),KZ273
   26    FORMAT (9X,51I3)
      end if
*
*
*       Perform a simple validation check on main input parameters.
      CALL VERIFY
*
*       Save the new parameters on tape/disc in case a restart is needed.
      CALL MYDUMP(1,1)
*
      RETURN
*
      END
