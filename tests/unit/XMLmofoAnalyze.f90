MODULE PassFail
    USE ISO_FORTRAN_ENV, ONLY : i4k => INT32, r8k => REAL64
    IMPLICIT NONE
    !! author: Ian Porter
    !! date: 3/21/2015
    !!
    !! This module is used to identity whether the unit test has passed or failed
    !!
    PRIVATE
    PUBLIC :: Analyze, testid, all_tests_pass
    !
    INTEGER(i4k) :: testcnt   = 0                   !! Counter for the number of unit tests performed
    INTEGER(i4k) :: testnum   = 0                   !! Test number for unit test being performed (number resets for
                                                    !! unit test on new subroutine/function)
    INTEGER(i4k) :: utunit                          !! File unit # for writing output file for Unit Testing
    INTEGER(i4k) :: nfailures = 0                   !! Counter of # of failed unit tests
    REAL(r8k), PARAMETER :: delta_min = 1.0e-20_r8k !! Minimum value for dividing by if known = 0.0
    LOGICAL :: TestingPassed = .TRUE.               !! Flag to indicate whether all unit tests passed or not
    CHARACTER(LEN=20) :: testid                     !! Name of subroutine/function being tested
                                                    !! (Defined by user as start of each set of unit tests)
    CHARACTER(LEN=20) :: testid_prev                !! Name of previous subroutine/function tested. Used as a tracking tool only
    CHARACTER(LEN=*), PARAMETER :: filename = "xmlmofo_test_results.txt"
                                                    !! File name to write output info

    CONTAINS

        ELEMENTAL IMPURE FUNCTION Analyze (known, calc, criteria) RESULT(test_passed)
        IMPLICIT NONE
        !! author: Ian Porter
        !! date: 3/21/2015
        !!
        !! This subroutine analyzes the results of the unit test
        !!
        REAL(r8k), INTENT(IN) :: known      !! Expected value
        REAL(r8k), INTENT(IN) :: calc       !! Subroutine/function calculated value
        REAL(r8k), INTENT(IN) :: criteria   !! Acceptance criteria (fractional difference between known and calc values,
                                            !! relative to known)
        LOGICAL :: test_passed, file_exists

        INQUIRE(file=filename,exist=file_exists)
        IF (.NOT. file_exists) THEN
            OPEN(newunit=utunit,file=filename,status='replace',form='formatted')
        END IF

        ! Count the # of unit tests performed for each subroutine/function
        IF (testid /= testid_prev) THEN
            !! A new subroutine/function is being tested
            testnum = 1                 !! First unit test for this subroutine/function
            testid_prev = testid
        ELSE
            !! The subroutine/function was tested in the previous iteration
            testnum = testnum + 1
        END IF
        testcnt = testcnt + 1           !! Count the total number of unit tests that have been performed
        ! Check to see if the results of the unit test fall within the specified criteria
        IF (known == 0.0_r8k) THEN
            !! Criteria is defined as the fractional difference (i.e. criteria = 0.01 specifies 1% difference)
            IF (((calc - known) / delta_min) <= criteria) THEN
                !! The difference falls within the acceptance criteria
                CALL TestPass (known, calc)
                test_passed = .TRUE.
            ELSE
                !! The differences is greater than the acceptance criteria
                CALL TestFail (known, calc)
                test_passed = .FALSE.
            END IF
        ELSE
            !! Criteria is defined as the fractional difference (i.e. criteria = 0.01 specifies 1% difference)
            IF ((ABS(calc - known) / known) <= criteria) THEN
                !! The difference falls within the acceptance criteria
                CALL TestPass (known, calc)
                test_passed = .TRUE.
            ELSE
                !! The differences is greater than the acceptance criteria
                CALL TestFail (known, calc)
                test_passed = .FALSE.
            END IF
        END IF

        END FUNCTION Analyze

        SUBROUTINE TestPass (known, calc)
        IMPLICIT NONE
        !! author: Ian Porter
        !! date: 3/21/2015
        !!
        !! This subroutine indicates that a unit test has passed.
        !!
        REAL(r8k), INTENT(IN) :: known  !! Known value that subroutine/function tested should calulate
        REAL(r8k), INTENT(IN) :: calc   !! Calculated value from subroutine/function tested

        !! Write to the command window and unit testing output file
        WRITE (*,100)      testnum, TestID, known, calc
        WRITE (utunit,100) testnum, TestID, known, calc
100     FORMAT (/,'Unit Test # ',i4,' PASSED for Subroutine/Function ',a20, &
          &     /,'Expected = ',e14.7,' Calculated = ',e14.7)

        END SUBROUTINE TestPass

        SUBROUTINE TestFail (known, calc)
        IMPLICIT NONE
        !! author: Ian Porter
        !! date: 3/21/2015
        !!
        !! This subroutine indicates that a unit test has failed.
        !!
        REAL(r8k), INTENT(IN) :: known  !! Known value that subroutine/function tested should calulate
        REAL(r8k), INTENT(IN) :: calc   !! Calculated value from subroutine/function tested

        ! Write to the command window and unit testing output file
        WRITE (*,100)      testnum, TestID, known, calc
        WRITE (utunit,100) testnum, TestID, known, calc
100     FORMAT (/,'Unit Test # ',i4,' FAILED on Subroutine/Function ',a20, &
          &     /,'Expected = ',e14.7,' Calculated = ',e14.7)

        nfailures = nfailures + 1    !! Keep track of the number of cases that have failed
        TestingPassed = .FALSE.      !! Indicate that a unit test has failed

        END SUBROUTINE TestFail

        SUBROUTINE all_tests_pass ()
        IMPLICIT NONE
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! This subroutine indicates that all unit tests have passed
        !! Using ctest, the value "Test passed" is searched for to indicate passing.
        !!
        CHARACTER(LEN=*), PARAMETER :: test_passed_message = 'Test passed'

        WRITE(*,*) test_passed_message

        END SUBROUTINE all_tests_pass

END MODULE PassFail
