// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Math.sol";
import "./Supervisor.sol";
import "./Vesting.sol";
import "./WhitelistInterface.sol";

/**
 * @title Buyback
 */
contract Buyback is AccessControl {
    using SafeERC20 for Mnt;

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Tole that's allowed to initiate buyback
    /// @dev Value is the Keccak-256 hash of "DISTRIBUTOR"
    bytes32 public constant DISTRIBUTOR = bytes32(0x85faced7bde13e1a7dad704b895f006e704f207617d68166b31ba2d79624862d);

    uint256 internal constant SHARE_SCALE = 1e36;
    uint256 internal constant CURVE_SCALE = 1e18;

    uint256 public constant SECS_PER_YEAR = 365 * 24 * 60 * 60;

    /// buyback curve approximates discount rate of the e^-kt, k = 0.725, t = days/365 with the polynomial.
    /// polynomial function f(x) = A + (B * x) + (C * x^2) + (D * x^3) + (E * x^4)
    /// e^(-0.725*t) ~ 1 - 0.7120242*x + 0.2339357*x^2 - 0.04053335*x^3 + 0.00294642*x^4, x in range
    /// of 0 .. 4.44 years in seconds, with good precision
    /// e^-kt gives a steady discount rate of approximately 48% per year on the function range
    /// polynomial approximation gives similar results on most of the range and then smoothly reduces it
    /// to the constant value of about 4.75% (flatRate) starting from the kink point, i.e. when
    /// blockTime >= flatSeconds, result value equals the flatRate
    /// kink point (flatSeconds) calculated as df/dx = 0 for approximation polynomial
    /// A..E are as follows, B and D values are negative in the formula,
    /// substraction is used in the calculations instead
    /// result formula is f(x) = A + C*x^2 + E*x^4 - B*x - D * x^3
    uint256 internal constant A = 1e18;
    uint256 internal constant B = 0.7120242e18; // negative
    uint256 internal constant C = 0.2339357e18; // positive
    uint256 internal constant D = 0.04053335e18; // negative
    uint256 internal constant E = 0.00294642e18; // positive

    /// @notice Seconds from protocol start when approximation function has minimum value
    ///     ~ 4.44 years of the perfect year, at this point df/dx == 0
    uint256 public constant flatSeconds = 140119200;

    /// @notice Flat rate of the discounted MNTs after the kink point, equal to the percentage at flatSeconds time
    uint256 public constant flatRate = 47563813360365998;

    /// @notice Timestamp from which the discount starts
    uint256 public startTimestamp;

    Mnt public mnt;
    Supervisor public supervisor;
    Vesting public vesting;

    /// @notice How much MNT claimed from the buyback
    /// @param participating Marks account as legally participating in Buyback
    /// @param weight Total weight of accounts' funds
    /// @param lastShareAccMantissa The cumulative buyback share which was claimed last time
    struct MemberData {
        bool participating;
        uint256 weight;
        uint256 lastShareAccMantissa;
    }

    /// @param amount The amount of staked MNT
    /// @param discounted The amount of staked MNT with discount
    struct StakeData {
        uint256 amount;
        uint256 discounted;
    }

    /// @notice Member info of accounts
    mapping(address => MemberData) public members;
    /// @notice Stake info of accounts
    mapping(address => StakeData) public stakes;

    /// @notice The sum of all members' weights
    uint256 public weightSum;
    /// @notice The accumulated buyback share per 1 weight.
    uint256 public shareAccMantissa;

    /// @notice is stake function paused
    bool public isStakePaused;
    /// @notice is unstake function paused
    bool public isUnstakePaused;
    /// @notice is leave function paused
    bool public isLeavePaused;
    /// @notice is restake function paused
    bool public isRestakePaused;

    event ClaimReward(address who, uint256 amount);
    event Unstake(address who, uint256 amount);
    event NewBuyback(uint256 amount, uint256 share);
    event ParticipateBuyback(address who);
    event LeaveBuyback(address who, uint256 currentStaked);
    event BuybackActionPaused(string action, bool pauseState);
    event DistributorChanged(address oldDistributor, address newDistributor);

    function initialize(
        Mnt mnt_,
        Supervisor supervisor_,
        Vesting vesting_,
        address admin_
    ) external {
        require(startTimestamp == 0, ErrorCodes.SECOND_INITIALIZATION);
        supervisor = supervisor_;
        startTimestamp = getTime();
        mnt = mnt_;
        vesting = vesting_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(DISTRIBUTOR, admin_);
    }

    /// @param account_ The account address
    /// @return Does the account legally participating Buyback
    function isParticipating(address account_) public view returns (bool) {
        return members[account_].participating;
    }

    /// @notice function to change stake enabled mode
    /// @param isPaused_ new state of stake allowance
    function setStakePaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit BuybackActionPaused("Stake", isPaused_);
        isStakePaused = isPaused_;
    }

    /// @notice function to change unstake enabled mode
    /// @param isPaused_ new state of stake allowance
    function setUnstakePaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit BuybackActionPaused("Unstake", isPaused_);
        isUnstakePaused = isPaused_;
    }

    /// @notice function to change unstake enabled mode
    /// @param isPaused_ new state of restake allowance
    function setRestakePaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit BuybackActionPaused("Restake", isPaused_);
        isRestakePaused = isPaused_;
    }

    /// @notice function to change unstake enabled mode
    /// @param isPaused_ new state of _leave allowance
    function setLeavePaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit BuybackActionPaused("Leave", isPaused_);
        isLeavePaused = isPaused_;
    }

    /// @notice How much weight address has
    /// @param who_ Buyback member address
    /// @return Weight
    function weight(address who_) external view returns (uint256) {
        return members[who_].weight;
    }

    /// @notice Applies current discount rate to supplied amount
    /// @param amount_ The amount to discount
    /// @return Discounted amount in range [0; amount]
    function discountAmount(uint256 amount_) public view returns (uint256) {
        uint256 realPassed = getTime() - startTimestamp;
        return (amount_ * getPolynomialFactor(realPassed)) / CURVE_SCALE;
    }

    /// @notice Calculates value of polynomial approximation of e^-kt, k = 0.725, t in seconds of a perfect year
    ///         function follows e^(-0.725*t) ~ 1 - 0.7120242*x + 0.2339357*x^2 - 0.04053335*x^3 + 0.00294642*x^4
    ///         up to the minimum and then continues with a flat rate
    /// @param secondsElapsed_ Seconds elapsed from the start block
    /// @return Discount rate in range [0..1] with precision mantissa 1e18
    function getPolynomialFactor(uint256 secondsElapsed_) public pure returns (uint256) {
        if (secondsElapsed_ >= flatSeconds) return flatRate;

        uint256 x = (CURVE_SCALE * secondsElapsed_) / SECS_PER_YEAR;
        uint256 x2 = (x * x) / CURVE_SCALE;
        uint256 bX = (B * x) / CURVE_SCALE;
        uint256 cX = (C * x2) / CURVE_SCALE;
        uint256 dX = (((D * x2) / CURVE_SCALE) * x) / CURVE_SCALE;
        uint256 eX = (((E * x2) / CURVE_SCALE) * x2) / CURVE_SCALE;

        return A + cX + eX - bX - dX;
    }

    /// @notice Calculates current weight of an account.
    /// @dev Reads a parameter mntAccrued from the supervisor's storage. Make sure you update the MNT supply and
    ///      borrow indexes and distribute MNT tokens for `who`.
    /// @param who_ The account under study
    /// @return Weight
    function calcWeight(address who_) public view returns (uint256) {
        return supervisor.mntAccrued(who_) + vesting.releasableAmount(who_) + stakes[who_].discounted;
    }

    /// @notice Stakes the specified amount of MNT and transfers them to this contract.
    ///         Sender's weight would increase by the discounted amount of staked funds.
    /// @notice This contract should be approved to transfer MNT from sender account
    /// @param amount_ The amount of MNT to stake
    function stake(uint256 amount_) external {
        WhitelistInterface whitelist = supervisor.whitelist();
        require(address(whitelist) == address(0) || whitelist.isWhitelisted(msg.sender), ErrorCodes.WHITELISTED_ONLY);
        require(isParticipating(msg.sender), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);
        require(!isStakePaused, ErrorCodes.OPERATION_PAUSED);

        StakeData storage staked = stakes[msg.sender];
        staked.amount += amount_;
        staked.discounted += discountAmount(amount_);

        _restakeFor(msg.sender);
        mnt.safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// @notice Unstakes the specified amount of MNT and transfers them back to sender if he participates
    ///         in the Buyback system, otherwise just transfers MNT tokens to the sender.
    ///         Sender's weight would decrease by discounted amount of unstaked funds, but resulting weight
    ///         would not be greater than staked amount left. If `amount_ == MaxUint256` unstakes all staked tokens.
    /// @param amount_ The amount of MNT to unstake
    function unstake(uint256 amount_) external {
        require(amount_ > 0, ErrorCodes.INCORRECT_AMOUNT);
        require(!isUnstakePaused, ErrorCodes.OPERATION_PAUSED);

        StakeData storage staked = stakes[msg.sender];

        // Check if the sender is a member of the Buyback system
        bool isSenderParticipating = isParticipating(msg.sender);

        if (amount_ == type(uint256).max || amount_ == staked.amount) {
            amount_ = staked.amount;
            delete stakes[msg.sender];
        } else {
            require(amount_ < staked.amount, ErrorCodes.INSUFFICIENT_STAKE);
            staked.amount -= amount_;
            // Recalculate the discount if the sender participates in the Buyback system
            if (isSenderParticipating) {
                uint256 newDiscounted = staked.discounted - discountAmount(amount_);
                /// Stake amount can be greater if discount is high leading to small discounted delta
                staked.discounted = Math.min(newDiscounted, staked.amount);
            }
        }

        emit Unstake(msg.sender, amount_);

        // Restake for the sender if he participates in the Buyback system
        if (isSenderParticipating) _restakeFor(msg.sender);

        mnt.safeTransfer(msg.sender, amount_);
    }

    /// @notice Stakes buyback reward and updates the sender's weight
    function restake() external {
        _restakeFor(msg.sender);
    }

    /// @notice Stakes buyback reward and updates the specified account's weight.
    /// @param who_ Address to claim for
    function restakeFor(address who_) external {
        _restakeFor(who_);
    }

    /// @notice Stakes buyback reward and updates the specified account's weight. Also updates MNT supply and
    ///         borrow indices and distributes for "who" MNT tokens
    /// @param who_ Address to claim for
    function restakeForWithDistribution(address who_) external {
        // slither-disable-next-line reentrancy-events,reentrancy-benign
        supervisor.distributeAllMnt(who_);
        _restakeFor(who_);
    }

    function _restakeFor(address who_) internal {
        require(!isRestakePaused, ErrorCodes.OPERATION_PAUSED);

        if (!isParticipating(who_)) return;
        MemberData storage member = members[who_];
        _claimReward(who_, member);

        uint256 oldWeight = member.weight;
        uint256 newWeight = calcWeight(who_);

        if (newWeight != oldWeight) {
            member.weight = newWeight;
            weightSum = weightSum + newWeight - oldWeight;

            mnt.updateVotesForAccount(who_, uint224(newWeight), uint224(weightSum));
        }
    }

    function _claimReward(address who_, MemberData storage member_) internal {
        if (member_.lastShareAccMantissa >= shareAccMantissa) return;
        if (member_.weight == 0) {
            // member weight 0 means account is not participating in buyback yet, we need
            // to initialize it first. There is nothing to claim so function simply returns
            member_.lastShareAccMantissa = shareAccMantissa;
            return;
        }

        uint256 shareDiffMantissa = shareAccMantissa - member_.lastShareAccMantissa;
        uint256 rewardMnt = (member_.weight * shareDiffMantissa) / SHARE_SCALE;
        if (rewardMnt <= 0) return;

        stakes[who_].amount += rewardMnt;
        stakes[who_].discounted += rewardMnt;
        member_.lastShareAccMantissa = shareAccMantissa;

        emit ClaimReward(who_, rewardMnt);
    }

    /// @notice Does a buyback using the specified amount of MNT from sender's account
    /// @param amount_ The amount of MNT to take and distribute as buyback
    function buyback(uint256 amount_) external onlyRole(DISTRIBUTOR) {
        require(amount_ > 0, ErrorCodes.NOTHING_TO_DISTRIBUTE);
        require(weightSum > 0, ErrorCodes.NOT_ENOUGH_PARTICIPATING_ACCOUNTS);

        uint256 shareMantissa = (amount_ * SHARE_SCALE) / weightSum;
        shareAccMantissa = shareAccMantissa + shareMantissa;

        emit NewBuyback(amount_, shareMantissa);

        mnt.safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// @notice Make account participating in the buyback. If the sender has a staked balance, then
    /// the weight will be equal to the discounted amount of staked funds.
    function participate() external {
        require(!isParticipating(msg.sender), ErrorCodes.ALREADY_PARTICIPATING_IN_BUYBACK);

        members[msg.sender].participating = true;
        emit ParticipateBuyback(msg.sender);

        StakeData storage staked = stakes[msg.sender];
        if (staked.amount > 0) staked.discounted = discountAmount(staked.amount);

        _restakeFor(msg.sender);
    }

    ///@notice Make accounts participate in buyback before its start.
    /// @param accounts_ Address to make participate in buyback.
    function participateOnBehalf(address[] memory accounts_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(shareAccMantissa == 0, ErrorCodes.BUYBACK_DRIPS_ALREADY_HAPPENED);
        for (uint256 i = 0; i < accounts_.length; i++) {
            members[accounts_[i]].participating = true;
        }
    }

    /// @notice Leave buyback participation, claim any MNTs rewarded by the buyback and withdraw all staked MNTs
    function leave() external {
        _leave(msg.sender);
    }

    /// @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
    /// withdraw all staked MNTs.
    /// @dev Admin function to leave on behalf.
    /// Can only be called if (timestamp > participantLastVoteTimestamp + maxNonVotingPeriod).
    /// @param participant_ Address to leave for
    function leaveOnBehalf(address participant_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!mnt.isParticipantActive(participant_), ErrorCodes.BB_ACCOUNT_RECENTLY_VOTED);
        _leave(participant_);
    }

    /// @notice Leave buyback participation, set discounted amount for the `_participant` to zero.
    function _leave(address participant_) internal {
        require(isParticipating(participant_), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);
        require(!isLeavePaused, ErrorCodes.OPERATION_PAUSED);

        _claimReward(participant_, members[participant_]);

        weightSum -= members[participant_].weight;
        delete members[participant_];
        stakes[participant_].discounted = 0;

        emit LeaveBuyback(participant_, stakes[participant_].amount);

        mnt.updateVotesForAccount(msg.sender, uint224(0), uint224(weightSum));
    }

    /// @return timestamp
    // slither-disable-next-line dead-code
    function getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
