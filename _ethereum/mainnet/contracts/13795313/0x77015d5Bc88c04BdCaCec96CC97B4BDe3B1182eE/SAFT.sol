pragma solidity 0.8.7;

import "./ERC20.sol";
import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./TimeHelpers.sol";

/**
 * @title SAFT
 */
contract SAFT is Initializable, AccessControlEnumerableUpgradeable {

    uint256 constant private _SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant private _MONTHS_PER_YEAR = 12;

    enum TimeUnit {
        DAY,
        MONTH,
        YEAR
    }

    enum BeneficiaryStatus {
        UNKNOWN,
        CONFIRMED,
        ACTIVE,
        TERMINATED
    }

    struct Plan {
        uint256 totalVestingDuration; // months
        uint256 vestingCliff; // months
        TimeUnit vestingIntervalTimeUnit;
        uint256 vestingInterval; // amount of days/months/years
    }

    struct Beneficiary {
        BeneficiaryStatus status;
        uint256 planId;
        uint256 startMonth;
        uint256 fullAmount;
        uint256 amountAfterLockup;
    }

    event PlanCreated(
        uint256 indexed id
    );

    event VestingStarted(
        address indexed beneficiary
    );

    event BeneficiaryConnectedToPlan(
        uint256 indexed id,
        address indexed beneficiary
    );

    event VestingTerminated(
        address indexed beneficiary
    );

    event Retrieved(
        address indexed beneficiary,
        uint256 amount
    );

    // array of Plan configs
    Plan[] private _plans;

    ERC20 public token;

    TimeHelpers public timeHelpers;

    bytes32 public constant VESTING_MANAGER_ROLE = keccak256("VESTING_MANAGER_ROLE");

    //       beneficiary => beneficiary plan params
    mapping (address => Beneficiary) private _beneficiaries;

    //       beneficiary => balanceLeft
    mapping (address => uint) private _beneficiaryToBalanceLeft;

    mapping (address => uint) private _availableAmountAfterTermination;

    uint256 public balanceUsed;

    modifier onlyVestingManager() {
        require(
            hasRole(VESTING_MANAGER_ROLE, _msgSender()),
            "VESTING_MANAGER_ROLE required"
        );
        _;
    }

    /**
     * @dev Allows Vesting manager to activate a vesting plan
     * 
     * Requirements:
     * 
     * - Beneficiary address must be already confirmed.
     */
    function startVesting(address beneficiary) external onlyVestingManager {
        require(
            _beneficiaries[beneficiary].status == BeneficiaryStatus.CONFIRMED,
            "Beneficiary status is incorrect"
        );
        require(
            token.balanceOf(address(this)) >= balanceUsed + _beneficiaries[beneficiary].fullAmount,
            "Not enough balance"
        );
        _beneficiaries[beneficiary].status = BeneficiaryStatus.ACTIVE;
        balanceUsed += _beneficiaries[beneficiary].fullAmount;
        emit VestingStarted(beneficiary);
    }

    /**
     * @dev Allows Vesting manager to define and add a Plan.
     * 
     * Requirements:
     * 
     * - Vesting cliff period must be less than or equal to the full period.
     * - Vesting step time unit must be in days, months, or years.
     * - Total vesting duration must equal vesting cliff plus entire vesting schedule.
     */
    function addPlan(
        uint256 vestingCliff, // months
        uint256 totalVestingDuration, // months
        TimeUnit vestingIntervalTimeUnit, // 0 - day 1 - month 2 - year
        uint256 vestingInterval // months or days or years
    )
        external
        onlyVestingManager
    {
        require(totalVestingDuration > 0, "Vesting duration can't be zero");
        require(vestingInterval > 0, "Vesting interval can't be zero");
        require(totalVestingDuration >= vestingCliff, "Lock period exceeds whole period");
        if (vestingIntervalTimeUnit == TimeUnit.MONTH) {
            uint256 vestingDurationAfterCliff = totalVestingDuration - vestingCliff;
            require(
                vestingDurationAfterCliff % vestingInterval == 0,
                "Intervals should be equal"
            );
        } else if (vestingIntervalTimeUnit == TimeUnit.YEAR) {
            uint256 vestingDurationAfterCliff = totalVestingDuration - vestingCliff;
            require(
                vestingDurationAfterCliff % (vestingInterval * _MONTHS_PER_YEAR) == 0,
                "Intervals should be equal"
            );
        }
        
        _plans.push(Plan({
            totalVestingDuration: totalVestingDuration,
            vestingCliff: vestingCliff,
            vestingIntervalTimeUnit: vestingIntervalTimeUnit,
            vestingInterval: vestingInterval
        }));
        emit PlanCreated(_plans.length);
    }

    /**
     * @dev Allows Vesting manager to register a beneficiary to a Plan.
     * 
     * Requirements:
     * 
     * - Plan must already exist.
     * - The vesting amount must be less than or equal to the full allocation.
     * - The beneficiary address must not already be included in the any other Plan.
     */
    function connectBeneficiaryToPlan(
        address beneficiary,
        uint256 planId,
        uint256 startMonth,
        uint256 fullAmount,
        uint256 lockupAmount
    )
        external
        onlyVestingManager
    {
        require(_plans.length >= planId && planId > 0, "Plan does not exist");
        require(fullAmount >= lockupAmount, "Incorrect amounts");
        require(_beneficiaries[beneficiary].status == BeneficiaryStatus.UNKNOWN, "Beneficiary is already added");
        if (_plans[planId - 1].vestingIntervalTimeUnit == TimeUnit.DAY) {
            uint256 vestingDurationInDays = _daysBetweenMonths(
                startMonth + _plans[planId - 1].vestingCliff,
                startMonth + _plans[planId - 1].totalVestingDuration
            );
            require(
                vestingDurationInDays % _plans[planId - 1].vestingInterval == 0,
                "Intervals should be equal"
            );
        }
        _beneficiaries[beneficiary] = Beneficiary({
            status: BeneficiaryStatus.CONFIRMED,
            planId: planId,
            startMonth: startMonth,
            fullAmount: fullAmount,
            amountAfterLockup: lockupAmount
        });
        _beneficiaryToBalanceLeft[beneficiary] = fullAmount;
        emit BeneficiaryConnectedToPlan(planId, beneficiary);
    }

    /**
     * @dev Allows Vesting manager to terminate a vesting plan.
     * 
     * Requirements:
     * 
     * - Vesting must be active.
     */
    function stopVesting(address beneficiary) external onlyVestingManager {
        require(
            _beneficiaries[beneficiary].status == BeneficiaryStatus.ACTIVE,
            "Beneficiary should be active"
        );
        _beneficiaries[beneficiary].status = BeneficiaryStatus.TERMINATED;
        _availableAmountAfterTermination[beneficiary] = calculateVestedAmount(beneficiary);
        balanceUsed -= _beneficiaries[beneficiary].fullAmount - _availableAmountAfterTermination[beneficiary];
        emit VestingTerminated(beneficiary);
    }

    /**
     * @dev Allows Beneficiary to retrieve vested tokens.
     */
    function retrieve(address beneficiary) external {
        require(beneficiary == _msgSender() || hasRole(VESTING_MANAGER_ROLE, _msgSender()), "Message sender is incorrect");
        require(isBeneficiaryRegistered(beneficiary), "Beneficiary is not registered");
        uint256 vestedAmount = 0;
        if (isVestingActive(beneficiary)) {
            vestedAmount = calculateVestedAmount(beneficiary);
        } else {
            vestedAmount = _availableAmountAfterTermination[beneficiary];
        }
        uint256 allowedBalance = _beneficiaryToBalanceLeft[beneficiary];
        uint256 fullAmount = _beneficiaries[beneficiary].fullAmount;
        if (vestedAmount > fullAmount - allowedBalance) {
            _beneficiaryToBalanceLeft[beneficiary] -= vestedAmount - (fullAmount - allowedBalance);
            balanceUsed -= vestedAmount - (fullAmount - allowedBalance);
            require(
                token.transfer(
                    beneficiary,
                    vestedAmount - (fullAmount - allowedBalance)
                ),
                "Error of token send"
            );
            emit Retrieved(beneficiary, vestedAmount - (fullAmount - allowedBalance));
        }
    }

    /**
     * @dev Returns a beneficiary's vesting amount left.
     */
    function getBeneficiaryBalanceLeft(address beneficiary) external view returns (uint)  {
        if (_beneficiaries[beneficiary].status == BeneficiaryStatus.TERMINATED) {
            return 0;
        }
        return _beneficiaryToBalanceLeft[beneficiary];
    }

    /**
     * @dev Returns vesting start month of the beneficiary's Plan.
     */
    function getStartMonth(address beneficiary) external view returns (uint) {
        return _beneficiaries[beneficiary].startMonth;
    }

    /**
     * @dev Returns the final vesting date of the beneficiary's Plan.
     */
    function getFinishVestingTime(address beneficiary) external view returns (uint) {
        Beneficiary memory beneficiaryPlan = _beneficiaries[beneficiary];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];
        return timeHelpers.monthToTimestamp(beneficiaryPlan.startMonth + planParams.totalVestingDuration);
    }

    /**
     * @dev Returns the vesting cliff period in months.
     */
    function getVestingCliffInMonth(address beneficiary) external view returns (uint) {
        return _plans[_beneficiaries[beneficiary].planId - 1].vestingCliff;
    }

    /**
     * @dev Returns the locked and unlocked (full) amount of tokens allocated to
     * the beneficiary address in Plan.
     */
    function getFullAmount(address beneficiary) external view returns (uint) {
        return _beneficiaries[beneficiary].fullAmount;
    }

    /**
     * @dev Returns the timestamp when vesting cliff ends and periodic vesting
     * begins.
     */
    function getLockupPeriodEndTimestamp(address beneficiary) external view returns (uint) {
        Beneficiary memory beneficiaryPlan = _beneficiaries[beneficiary];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];
        return timeHelpers.monthToTimestamp(beneficiaryPlan.startMonth + planParams.vestingCliff);
    }

    /**
     * @dev Returns the time of the next vesting event.
     */
    function getTimeOfNextVest(address beneficiary) external view returns (uint) {

        Beneficiary memory beneficiaryPlan = _beneficiaries[beneficiary];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];

        uint256 firstVestingMonth = beneficiaryPlan.startMonth + planParams.vestingCliff;
        uint256 lockupEndTimestamp = timeHelpers.monthToTimestamp(firstVestingMonth);
        if (block.timestamp < lockupEndTimestamp) {
            return lockupEndTimestamp;
        }
        require(
            block.timestamp < timeHelpers.monthToTimestamp(beneficiaryPlan.startMonth + planParams.totalVestingDuration),
            "Vesting is over"
        );
        require(beneficiaryPlan.status != BeneficiaryStatus.TERMINATED, "Vesting was stopped");
        
        uint256 currentMonth = timeHelpers.getCurrentMonth();
        if (planParams.vestingIntervalTimeUnit == TimeUnit.DAY) {
            uint daysPassedBeforeCurrentMonth = _daysBetweenMonths(firstVestingMonth, currentMonth);
            uint256 currentMonthBeginningTimestamp = timeHelpers.monthToTimestamp(currentMonth);
            uint256 daysPassedInCurrentMonth = (block.timestamp - currentMonthBeginningTimestamp) / _SECONDS_PER_DAY;
            uint256 daysPassedBeforeNextVest = _calculateNextVestingStep(
                daysPassedBeforeCurrentMonth + daysPassedInCurrentMonth,
                planParams.vestingInterval
            );
            return currentMonthBeginningTimestamp + (daysPassedBeforeNextVest - daysPassedBeforeCurrentMonth) * _SECONDS_PER_DAY;
        } else if (planParams.vestingIntervalTimeUnit == TimeUnit.MONTH) {
            return timeHelpers.monthToTimestamp(
                firstVestingMonth + _calculateNextVestingStep(currentMonth - firstVestingMonth, planParams.vestingInterval)
            );
        } else if (planParams.vestingIntervalTimeUnit == TimeUnit.YEAR) {
            return timeHelpers.monthToTimestamp(
                firstVestingMonth + _calculateNextVestingStep(
                    currentMonth - firstVestingMonth,
                    planParams.vestingInterval * _MONTHS_PER_YEAR
                )
            );
        } else {
            revert("Vesting timeunit is incorrect");
        }
    }

    /**
     * @dev Returns the Plan parameters.
     * 
     * Requirements:
     * 
     * - Plan must already exist.
     */
    function getPlan(uint256 planId) external view returns (Plan memory) {
        require(planId > 0 && planId <= _plans.length, "Plan Round does not exist");
        return _plans[planId - 1];
    }

    /**
     * @dev Returns the Plan parameters for a beneficiary address.
     * 
     * Requirements:
     * 
     * - Beneficiary address must be registered to an Plan.
     */
    function getBeneficiaryPlanParams(address beneficiary) external view returns (Beneficiary memory) {
        require(_beneficiaries[beneficiary].status != BeneficiaryStatus.UNKNOWN, "Beneficiary is not registered");
        return _beneficiaries[beneficiary];
    }

    function initialize(address tokenAddress, address timeHelpersAddress) public initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(VESTING_MANAGER_ROLE, _msgSender());
        token = ERC20(tokenAddress);
        timeHelpers = TimeHelpers(timeHelpersAddress);
    }

    /**
     * @dev Calculates and returns the vested token amount.
     */
    function calculateVestedAmount(address wallet) public view returns (uint256 vestedAmount) {
        Beneficiary memory beneficiaryPlan = _beneficiaries[wallet];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];
        vestedAmount = 0;
        uint256 currentMonth = timeHelpers.getCurrentMonth();
        if (currentMonth >= beneficiaryPlan.startMonth + planParams.vestingCliff) {
            vestedAmount = beneficiaryPlan.amountAfterLockup;
            if (currentMonth >= beneficiaryPlan.startMonth + planParams.totalVestingDuration) {
                vestedAmount = beneficiaryPlan.fullAmount;
            } else {
                uint256 payment = _getSinglePaymentSize(
                    wallet,
                    beneficiaryPlan.fullAmount,
                    beneficiaryPlan.amountAfterLockup
                );
                vestedAmount = vestedAmount + (payment * _getNumberOfCompletedVestingEvents(wallet));
            }
        }
    }

    /**
     * @dev Confirms whether the beneficiary is active in the Plan.
     */
    function isVestingActive(address beneficiary) public view returns (bool) {
        return _beneficiaries[beneficiary].status == BeneficiaryStatus.ACTIVE;
    }

    /**
     * @dev Confirms whether the beneficiary is registered in a Plan.
     */
    function isBeneficiaryRegistered(address beneficiary) public view returns (bool) {
        return _beneficiaries[beneficiary].status != BeneficiaryStatus.UNKNOWN;
    }

    /**
     * @dev Returns the number of vesting events that have completed.
     */
    function _getNumberOfCompletedVestingEvents(address wallet) internal view returns (uint) {
        
        Beneficiary memory beneficiaryPlan = _beneficiaries[wallet];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];

        uint256 firstVestingMonth = beneficiaryPlan.startMonth + planParams.vestingCliff;
        if (block.timestamp < timeHelpers.monthToTimestamp(firstVestingMonth)) {
            return 0;
        } else {
            uint256 currentMonth = timeHelpers.getCurrentMonth();
            if (planParams.vestingIntervalTimeUnit == TimeUnit.DAY) {
                return _daysBetweenMonths(firstVestingMonth, currentMonth) + 
                    ((block.timestamp - timeHelpers.monthToTimestamp(currentMonth)) / _SECONDS_PER_DAY) / planParams.vestingInterval;
            } else if (planParams.vestingIntervalTimeUnit == TimeUnit.MONTH) {
                return (currentMonth - firstVestingMonth) / planParams.vestingInterval;
            } else if (planParams.vestingIntervalTimeUnit == TimeUnit.YEAR) {
                return ((currentMonth - firstVestingMonth) / _MONTHS_PER_YEAR) / planParams.vestingInterval;
            } else {
                revert("Unknown time unit");
            }
        }
    }

    /**
     * @dev Returns the number of total vesting events.
     */
    function _getNumberOfAllVestingEvents(address wallet) internal view returns (uint) {
        Beneficiary memory beneficiaryPlan = _beneficiaries[wallet];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];
        if (planParams.vestingIntervalTimeUnit == TimeUnit.DAY) {
            return _daysBetweenMonths(
                beneficiaryPlan.startMonth + planParams.vestingCliff,
                beneficiaryPlan.startMonth + planParams.totalVestingDuration
            ) / planParams.vestingInterval;
        } else if (planParams.vestingIntervalTimeUnit == TimeUnit.MONTH) {
            return (planParams.totalVestingDuration - planParams.vestingCliff) / planParams.vestingInterval;
        } else if (planParams.vestingIntervalTimeUnit == TimeUnit.YEAR) {
            return (planParams.totalVestingDuration - planParams.vestingCliff) / _MONTHS_PER_YEAR / planParams.vestingInterval;
        } else {
            revert("Unknown time unit");
        }
    }

    /**
     * @dev Returns the amount of tokens that are unlocked in each vesting
     * period.
     */
    function _getSinglePaymentSize(
        address wallet,
        uint256 fullAmount,
        uint256 afterLockupPeriodAmount
    )
        internal
        view
        returns(uint)
    {
        return (fullAmount - afterLockupPeriodAmount) / _getNumberOfAllVestingEvents(wallet);
    }

    function _daysBetweenMonths(uint256 beginMonth, uint256 endMonth) private view returns (uint256) {
        assert(beginMonth <= endMonth);
        uint256 beginTimestamp = timeHelpers.monthToTimestamp(beginMonth);
        uint256 endTimestamp = timeHelpers.monthToTimestamp(endMonth);
        uint256 secondsPassed = endTimestamp - beginTimestamp;
        require(secondsPassed % _SECONDS_PER_DAY == 0, "Internal error in calendar");
        return secondsPassed / _SECONDS_PER_DAY;
    }

    /**
     * @dev returns time of next vest in abstract time units named "step"
     * Examples:
     *     if current step is 5 and vesting interval is 7 function returns 7.
     *     if current step is 17 and vesting interval is 7 function returns 21.
     */
    function _calculateNextVestingStep(uint256 currentStep, uint256 vestingInterval) private pure returns (uint256) {
        return currentStep + vestingInterval - currentStep % vestingInterval;
    }
}