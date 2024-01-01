//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IVestingFee.sol";
import "./UniswapOracle.sol";
import "./AccessProtected.sol";

struct ClaimInput {
    uint40 startTimestamp; // When does the vesting start (40 bits is enough for TS)
    uint40 endTimestamp; // When does the vesting end - the vesting goes linearly between the start and end timestamps
    uint40 cliffReleaseTimestamp; // At which timestamp is the cliffAmount released. This must be <= startTimestamp
    uint40 releaseIntervalSecs; // Every how many seconds does the vested amount increase.
    // uint112 range: range 0 –     5,192,296,858,534,827,628,530,496,329,220,095.
    // uint112 range: range 0 –                             5,192,296,858,534,827.
    uint256 linearVestAmount; // total entitlement
    uint256 cliffAmount; // how much is released at the cliff
    address recipient; // the recipient address
}

contract VTVLVesting is
    AccessProtected,
    ReentrancyGuard,
    IVestingFee,
    UniswapOracle
{
    using SafeERC20 for IERC20Extented;

    /**
    @notice How many tokens are already allocated to vesting schedules.
    @dev Our balance of the token must always be greater than this amount.
    * Otherwise we risk some users not getting their shares.
    * This gets reduced as the users are paid out or when their schedules are revoked (as it is not reserved any more).
    * In other words, this represents the amount the contract is scheduled to pay out at some point if the 
    * owner were to never interact with the contract.
    */
    uint256 public numTokensReservedForVesting = 0;

    /**
    @notice A structure representing a single claim - supporting linear and cliff vesting.
     */
    struct Claim {
        // Using 40 bits for timestamp (seconds)
        // Gives us a range from 1 Jan 1970 (Unix epoch) up to approximately 35 thousand years from then (2^40 / (365 * 24 * 60 * 60) ~= 35k)
        uint40 startTimestamp; // When does the vesting start (40 bits is enough for TS)
        uint40 endTimestamp; // When does the vesting end - the vesting goes linearly between the start and end timestamps
        uint40 cliffReleaseTimestamp; // At which timestamp is the cliffAmount released. This must be <= startTimestamp
        uint40 releaseIntervalSecs; // Every how many seconds does the vested amount increase.
        // uint112 range: range 0 –     5,192,296,858,534,827,628,530,496,329,220,095.
        // uint112 range: range 0 –                             5,192,296,858,534,827.
        uint256 linearVestAmount; // total entitlement
        uint256 amountWithdrawn; // how much was withdrawn thus far - released at the cliffReleaseTimestamp
        uint112 cliffAmount; // how much is released at the cliff
        bool isActive; // whether this claim is active (or revoked)
        // should keep the current index of struct fields to avoid changing frontend code regarding this change
        uint40 deactivationTimestamp;
    }

    // Mapping every user address to his/her Claim
    // This could be array because a recipient can have multiple schdules.
    // Only one Claim possible per address
    mapping(address => Claim[]) internal claims;

    address private immutable factoryAddress;
    uint256 public feePercent; // Fee percent.  500 means 5%, 1 means 0.01 %
    address public feeReceiver; // The receier address that will get the fee.

    uint256 public conversionThreshold;

    // Events:
    /**
    @notice Emitted when a founder adds a vesting schedule.
     */
    event ClaimCreated(
        address indexed _recipient,
        Claim _claim,
        uint256 _scheduleIndex
    );

    /**
    @notice Emitted when someone withdraws a vested amount
    */
    event Claimed(
        address indexed _recipient,
        uint256 _withdrawalAmount,
        uint256 _scheduleIndex
    );

    /**
    @notice Emitted when receiving the fee.
    @dev _tokenAddress may be vesting token address or USDC address depending on the token price.
    */
    event FeeReceived(
        address indexed _recipient,
        uint256 _feeAmount,
        uint256 _scheduleIndex,
        address _tokenAddress
    );

    /** 
    @notice Emitted when a claim is revoked
    */
    event ClaimRevoked(
        address indexed _recipient,
        uint256 _numTokensWithheld,
        uint256 revocationTimestamp,
        Claim _claim,
        uint256 _scheduleIndex
    );

    /** 
    @notice Emitted when admin withdraws.
    */
    event AdminWithdrawn(address indexed _recipient, uint256 _amountRequested);

    //
    /**
    @notice Construct the contract, taking the ERC20 token to be vested as the parameter.
    @dev The owner can set the contract in question when creating the contract.
     */
    constructor(
        IERC20Extented _tokenAddress,
        uint256 _feePercent
    ) UniswapOracle(_tokenAddress) {
        factoryAddress = msg.sender;
        feeReceiver = msg.sender;
        feePercent = _feePercent;

        // mint price is 0.3 USD
        conversionThreshold = 30;
    }

    /**
    @notice Basic getter for a claim. 
    @dev Could be using public claims var, but this is cleaner in terms of naming. (getClaim(address) as opposed to claims(address)). 
    @param _recipient - the address for which we fetch the claim.
    @param _scheduleIndex - the index of the schedules.
     */
    function getClaim(
        address _recipient,
        uint256 _scheduleIndex
    ) external view returns (Claim memory) {
        if (claims[_recipient].length <= _scheduleIndex) {
            revert("NO_SCHEDULE_EXIST");
        }
        return claims[_recipient][_scheduleIndex];
    }

    /**
    @notice This modifier requires that an user has a claim attached.
    @dev  To determine this, we check that a claim:
    * - is active
    * - start timestamp is nonzero.
    * These are sufficient conditions because we only ever set startTimestamp in 
    * createClaim, and we never change it. Therefore, startTimestamp will be set
    * IFF a claim has been created. In addition to that, we need to check
    * a claim is active (since this is has_*Active*_Claim)
    */
    modifier hasActiveClaim(address _recipient, uint256 _scheduleIndex) {
        require(claims[_recipient].length > _scheduleIndex, "NO_ACTIVE_CLAIM");

        Claim storage _claim = claims[_recipient][_scheduleIndex];
        require(_claim.startTimestamp > 0, "NO_ACTIVE_CLAIM");

        // We however still need the active check, since (due to the name of the function)
        // we want to only allow active claims
        require(_claim.isActive, "NO_ACTIVE_CLAIM");

        // Save gas, omit further checks
        // require(_claim.linearVestAmount + _claim.cliffAmount > 0, "INVALID_VESTED_AMOUNT");
        // require(_claim.endTimestamp > 0, "NO_END_TIMESTAMP");
        _;
    }

    /**
    @notice This modifier requires that owner or factory contract.
    */
    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "Not Factory");
        _;
    }

    // /**
    // @notice This modifier requires that owner or factory contract.
    // */
    // modifier onlyOwnerOrFactory() {
    //     require(
    //         msg.sender == owner() || msg.sender == factoryAddress,
    //         "Not Owner or Factory"
    //     );
    //     _;
    // }

    /**
    @notice Pure function to calculate the vested amount from a given _claim, at a reference timestamp
    @param _claim The claim in question
    @param _referenceTs Timestamp for which we're calculating
     */
    function _baseVestedAmount(
        Claim memory _claim,
        uint40 _referenceTs
    ) internal pure returns (uint256) {
        // If no schedule is created
        if (!_claim.isActive && _claim.deactivationTimestamp == 0) {
            return 0;
        }

        uint256 vestAmt = 0;

        // Check if this time is over vesting end time
        if (_referenceTs > _claim.endTimestamp) {
            return _claim.linearVestAmount + _claim.cliffAmount;
        }

        // If we're past the cliffReleaseTimestamp, we release the cliffAmount
        // We don't check here that cliffReleaseTimestamp is after the startTimestamp
        if (_referenceTs >= _claim.cliffReleaseTimestamp) {
            vestAmt = _claim.cliffAmount;
        }

        // Calculate the linearly vested amount - this is relevant only if we're past the schedule start
        // at _referenceTs == _claim.startTimestamp, the period proportion will be 0 so we don't need to start the calc
        if (_referenceTs > _claim.startTimestamp) {
            uint40 currentVestingDurationSecs = _referenceTs -
                _claim.startTimestamp; // How long since the start

            // Next, we need to calculated the duration truncated to nearest releaseIntervalSecs
            uint40 truncatedCurrentVestingDurationSecs = (currentVestingDurationSecs /
                    _claim.releaseIntervalSecs) * _claim.releaseIntervalSecs;

            uint40 finalVestingDurationSecs = _claim.endTimestamp -
                _claim.startTimestamp; // length of the interval

            // Calculate the linear vested amount - fraction_of_interval_completed * linearVestedAmount
            // Since fraction_of_interval_completed is truncatedCurrentVestingDurationSecs / finalVestingDurationSecs, the formula becomes
            // truncatedCurrentVestingDurationSecs / finalVestingDurationSecs * linearVestAmount, so we can rewrite as below to avoid
            // rounding errors
            uint256 linearVestAmount = (_claim.linearVestAmount *
                truncatedCurrentVestingDurationSecs) / finalVestingDurationSecs;

            // Having calculated the linearVestAmount, simply add it to the vested amount
            vestAmt += linearVestAmount;
        }

        return vestAmt;
    }

    /**
    @notice Calculate the amount vested for a given _recipient at a reference timestamp.
    @param _recipient - The address for whom we're calculating
    @param _scheduleIndex - The index of the vesting schedules of the recipient.
    @param _referenceTs - The timestamp at which we want to calculate the vested amount.
    @dev Simply call the _baseVestedAmount for the claim in question
    */
    function vestedAmount(
        address _recipient,
        uint256 _scheduleIndex,
        uint40 _referenceTs
    ) public view returns (uint256) {
        Claim memory _claim = claims[_recipient][_scheduleIndex];
        uint40 vestEndTimestamp = _claim.deactivationTimestamp == 0
            ? _referenceTs
            : _claim.deactivationTimestamp;
        return _baseVestedAmount(_claim, vestEndTimestamp);
    }

    /**
    @notice Calculate the total vested at the end of the schedule, by simply feeding in the end timestamp to the function above.
    @dev This fn is somewhat superfluous, should probably be removed.
    @param _recipient - The address for whom we're calculating
    @param _scheduleIndex - The index of the vesting schedules of the recipient.
     */
    function finalVestedAmount(
        address _recipient,
        uint256 _scheduleIndex
    ) public view returns (uint256) {
        Claim memory _claim = claims[_recipient][_scheduleIndex];
        return _baseVestedAmount(_claim, _claim.endTimestamp);
    }

    /**
    @notice Calculates how much can we claim, by subtracting the already withdrawn amount from the vestedAmount at this moment.
    @param _recipient - The address for whom we're calculating
    @param _scheduleIndex - The index of the vesting schedules of the recipient.
    */
    function claimableAmount(
        address _recipient,
        uint256 _scheduleIndex
    ) public view returns (uint256) {
        Claim memory _claim = claims[_recipient][_scheduleIndex];
        return
            vestedAmount(_recipient, _scheduleIndex, uint40(block.timestamp)) -
            _claim.amountWithdrawn;
    }

    /**
    @notice Calculates how much wil be possible to claim at the end of vesting date, by subtracting the already withdrawn
            amount from the vestedAmount at this moment. Vesting date is either the end timestamp or the deactivation timestamp.
    @param _recipient - The address for whom we're calculating
    @param _scheduleIndex - The index of the vesting schedules of the recipient.
    */
    function finalClaimableAmount(
        address _recipient,
        uint256 _scheduleIndex
    ) external view returns (uint256) {
        Claim storage _claim = claims[_recipient][_scheduleIndex];
        uint40 vestEndTimestamp = _claim.deactivationTimestamp == 0
            ? _claim.endTimestamp
            : _claim.deactivationTimestamp;
        return
            _baseVestedAmount(_claim, vestEndTimestamp) -
            _claim.amountWithdrawn;
    }

    /** 
    @notice Permission-unchecked version of claim creation (no onlyOwner). Actual logic for create claim, to be run within either createClaim or createClaimBatch.
    @dev This'll simply check the input parameters, and create the structure verbatim based on passed in parameters.
     */
    function _createClaimUnchecked(ClaimInput memory claimInput) private {
        require(claimInput.recipient != address(0), "INVALID_ADDRESS");
        require(
            claimInput.linearVestAmount + claimInput.cliffAmount > 0,
            "INVALID_VESTED_AMOUNT"
        ); // Actually only one of linearvested/cliff amount must be 0, not necessarily both
        require(claimInput.startTimestamp > 0, "INVALID_START_TIMESTAMP");
        // Do we need to check whether _startTimestamp is greater than the current block.timestamp?
        // Or do we allow schedules that started in the past?
        // -> Conclusion: we want to allow this, for founders that might have forgotten to add some users, or to avoid issues with transactions not going through because of discoordination between block.timestamp and sender's local time
        // require(_endTimestamp > 0, "_endTimestamp must be valid"); // not necessary because of the next condition (transitively)
        require(
            claimInput.startTimestamp < claimInput.endTimestamp,
            "INVALID_END_TIMESTAMP"
        ); // _endTimestamp must be after _startTimestamp
        require(claimInput.releaseIntervalSecs > 0, "INVALID_RELEASE_INTERVAL");
        require(
            (claimInput.endTimestamp - claimInput.startTimestamp) %
                claimInput.releaseIntervalSecs ==
                0,
            "INVALID_INTERVAL_LENGTH"
        );

        // Potential TODO: sanity check, if _linearVestAmount == 0, should we perhaps force that start and end ts are the same?

        // No point in allowing cliff TS without the cliff amount or vice versa.
        // Both or neither of _cliffReleaseTimestamp and _cliffAmount must be set. If cliff is set, _cliffReleaseTimestamp must be before or at the _startTimestamp
        require(
            (claimInput.cliffReleaseTimestamp > 0 &&
                claimInput.cliffAmount > 0 &&
                claimInput.cliffReleaseTimestamp <=
                claimInput.startTimestamp) ||
                (claimInput.cliffReleaseTimestamp == 0 &&
                    claimInput.cliffAmount == 0),
            "INVALID_CLIFF"
        );

        Claim memory _claim;
        _claim.startTimestamp = claimInput.startTimestamp;
        _claim.endTimestamp = claimInput.endTimestamp;
        _claim.deactivationTimestamp = 0;
        _claim.cliffReleaseTimestamp = claimInput.cliffReleaseTimestamp;
        _claim.releaseIntervalSecs = claimInput.releaseIntervalSecs;
        _claim.linearVestAmount = claimInput.linearVestAmount;
        _claim.cliffAmount = uint112(claimInput.cliffAmount);
        _claim.amountWithdrawn = 0;
        _claim.isActive = true;

        claims[claimInput.recipient].push(_claim);

        // Our total allocation is simply the full sum of the two amounts, _cliffAmount + _linearVestAmount
        // Not necessary to use the more complex logic from _baseVestedAmount
        uint256 allocatedAmount = claimInput.cliffAmount +
            claimInput.linearVestAmount;
        require(
            // Still no effects up to this point (and tokenAddress is selected by contract deployer and is immutable), so no reentrancy risk
            tokenAddress.balanceOf(address(this)) >=
                numTokensReservedForVesting + allocatedAmount,
            "INSUFFICIENT_BALANCE"
        );

        // Done with checks

        // Effects limited to lines below
        numTokensReservedForVesting += allocatedAmount; // track the allocated amount

        emit ClaimCreated(
            claimInput.recipient,
            _claim,
            claims[claimInput.recipient].length
        ); // let everyone know
    }

    /** 
    @notice Create a claim based on the input parameters.
    @dev This'll simply check the input parameters, and create the structure verbatim based on passed in parameters.
     */
    function createClaim(
        ClaimInput memory claimInput
    ) external onlyAdmin nonReentrant {
        _createClaimUnchecked(claimInput);
    }

    /**
    @notice The batch version of the createClaim function. Each argument is an array, and this function simply repeatedly calls the createClaim.
    
     */
    function createClaimsBatch(
        ClaimInput[] calldata claimInputs
    ) external onlyAdmin nonReentrant {
        uint256 length = claimInputs.length;

        for (uint256 i = 0; i < length; ) {
            _createClaimUnchecked(claimInputs[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
    @notice Withdraw the full claimable balance.
    @dev hasActiveClaim throws off anyone without a claim.
    @param _scheduleIndex - The index of the vesting schedules of the recipient.
     */
    function withdraw(
        uint256 _scheduleIndex
    ) external hasActiveClaim(_msgSender(), _scheduleIndex) nonReentrant {
        // Get the message sender claim - if any

        Claim storage usrClaim = claims[_msgSender()][_scheduleIndex];

        // we can use block.timestamp directly here as reference TS, as the function itself will make sure to cap it to endTimestamp
        // Conversion of timestamp to uint40 should be safe since 48 bit allows for a lot of years.
        uint256 allowance = vestedAmount(
            _msgSender(),
            _scheduleIndex,
            uint40(block.timestamp)
        );

        // Make sure we didn't already withdraw more that we're allowed.
        require(
            allowance > usrClaim.amountWithdrawn && allowance > 0,
            "NOTHING_TO_WITHDRAW"
        );

        // Calculate how much can we withdraw (equivalent to the above inequality)
        uint256 amountRemaining = allowance - usrClaim.amountWithdrawn;
        require(amountRemaining > 0, "NOTHING_TO_WITHDRAW");

        // "Double-entry bookkeeping"
        // Carry out the withdrawal by noting the withdrawn amount, and by transferring the tokens.
        usrClaim.amountWithdrawn += amountRemaining;
        // Reduce the allocated amount since the following transaction pays out so the "debt" gets reduced
        numTokensReservedForVesting -= amountRemaining;

        _transferToken(amountRemaining, _scheduleIndex);
        // After the "books" are set, transfer the tokens
        // Reentrancy note - internal vars have been changed by now
        // Also following Checks-effects-interactions pattern

        // Let withdrawal known to everyone.
        emit Claimed(_msgSender(), amountRemaining, _scheduleIndex);
    }

    /**
     * @notice transfer the token to the user and fee receiver.
     * // if the token price is samller than the conversionThreshold, then it will transfer USDC to the recipient.
     * @param _amount The total amount that will be transfered.
     * @param _scheduleIndex The index of the schedule.
     */
    function _transferToken(uint256 _amount, uint256 _scheduleIndex) private {
        if (feePercent > 0) {
            uint256 _feeAmount = calculateFee(_amount);
            uint256 _realFeeAmount = (((_feeAmount * conversionThreshold) /
                100) * 10 ** USDC_DECIMAL) / 10 ** tokenDecimal;

            if (pool != address(0)) {
                // calcualte the price when 10 secs ago.
                uint256 price = getTokenPrice(10);
                if (price >= conversionThreshold) {
                    tokenAddress.safeTransfer(
                        _msgSender(),
                        _amount - _feeAmount
                    );
                    tokenAddress.safeTransfer(feeReceiver, _feeAmount);
                    emit FeeReceived(
                        feeReceiver,
                        _feeAmount,
                        _scheduleIndex,
                        address(tokenAddress)
                    );
                } else {
                    tokenAddress.safeTransfer(_msgSender(), _amount);
                    IERC20Extented(USDC_ADDRESS).safeTransferFrom(
                        msg.sender,
                        feeReceiver,
                        _realFeeAmount
                    );
                    emit FeeReceived(
                        feeReceiver,
                        _realFeeAmount,
                        _scheduleIndex,
                        address(USDC_ADDRESS)
                    );
                }
            } else {
                tokenAddress.safeTransfer(_msgSender(), _amount);
                IERC20Extented(USDC_ADDRESS).safeTransferFrom(
                    msg.sender,
                    feeReceiver,
                    _realFeeAmount
                );

                emit FeeReceived(
                    feeReceiver,
                    _realFeeAmount,
                    _scheduleIndex,
                    address(USDC_ADDRESS)
                );
            }
        } else {
            tokenAddress.safeTransfer(_msgSender(), _amount);
        }
    }

    function calculateFee(uint256 _amount) private view returns (uint256) {
        return (_amount * feePercent + 9999) / 10000;
    }

    /**
    @notice Admin withdrawal of the unallocated tokens.
    @param _amountRequested - the amount that we want to withdraw
     */
    function withdrawAdmin(
        uint256 _amountRequested
    ) public onlyAdmin nonReentrant {
        // Allow the owner to withdraw any balance not currently tied up in contracts.
        uint256 amountRemaining = amountAvailableToWithdrawByAdmin();

        require(amountRemaining >= _amountRequested, "INSUFFICIENT_BALANCE");

        // Actually withdraw the tokens
        // Reentrancy note - this operation doesn't touch any of the internal vars, simply transfers
        // Also following Checks-effects-interactions pattern
        tokenAddress.safeTransfer(_msgSender(), _amountRequested);

        // Let the withdrawal known to everyone
        emit AdminWithdrawn(_msgSender(), _amountRequested);
    }

    /** 
    @notice Allow an Owner to revoke a claim that is already active.
    @dev The requirement is that a claim exists and that it's active.
    @param _scheduleIndex - The index of the vesting schedules of the recipient.
    */
    function revokeClaim(
        address _recipient,
        uint256 _scheduleIndex
    ) external onlyAdmin hasActiveClaim(_recipient, _scheduleIndex) {
        // Fetch the claim
        Claim storage _claim = claims[_recipient][_scheduleIndex];
        require(_claim.deactivationTimestamp == 0, "NO_ACTIVE_CLAIM");

        // Calculate what the claim should finally vest to
        uint256 finalVestAmt = finalVestedAmount(_recipient, _scheduleIndex);

        // No point in revoking something that has been fully consumed
        // so require that there be unconsumed amount
        require(_claim.amountWithdrawn < finalVestAmt, "NO_UNVESTED_AMOUNT");

        // Deactivate the claim, and release the appropriate amount of tokens
        // _claim.isActive = false; // This effectively reduces the liability by amountRemaining, so we can reduce the liability numTokensReservedForVesting by that much
        _claim.deactivationTimestamp = uint40(block.timestamp);

        // The amount that is "reclaimed" is equal to the total allocation less what was already withdrawn
        uint256 vestedSoFarAmt = vestedAmount(
            _recipient,
            _scheduleIndex,
            uint40(block.timestamp)
        );
        uint256 amountRemaining = finalVestAmt - vestedSoFarAmt;
        numTokensReservedForVesting -= amountRemaining; // Reduces the allocation

        // Tell everyone a claim has been revoked.
        emit ClaimRevoked(
            _recipient,
            amountRemaining,
            uint40(block.timestamp),
            _claim,
            _scheduleIndex
        );
    }

    /**
    @notice Withdraw a token which isn't controlled by the vesting contract.
    @dev This contract controls/vests token at "tokenAddress". However, someone might send a different token. 
    To make sure these don't get accidentally trapped, give admin the ability to withdraw them (to their own address).
    Note that the token to be withdrawn can't be the one at "tokenAddress".
    @param _otherTokenAddress - the token which we want to withdraw
     */
    function withdrawOtherToken(
        IERC20 _otherTokenAddress
    ) external onlyAdmin nonReentrant {
        require(_otherTokenAddress != tokenAddress, "INVALID_TOKEN"); // tokenAddress address is already sure to be nonzero due to constructor
        uint256 bal = _otherTokenAddress.balanceOf(address(this));
        require(bal > 0, "INSUFFICIENT_BALANCE");
        _otherTokenAddress.transfer(_msgSender(), bal);
    }

    /**
     * @notice Get amount that is not vested in contract
     * @dev Whenever vesting is revoked, this amount will be increased.
     */
    function amountAvailableToWithdrawByAdmin() public view returns (uint256) {
        return
            tokenAddress.balanceOf(address(this)) - numTokensReservedForVesting;
    }

    function getNumberOfVestings(
        address _recipient
    ) public view returns (uint256) {
        return claims[_recipient].length;
    }

    function setFee(uint256 _feePercent) external onlyFactory {
        feePercent = _feePercent;
    }

    function updateFeeReceiver(address _newReceiver) external onlyFactory {
        feeReceiver = _newReceiver;
    }

    function updateconversionThreshold(
        uint256 _threshold
    ) external onlyFactory {
        conversionThreshold = _threshold;
    }
}
