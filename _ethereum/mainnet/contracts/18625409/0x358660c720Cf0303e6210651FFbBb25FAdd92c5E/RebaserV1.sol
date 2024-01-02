// Thunderhead: https://github.com/thunderhead-labs


// Author(s)
// Addison Spiegel: https://addison.is
// Pierre Spiegel: https://pierre.wtf

pragma solidity 0.8.20;

import "./IERC20.sol";
import "./stFlip.sol";
import "./BurnerV1.sol";
import "./OutputV1.sol";
import "./MinterV1.sol";
import "./StateChainGateway.sol";
import "./Initializable.sol";
import "./ProxyAdmin.sol";
import "./SafeCast.sol";

/**
 * @title Rebaser contract for stFLIP
 * @notice Will be called by an offchain service to set the rebase factor.
 * Has protections so the rebase can't be too large or small. Fees come from
 * rebases, there is a fee claim function to claim fees.
 */
contract RebaserV1 is Initializable, Ownership {

    uint256 constant TIME_IN_YEAR = 31536000;

    uint16 public aprThresholdBps;         // uint16 sufficient
    uint16 public slashThresholdBps;       // uint16 sufficient
    uint32 public lastRebaseTime;          // uint32 sufficient
    uint32 public rebaseInterval;          // uint32 sufficient
    uint80 public servicePendingFee;       // uint80-88 sufficient
    uint80 public totalOperatorPendingFee;

    BurnerV1 public wrappedBurnerProxy;
    OutputV1 public wrappedOutputProxy;
    MinterV1 public wrappedMinterProxy;

    IERC20 public flip;
    stFlip public stflip;

    struct Operator {
        uint88 rewards;            // uint88 sufficient 
        uint80 pendingFee;         // uint80 sufficient
        uint88 slashCounter;       // uint88 sufficient
    }

    mapping(uint256 => Operator) public operators;

    event FeeClaim(address feeRecipient, uint256 indexed amount, bool indexed receivedFlip, uint256 indexed operatorId);
    event RebaserRebase(uint256 indexed apr, uint256 indexed stateChainBalance, uint256 previousSupply, uint256 indexed newSupply);
    event NewAprThreshold(uint256 indexed newAprThreshold);
    event NewSlashThreshold(uint256 indexed newSlashThreshold);
    event NewRebaseInterval(uint256 indexed newRebaseInterval);
    
    error RebaseTooSoon();
    error AprTooHigh(uint256 apr);
    error SupplyDecreaseTooHigh(uint256 decrease);
    error ValidatorAddressesDoNotMatch();
    error InputLengthsMustMatch();
    error ExcessiveFeeClaim();
    error NotFeeRecipientOrManager();

    constructor () {
        _disableInitializers();
    }


    /**
     * @notice Initializes the contract
     * @param addresses The addresses of the contracts to use: flip, burnerProxy, gov, feeRecipient, manager, stflip, outputProxy
     * @param aprThresholdBps_ The amount of bps to set apr threshold to
     * @param rebaseInterval_ The amount of time in seconds between rebases
     */
    function initialize(address[8] calldata addresses, uint256 aprThresholdBps_, uint256 slashThresholdBps_, uint256 rebaseInterval_) initializer public {
        flip = IERC20(addresses[0]);
        wrappedBurnerProxy = BurnerV1(addresses[1]);
        
        __AccessControlDefaultAdminRules_init(0, addresses[2]);
        _grantRole(MANAGER_ROLE, addresses[2]);
        _grantRole(MANAGER_ROLE, addresses[4]);
        _grantRole(FEE_RECIPIENT_ROLE, addresses[3]);

        stflip = stFlip(addresses[5]);
        wrappedOutputProxy = OutputV1(addresses[6]);
        wrappedMinterProxy = MinterV1(addresses[7]);

        slashThresholdBps = SafeCast.toUint16(slashThresholdBps_);
        aprThresholdBps = SafeCast.toUint16(aprThresholdBps_);
        rebaseInterval = SafeCast.toUint32(rebaseInterval_);


        lastRebaseTime = SafeCast.toUint32(block.timestamp);
    }

    /** Sets the APR threshold in bps
     * @param aprThresholdBps_ The amount of bps to set apr threshold to
     * @dev If the rebase exceeds this APR, then the rebase will revert
     */
    function setAprThresholdBps(uint256 aprThresholdBps_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        aprThresholdBps = SafeCast.toUint16(aprThresholdBps_);

        emit NewAprThreshold(aprThresholdBps_);
    }

    /** Sets slash threshold in bps
     * @param slashThresholdBps_ The number of bps to set slash threshold to
     * @dev If the supply decreases by this threshold, then the rebase will revert
     * @dev This is different from APR threshold because slashes would be much more serious
     */
    function setSlashThresholdBps(uint256 slashThresholdBps_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        slashThresholdBps = SafeCast.toUint16(slashThresholdBps_);

        emit NewSlashThreshold(slashThresholdBps_);
    }

    /** Sets minimum rebase interval
     * @param rebaseInterval_ The minimum unix time between rebases
     * @dev If a rebase occurs before this interval elapses, it will revert
     */
    function setRebaseInterval(uint256 rebaseInterval_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rebaseInterval = SafeCast.toUint32(rebaseInterval_);

        emit NewRebaseInterval(rebaseInterval_);
    }

    /** Calculates the new rebase factor based on the state chain validator balance
     * and whether or not a fee will be taken
     * @param epoch The epoch number of the rebase
     * @param validatorBalances The balances of the state chain validators
     * @param addresses The addresses of the state chain validators
     * @param takeFee Whether or not to claim fee
     * @dev There is no oracle support for Chainflip yet so we must run the oracle. We have an offchain service that
     * queries the countable validators on the Output address and submits the addresses along with their balances to this 
     * address. There is `aprThresholdBps` and `slashThresholdBps` to ensure that the oracle report is within reasonable bounds.
     * `_updateOperators` calls `_updateOperator` for each operator which changes the `rewards`, `slashCounter`, and `pendingFee`
     * in accordance with the balance report. We might disable `takeFee`
     * if there is a slash we need to make up for. Its also worth noting how `pendingFee` is a piece of the pool,
     * in the same way that pending burns are. 
     */
    function rebase (uint256 epoch, uint256[] calldata validatorBalances, bytes32[] calldata addresses, bool takeFee) external onlyRole(MANAGER_ROLE) {
        uint256 timeElapsed = block.timestamp - lastRebaseTime;
        if (timeElapsed < rebaseInterval) revert RebaseTooSoon();
        if (validatorBalances.length != addresses.length) revert InputLengthsMustMatch();

        (uint256 stateChainBalance, uint256 totalOperatorPendingFee_) = _updateOperators(validatorBalances, addresses, takeFee);
        uint256 currentSupply = stflip.totalSupply();

        uint256 newSupply = stateChainBalance + flip.balanceOf(address(wrappedOutputProxy)) - wrappedBurnerProxy.totalPendingBurns() - servicePendingFee - totalOperatorPendingFee_;
        uint256 apr = _validateSupplyChange(timeElapsed, currentSupply, newSupply);
        
        stflip.syncSupply(epoch, newSupply, rebaseInterval);
        lastRebaseTime = SafeCast.toUint32(block.timestamp);

        emit RebaserRebase(apr, stateChainBalance, currentSupply, newSupply);
    }

    /**
     * Internal function to loop through all operators and update them
     * @param validatorBalances the balances of all the state chain validators
     * @param addresses the addresses of all the state chain validators
     * @param takeFee whether or not `pendingFee` should increment for these operators
     * @return stateChainBalance the sum of all the countable validator balances
     * @return totalOperatorPendingFee_ the sum of all the operators pendingFees
     * @dev This function is called by `rebase`. It iterates through all the validators and their balances
     * to create a map of operators and their balances. This information is used to call `updateOperator`. 
     * We check the hash of the addresses to ensure that the oracle included all the necessary addresses.
     */
    function _updateOperators(uint256[] calldata validatorBalances, bytes32[] calldata addresses, bool takeFee) internal returns (uint256, uint256) {
        uint256 stateChainBalance;
        uint256 totalOperatorPendingFee_;
        uint256 operatorId;

        (OutputV1.ValidatorInfo[] memory validatorInfo, uint256 operatorCount, bool addressesEqual) = wrappedOutputProxy.getValidatorInfo(addresses);
        uint256[] memory operatorBalances = new uint256[](operatorCount);

        if (addressesEqual == false) revert ValidatorAddressesDoNotMatch();
        if (validatorBalances.length != addresses.length) revert InputLengthsMustMatch();

        uint256 validatorInfoLength = validatorInfo.length;
        for (uint i; i < validatorInfoLength; ++i) {
            if (validatorInfo[i].trackBalance == true) {
                operatorBalances[validatorInfo[i].operatorId] += validatorBalances[i];
                stateChainBalance += validatorBalances[i];
            }       
        }
        
        for (operatorId = 1; operatorId < operatorCount; operatorId++) {
            totalOperatorPendingFee_ += _updateOperator(operatorBalances[operatorId], operatorId, takeFee);
        }  

        totalOperatorPendingFee = SafeCast.toUint80(totalOperatorPendingFee_);

        return (stateChainBalance, totalOperatorPendingFee_);
    }

    /**
     * Updates individual operators. Performs meat of the rebase logic
     * @param operatorBalance The actual balance of the operator
     * @param operatorId The ID of the operator
     * @param takeFee Whether or not pendingFee should increment
     * @dev Calculates previous balance as total amount staked + total rewards - total unstaked - current slashCounter.
     * If the actual balance is greater than the current balance this means that there are rewards. We separate the current
     * balance into the positive and negative components to account for a possible overflow. The reward increment is 
     * the difference of these two values. We then check that the reward increment is greater than the slashCounter because
     * an operator should not be paid until they earn back a slash. We decrement the slashCounter until its zero and then
     * we increment the pendingFees by a specified percentage of the reward increase. If slashCounter is bigger than reward
     * increment then we just decrement slashCounter to reduce the deficit and if previousBalance is greater than the
     * actual operator balance then we increment slashCounter as there has been a slash. 
     */
    function _updateOperator(uint256 operatorBalance, uint256 operatorId, bool takeFee) internal returns (uint256) {
        uint256 rewardIncrement;
        uint96 staked;
        uint96 unstaked;
        uint16 serviceFeeBps;
        uint16 validatorFeeBps;
        (staked,unstaked,serviceFeeBps, validatorFeeBps) = wrappedOutputProxy.getOperatorInfo(operatorId);

        uint256 slashCounter_ = operators[operatorId].slashCounter;
        
        // in actuality, previousBalance = positivePreviousBalanceComponent - negativePreviousBalanceComponent
        // but, we separate them for the edge case where the negative component exceeds the positive component, which would cause an underflow
        uint256 positivePreviousBalanceComponent = staked + operators[operatorId].rewards;
        uint256 negativePreviousBalanceComponent = unstaked + slashCounter_;

        // mathematically equivalent to `if (operatorBalance >= previousBalance)` but we rearrange to account for the underflow possibility mentioned above:
        // operatorBalance >= previousBalance
        // operatorBalance >= positivePreviousBalanceComponent - negativePreviousBalanceComponent
        // operatorBalance + negativePreviousBalanceComponent >= positivePreviousBalanceComponent
        if (operatorBalance + negativePreviousBalanceComponent >= positivePreviousBalanceComponent) {
            
            if (positivePreviousBalanceComponent > negativePreviousBalanceComponent) {
                rewardIncrement = operatorBalance - (positivePreviousBalanceComponent - negativePreviousBalanceComponent); // default path
            } else {
                rewardIncrement = operatorBalance + (negativePreviousBalanceComponent - positivePreviousBalanceComponent); // edge case if operator's entire balance is unstaked
            }

            if (rewardIncrement > slashCounter_) {
                if (slashCounter_ != 0) {
                    rewardIncrement -= slashCounter_;
                    operators[operatorId].slashCounter = 0; 
                }
                operators[operatorId].rewards += SafeCast.toUint80(rewardIncrement);
                if (takeFee == true) {
                    operators[operatorId].pendingFee += SafeCast.toUint80(rewardIncrement * validatorFeeBps  / 10000);
                    servicePendingFee += SafeCast.toUint80(rewardIncrement * serviceFeeBps / 10000);
                }
            } else {
                operators[operatorId].slashCounter -= SafeCast.toUint88(rewardIncrement);
            }
        } else {
            operators[operatorId].slashCounter += SafeCast.toUint88(positivePreviousBalanceComponent - negativePreviousBalanceComponent - operatorBalance);
        }
        return operators[operatorId].pendingFee;
    }
    
    /**
     * Ensures that the APR of the possible supply change is within reasonable bounds
     * @param timeElapsed unix time since the last rebase
     * @param currentSupply the current supply of stflip
     * @param newSupply the new supply that would be increased to
     */
    function _validateSupplyChange(uint256 timeElapsed, uint256 currentSupply, uint256 newSupply) internal view returns (uint256) {
        uint256 apr;
        if (newSupply > currentSupply){
            apr = (newSupply * 10**18 / currentSupply - 10**18) * 10**18 / (timeElapsed * 10**18 / TIME_IN_YEAR) / (10**18/10000);

            if (apr + 1 >= aprThresholdBps) revert AprTooHigh(apr + 1);
        } else {
            uint256 supplyDecrease = 10000 - (newSupply * 10000 / currentSupply);
            if (supplyDecrease >= slashThresholdBps) revert SupplyDecreaseTooHigh(supplyDecrease);
        }

        return apr;
    }

    /** 
     *  @notice Claims pending fees to the fee recipient in either stflip or flip
     *  @dev `pendingFee` is a piece of the pool. When fee is claimed in FLIP, the
     *  pool's decrease in FLIP aligns with the decrease in `pendingFee`. Similarly,
     *  when stFLIP is claimed, the increase in stFLIP supply corresponds to the decrease
     *  in `pendingFee`. When `max` is true, the entire `pendingFee` is claimed and the
     *  `amount` does not matter. 
     *  @param amount Amount of tokens to burn
     *  @param max Whether or not to claim all pending fees
     *  @param receiveFlip Whether or not to receive the fee in flip or stflip
     *  @param operatorId the operator's ID that is claiming their fee
     */
    function claimFee (uint256 amount, bool max, bool receiveFlip, uint256 operatorId) external {
        address manager;
        address feeRecipient;
        uint256 pendingFee = operators[operatorId].pendingFee;
        (manager,feeRecipient) = wrappedOutputProxy.getOperatorAddresses(operatorId);
        
        if (max == false && amount > pendingFee) revert ExcessiveFeeClaim();
        if (msg.sender != feeRecipient && msg.sender != manager) revert NotFeeRecipientOrManager();

        uint256 amountToClaim = max ? pendingFee : amount;

        operators[operatorId].pendingFee -= SafeCast.toUint80(amountToClaim);
        totalOperatorPendingFee -= SafeCast.toUint80(amountToClaim);
        
        if (receiveFlip == true) {
            flip.transferFrom(address(wrappedOutputProxy), msg.sender, amountToClaim);
        } else {
            stflip.mint(msg.sender, amountToClaim);
        }

        emit FeeClaim(msg.sender, amountToClaim, receiveFlip, operatorId);
    }

    /**
     * Claims the service's pendingFees
     * @param amount Amount of fee to claim
     * @param max Whether or not to claim all pending fees
     * @param receiveFlip Whether to receive the fee in flip or stflip
     */
    function claimServiceFee(uint256 amount, bool max, bool receiveFlip) external onlyRole(FEE_RECIPIENT_ROLE) {
        if (max == false && amount > servicePendingFee) revert ExcessiveFeeClaim();

        uint256 amountToClaim = max ? servicePendingFee : amount;

        servicePendingFee -= SafeCast.toUint80(amountToClaim);

        if (receiveFlip == true) {
            flip.transferFrom(address(wrappedOutputProxy), msg.sender, amountToClaim);
        } else {
            stflip.mint(msg.sender, amountToClaim);
        }

        emit FeeClaim(msg.sender, amountToClaim, receiveFlip, 0); // consider putting service Fee under operator id zero. consider implications though since all validators will have operator id of zero by default. 
    }

    /**
     * @notice Returns all operators
     */
    function getOperators() external view returns (Operator[] memory) {
        uint256 operatorCount = wrappedOutputProxy.getOperatorCount();
        Operator[] memory ret = new Operator[](operatorCount);
        for (uint256 operatorId; operatorId < operatorCount; operatorId++) {
            ret[operatorId] = operators[operatorId];
        }

        return ret;
    }


}
