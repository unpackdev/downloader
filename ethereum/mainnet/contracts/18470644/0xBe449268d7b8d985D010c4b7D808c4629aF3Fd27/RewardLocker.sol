// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Bloodline.sol";

/// Attempt to access meme altar functionality from unauthorized address.
error NotMemeAltar();

/// Initialization is one time action.
error AlreadyInitialized();

/// MemeAltar and RewardLocker are unsynchronized.
error Unsynchronized();

/// Action is disallowed until current cycle will be completed.
error CycleIsNotCompletedYet();

/// Unstake is ordered, but the cycle is still not completed, wait.
error TooEarlyToUnstake();

/// Stake coefficient cannot be bigger than 10000.
error StakePartMoreThan100Percent();

/**
 * @title RewardLocker - Rewards registry for cycles, the only minter of `bloodline`,
 *                          provides an ability to claim and stake reward token.
 */
contract RewardLocker {
    struct Cycle {
        uint32 cycleCompletedTimestamp;
        uint224 totalSacrificeCompetitionRewards;
        uint256 totalStakeRewards;
        address[] sacrificableTokens;
        // sacrificedToken -> coefficient
        mapping(address => uint256) coefficients;
        // sacrificedToken -> total sacrifice rewards
        mapping(address => uint256) totalSacrificeRewardsForToken;
    }

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/
    event CycleStarted(uint256 indexed index);

    event CycleCompleted(
        uint256 indexed index, address indexed winnerToken, uint256 indexed totalCycleRewards
    );

    event Rewarded(
        address indexed user,
        uint256 indexed cycleNumber,
        address indexed token,
        uint256 reward
    );

    event ClaimedReward(address indexed claimer, uint256 indexed amount);

    event RewardStaked(
        address indexed staker, uint256 indexed stakedCycle, uint256 indexed stakedAmount
    );

    event UnstakeOrdered(
        address indexed unstaker, uint256 indexed unstakeCycle, uint256 indexed unstakedAmount
    );

    event RewardUnstaked(
        address indexed unstaker, uint256 indexed unstakeCycle, uint256 indexed unstakedAmount
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Constant used in calculation as a denominator for accurancy.
    uint256 constant DENOMINATOR = 10_000;
    /// @notice Constants represents a bonus percentage for competition and stake rewards.
    uint256 constant BONUS_PERCENTAGE = 25;
    uint256 constant HUNDRED = 100;
    /// @notice Represents a developer fee as a percentage, which is additionally minted on top of total cycle rewards.
    uint256 constant DEVELOPER_PERCENTAGE = 3;

    /*//////////////////////////////////////////////////////////////
                        REWARD LOCKER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice ERC20 which is a reward token and can be minted only by this contract.
    Bloodline public bloodline;
    /// @notice Contract that defines the rewards, cycles and their completion.
    address public memeAltar;
    // @notice Contract, which receives developer fee and provides BDL liquidity.
    address public devLiquidityHolder;
    /// @notice The number of the last completed cycle.
    uint256 public lastCompletedCycle;
    /// @notice Stores the data related to the cycles.
    /// @dev cycleNumber -> Cycle struct
    mapping(uint256 => Cycle) public cycles;

    /// @notice Stores the rewards concatenated 128bit stake amount and 128bit sacrifice amount.
    /// @dev user -> cycleNumber -> sacrificedToken -> concatenated amounts
    mapping(address => mapping(uint256 => mapping(address => uint256))) private rewards;
    /// @notice Stores the staked amounts.
    /// @dev user -> stakedAmount
    mapping(address => uint256) public staked;
    /// @notice Stores the unstake orders.
    /// @dev cycleNumber -> user -> unstakeAmount
    mapping(uint256 => mapping(address => uint256)) public unstakeOrdered;

    modifier onlyMemeAltar() {
        if (msg.sender != memeAltar) {
            revert NotMemeAltar();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method initialize memeAltar and bloodline, sets first cycle as 1.
     * @param _memeAltar address of contract that defines the rewards, cycles and their completion.
     * @param _bloodline address of ERC20 which is a reward token and can be minted only by this contract.
     * @param _devLiquidityHolder address which receives developer fee and provides BDL liquidity.
     */
    function init(
        address _memeAltar,
        address _bloodline,
        address _devLiquidityHolder
    )
        external
    {
        if (
            memeAltar != address(0) && address(bloodline) != address(0)
                && devLiquidityHolder != address(0)
        ) {
            revert AlreadyInitialized();
        }
        devLiquidityHolder = _devLiquidityHolder;
        memeAltar = _memeAltar;
        bloodline = Bloodline(_bloodline);
        Cycle storage cycle0 = cycles[0];
        cycle0.cycleCompletedTimestamp = uint32(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                            CYCLE AND REWARD LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Method inits data related to the next cycle.
     * @dev Should be called after `registerCycleCompleted`.
     *      Must be at least 2 sacrificable tokens.
     * @param cycleIndex the number of the next cycle.
     * @param sacrificableTokens list of token addresses that participate in the next cycle.
     * @return True
     */
    function registerNextCycle(
        uint256 cycleIndex,
        address[] calldata sacrificableTokens
    )
        external
        onlyMemeAltar
        returns (bool)
    {
        Cycle storage previousCycle = cycles[lastCompletedCycle];
        if (
            cycleIndex != lastCompletedCycle + 1
                || previousCycle.cycleCompletedTimestamp != block.timestamp
                || sacrificableTokens.length < 2
        ) {
            revert Unsynchronized();
        }
        Cycle storage cycle = cycles[cycleIndex];
        if (cycle.sacrificableTokens.length > 0) {
            revert Unsynchronized();
        }
        cycle.sacrificableTokens = sacrificableTokens;
        emit CycleStarted(cycleIndex);
        return true;
    }

    /**
     * @notice Method register the user reward for sacrificing and extra reward if
     *         user staked to be secured.
     * @param user address which is being rewarded.
     * @param _sacrificedToken address of a token that was sacrificed.
     * @param reward amount of the reward tokens `user` is getting for sacrificing.
     * @return True
     */
    function registerReward(
        address user,
        address _sacrificedToken,
        uint256 reward
    )
        external
        onlyMemeAltar
        returns (bool)
    {
        uint256 cycleNumber = lastCompletedCycle + 1;
        Cycle storage cycle = cycles[cycleNumber];
        uint256 stakeSacrificeRewards = rewards[user][cycleNumber][_sacrificedToken];
        uint256 stakedAmount = staked[user];
        if (stakedAmount != 0) {
            (uint256 stakeReward, uint256 sacrificeReward) =
                _unpackStakeSacrificeRewards(stakeSacrificeRewards);
            if (stakeReward < BONUS_PERCENTAGE * stakedAmount / HUNDRED) {
                if (reward + sacrificeReward >= stakedAmount) {
                    // storage write
                    cycle.totalStakeRewards +=
                        (BONUS_PERCENTAGE * stakedAmount / HUNDRED) - stakeReward;
                    stakeReward = BONUS_PERCENTAGE * stakedAmount / HUNDRED;
                } else {
                    // storage write
                    cycle.totalStakeRewards += BONUS_PERCENTAGE * reward / HUNDRED;
                    stakeReward += BONUS_PERCENTAGE * reward / HUNDRED;
                }
            }
            sacrificeReward += reward;
            stakeSacrificeRewards = _packStakeSacrificeRewards(stakeReward, sacrificeReward);
        } else {
            stakeSacrificeRewards += reward;
        }
        // storage write
        rewards[user][cycleNumber][_sacrificedToken] = stakeSacrificeRewards;
        // storage write
        cycle.totalSacrificeRewardsForToken[_sacrificedToken] += reward;
        emit Rewarded(user, cycleNumber, _sacrificedToken, reward);
        return true;
    }

    function _unpackStakeSacrificeRewards(uint256 stakeSacrificeRewards)
        internal
        pure
        returns (uint256 stakeReward, uint256 sacrificeReward)
    {
        stakeReward = uint256(uint128(stakeSacrificeRewards >> 128));
        sacrificeReward = uint256(uint128(stakeSacrificeRewards));
    }

    function _packStakeSacrificeRewards(
        uint256 stakeReward,
        uint256 sacrificeReward
    )
        internal
        pure
        returns (uint256 stakeSacrificeRewards)
    {
        stakeSacrificeRewards = (stakeReward << 128) + sacrificeReward;
    }

    /**
     * @notice Method register cycle as a completed. Sets token coefficients
     *         to extra reward winner up to 25%. Mints reward tokens.
     * @dev IF we want to fight against inflation - here we can set losers
     *      coefficient as 0.5.
     * @param cycleIndex number of the cycle which is completed.
     * @param winnerToken address of a token which won cycle competition.
     * @return True
     */
    function registerCycleCompleted(
        uint256 cycleIndex,
        address winnerToken
    )
        external
        onlyMemeAltar
        returns (bool)
    {
        if (cycleIndex != lastCompletedCycle + 1) {
            revert Unsynchronized();
        }
        Cycle storage cycle = cycles[cycleIndex];
        uint256 numberOfSacrificables = cycle.sacrificableTokens.length;
        uint256 cycleTotalRewards;
        for (uint256 i = 0; i < numberOfSacrificables; i++) {
            address token = cycle.sacrificableTokens[i];
            // storage write
            cycle.coefficients[token] = DENOMINATOR;
            // storage read
            cycleTotalRewards += cycle.totalSacrificeRewardsForToken[token];
        }

        // winner competition bonus
        if (cycleTotalRewards != 0 && winnerToken != address(0)) {
            uint256 minDominance = cycleTotalRewards / numberOfSacrificables;
            uint256 winnerCoefficient = (
                DENOMINATOR + (BONUS_PERCENTAGE * DENOMINATOR / HUNDRED)
            )
                - (
                    (cycle.totalSacrificeRewardsForToken[winnerToken] - minDominance)
                        * (BONUS_PERCENTAGE * DENOMINATOR / HUNDRED)
                        / (cycleTotalRewards - minDominance)
                );
            // storage rewrite
            cycle.coefficients[winnerToken] = winnerCoefficient;
            // add competition reward
            cycleTotalRewards += cycle.totalSacrificeRewardsForToken[winnerToken]
                * (winnerCoefficient - DENOMINATOR) / DENOMINATOR;
        }

        // storage write
        cycle.totalSacrificeCompetitionRewards = uint224(cycleTotalRewards);
        // add stake rewards
        cycleTotalRewards += cycle.totalStakeRewards;

        bloodline.mintBloodline(address(this), cycleTotalRewards);
        uint256 developerFee = cycleTotalRewards * DEVELOPER_PERCENTAGE / HUNDRED;
        bloodline.mintBloodline(devLiquidityHolder, developerFee);
        // storage write
        lastCompletedCycle += 1;
        // storage write
        cycle.cycleCompletedTimestamp = uint32(block.timestamp);
        emit CycleCompleted(cycleIndex, winnerToken, cycleTotalRewards);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            STAKE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method stakes tokens collected as rewards from `_cycles` cycles
     *         for sacrificing `_sacrificedTokens` tokens. Staking guarantees
     *         additional reward for sacrificing tokens in the next cycles -
     *         each sacrificed reward is doubled, if the same amount is staked.
     * @dev Should be called instead claim by long run users.
     * @param _cycles an array of cycle numbers (must be completed ones).
     * @param _sacrificedTokens an array of sacrificed token addresses.
     * @return stakedAmount amount of tokens which were staked.
     */
    function stakeToBeSecured(
        uint256[] memory _cycles,
        address[] memory _sacrificedTokens
    )
        external
        returns (uint256 stakedAmount)
    {
        stakedAmount = _getRewardForCyclesTokens(_cycles, _sacrificedTokens);
        staked[msg.sender] += stakedAmount;
        emit RewardStaked(msg.sender, lastCompletedCycle + 1, stakedAmount);
    }

    /**
     * @notice Method stakes `amount` amount of `bloodline` tokens using permit,
     *         requires to sign EIP2612 approval for this contract. Staking guarantees
     *         additional reward for sacrificing tokens in the next cycles -
     *         each sacrificed reward is doubled, if the same amount is staked.
     * @dev Frontend must have ability to sign EIP2612 approval. Could be called by lucky price deep buyers.
     * @param amount of `bloodline` tokens which are staking.
     * @param deadline timestamp until permit is valid.
     * @param v secp256k1 signature field
     * @param r secp256k1 signature field
     * @param s secp256k1 signature field
     * @return stakedAmount amount of tokens which were staked.
     */
    function stakeToBeSecured(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint256 stakedAmount)
    {
        bloodline.permit(msg.sender, address(this), amount, deadline, v, r, s);
        stakedAmount = stakeToBeSecured(amount);
    }

    /**
     * @notice Method stakes `amount` amount of `bloodline` tokens.
     *         Requires token preapproval for this contract. Staking guarantees
     *         additional reward for sacrificing tokens in the next cycles -
     *         each sacrificed reward is doubled, if the same amount is staked.
     * @dev Should be called after `bloodline` approve tx.
     * @param amount of `bloodline` tokens which are staking.
     * @return stakedAmount amount of tokens which were staked.
     */
    function stakeToBeSecured(uint256 amount) public returns (uint256 stakedAmount) {
        require(bloodline.transferFrom(msg.sender, address(this), amount));
        staked[msg.sender] += amount;
        stakedAmount = amount;
        emit RewardStaked(msg.sender, lastCompletedCycle + 1, stakedAmount);
    }

    /**
     * @notice Method creates an order to unstake staked `bloodline` tokens.
     *         After method is called, tokens can be unstaked in the next cycle.
     * @dev Should be called before unstake.
     * @return unstakeCycle number of cycle, when tokens can be unstaked.
     */
    function orderUnstake() external returns (uint256 unstakeCycle) {
        unstakeCycle = lastCompletedCycle + 2;
        uint256 stakedAmount = staked[msg.sender];
        staked[msg.sender] = 0;
        unstakeOrdered[unstakeCycle][msg.sender] += stakedAmount;
        emit UnstakeOrdered(msg.sender, unstakeCycle, stakedAmount);
    }

    /**
     * @notice Method unstakes staked `bloodline` tokens and transfers them to
     *         `msg.sender`, which were ordered to be unstaked in `unstakeCycle` cycle.
     * @dev Should be called after orderUnstake and cycle order was made is completed.
     * @param unstakeCycle number of the next cycle after cycle tokens were ordered to be unstaked.
     * @return unstakedAmount amount of tokens being unstaked.
     */
    function unstake(uint256 unstakeCycle) external returns (uint256 unstakedAmount) {
        if (unstakeCycle > lastCompletedCycle + 1) {
            revert TooEarlyToUnstake();
        }
        unstakedAmount = unstakeOrdered[unstakeCycle][msg.sender];
        unstakeOrdered[unstakeCycle][msg.sender] = 0;
        _transferReward(unstakedAmount);
        emit RewardUnstaked(msg.sender, unstakeCycle, unstakedAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method claims for specified `_cycles` cycles reward as `bloodline`
     *         tokens and transfers them to `msg.sender` user.
     * @dev Should be called by users, who sacrificed all sacrificable tokens.
     * @param _cycles an array of cycle numbers, for which rewards should be claimed.
     * @return claimedAmount amount of tokens are being claimed by 'msg.sender' user.
     */
    function claim(uint256[] memory _cycles) external returns (uint256 claimedAmount) {
        for (uint256 i = 0; i < _cycles.length; i++) {
            Cycle storage cycle = cycles[_cycles[i]];
            if (
                cycle.cycleCompletedTimestamp == 0
                    || cycle.cycleCompletedTimestamp >= block.timestamp
            ) {
                revert CycleIsNotCompletedYet();
            }
            for (uint256 k = 0; k < cycle.sacrificableTokens.length; k++) {
                address _sacrificedToken = cycle.sacrificableTokens[k];
                uint256 rewardAmount = _getReward(_cycles[i], cycle, _sacrificedToken);
                claimedAmount += rewardAmount;
            }
        }
        _transferReward(claimedAmount);
        emit ClaimedReward(msg.sender, claimedAmount);
    }

    /**
     * @notice Method claims for specified `_cycles` cycles for specified
     *         sacrificable `_sacrificedTokens` tokens reward as `bloodline`
     *         tokens and transfers them to `msg.sender` user.
     * @dev Should be called by users, who sacrificed specific sacrificable tokens.
     * @param _cycles an array of cycle numbers, for which rewards should be claimed.
     * @param _sacrificedTokens an array of sacrificed token addresses, for which rewards should be claimed.
     * @return claimedAmount amount of tokens are being claimed by 'msg.sender' user.
     */
    function claim(
        uint256[] memory _cycles,
        address[] memory _sacrificedTokens
    )
        external
        returns (uint256 claimedAmount)
    {
        claimedAmount = _getRewardForCyclesTokens(_cycles, _sacrificedTokens);
        _transferReward(claimedAmount);
        emit ClaimedReward(msg.sender, claimedAmount);
    }

    /**
     * @notice Method claims for specified `_cycles` cycles for specified
     *         sacrificable `_sacrificedToken` token reward as `bloodline`
     *         tokens and transfers them to `msg.sender` user.
     * @dev Should be called by users, who sacrificed specific sacrificable token.
     * @param _cycles an array of cycle numbers, for which rewards should be claimed.
     * @param _sacrificedToken an address of sacrificed token, for which rewards should be claimed.
     * @return claimedAmount amount of tokens are being claimed by 'msg.sender' user.
     */
    function claim(
        uint256[] memory _cycles,
        address _sacrificedToken
    )
        external
        returns (uint256 claimedAmount)
    {
        for (uint256 i = 0; i < _cycles.length; i++) {
            Cycle storage cycle = cycles[_cycles[i]];
            if (
                cycle.cycleCompletedTimestamp == 0
                    || cycle.cycleCompletedTimestamp >= block.timestamp
            ) {
                revert CycleIsNotCompletedYet();
            }
            uint256 rewardAmount = _getReward(_cycles[i], cycle, _sacrificedToken);
            claimedAmount += rewardAmount;
        }
        _transferReward(claimedAmount);
        emit ClaimedReward(msg.sender, claimedAmount);
    }

    /*//////////////////////////////////////////////////////////////
                      COMBINED STAKE AND CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method partially stakes tokens collected as rewards from `_cycles`
     *         cycles for sacrificing `_sacrificedTokens` tokens and partially
     *         claims them. Staking guarantees additional reward for sacrificing
     *         tokens in the next cycles - each sacrificed reward is doubled,
     *         if the same amount is staked.
     * @dev Should be called by those who wants to stake and claim at the same time.
     * @param stakeCoefficient is a value between 0 and 10000 that determines
     *                         the portion of totalRewardAmount to be staked.
     *                         The remaining percentage will be claimed.
     * @param _cycles an array of cycle numbers (must be completed ones).
     * @param _sacrificedTokens an array of sacrificed token addresses.
     * @return stakedAmount amount of tokens which were staked.
     * @return claimedAmount amount of tokens which were claimed.
     */
    function stakeAndClaim(
        uint256 stakeCoefficient,
        uint256[] memory _cycles,
        address[] memory _sacrificedTokens
    )
        external
        returns (uint256 stakedAmount, uint256 claimedAmount)
    {
        if (stakeCoefficient > DENOMINATOR) {
            revert StakePartMoreThan100Percent();
        }
        uint256 totalRewardAmount = _getRewardForCyclesTokens(_cycles, _sacrificedTokens);
        stakedAmount = totalRewardAmount * stakeCoefficient / DENOMINATOR;
        claimedAmount = totalRewardAmount - stakedAmount;
        staked[msg.sender] += stakedAmount;
        _transferReward(claimedAmount);
        emit RewardStaked(msg.sender, lastCompletedCycle + 1, stakedAmount);
        emit ClaimedReward(msg.sender, claimedAmount);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getRewards(
        address user,
        uint256 cycleNumber,
        address sacrificedToken
    )
        public
        view
        returns (uint256 stakeReward, uint256 sacrificeReward)
    {
        uint256 stakeSacrificeRewards = rewards[user][cycleNumber][sacrificedToken];
        (stakeReward, sacrificeReward) = _unpackStakeSacrificeRewards(stakeSacrificeRewards);
    }

    /**
     * @notice View method returns total amount of sacrifice and stake rewards
     *         `beneficiary` user has earned for `cycleNumbers` cycles.
     * @param beneficiary user address.
     * @param cycleNumbers an array of cycle numbers, user has participated in.
     * @return totalSacrificeRewards amount of tokens user has earned for sacrificing + competition reward (if token won).
     * @return totalStakeRewards amount of tokens user has earned by staking.
     */
    function getTotalRewardsOf(
        address beneficiary,
        uint256[] memory cycleNumbers
    )
        external
        view
        returns (uint256 totalSacrificeRewards, uint256 totalStakeRewards)
    {
        for (uint256 i = 0; i < cycleNumbers.length; i++) {
            uint256 cycleNumber = cycleNumbers[i];
            Cycle storage cycle = cycles[cycleNumber];
            for (uint256 k = 0; k < cycle.sacrificableTokens.length; k++) {
                address sacrificedToken = cycle.sacrificableTokens[k];
                uint256 coefficient = cycle.coefficients[sacrificedToken];
                (uint256 stakeReward, uint256 sacrificeReward) =
                    getRewards(beneficiary, cycleNumber, sacrificedToken);
                if (coefficient != 0) {
                    totalSacrificeRewards += sacrificeReward * coefficient / DENOMINATOR;
                } else {
                    totalSacrificeRewards += sacrificeReward;
                }
                totalStakeRewards += stakeReward;
            }
        }
    }

    /**
     * @notice View method returns stake reward for sacrifice reward.
     * @param user user address.
     * @param sacrificedToken token address to get stake reward for.
     * @param reward sacrifice reward to get stake reward for.
     * @return stakeReward amount of tokens user has earned by staking.
     */
    function getStakeRewardForSacrificeReward(
        address user,
        address sacrificedToken,
        uint256 reward
    )
        external
        view
        returns (uint256 stakeReward)
    {
        uint256 cycleNumber = lastCompletedCycle + 1;
        uint256 stakeSacrificeRewards = rewards[user][cycleNumber][sacrificedToken];
        uint256 stakedAmount = staked[user];
        if (stakedAmount != 0) {
            uint256 sacrificeReward;
            (stakeReward, sacrificeReward) =
                _unpackStakeSacrificeRewards(stakeSacrificeRewards);
            if (stakeReward < BONUS_PERCENTAGE * stakedAmount / HUNDRED) {
                if (reward + sacrificeReward >= stakedAmount) {
                    stakeReward = (BONUS_PERCENTAGE * stakedAmount / HUNDRED) - stakeReward;
                } else {
                    stakeReward = BONUS_PERCENTAGE * reward / HUNDRED;
                }
            }
        }
    }

    /**
     * @notice View method returns an array of addresses, which are sacrificable
     *         tokens in a `cycleNumber` cycle.
     * @param cycleNumber number of a cycle, an array is requested for.
     * @return An array of addresses, which are sacrificable tokens.
     */
    function getSacrificableTokens(uint256 cycleNumber)
        external
        view
        returns (address[] memory)
    {
        Cycle storage cycle = cycles[cycleNumber];
        return cycle.sacrificableTokens;
    }

    /**
     * @notice View method returns a coefficient, which is applied as a multiplier
     *         for sacrifice rewards.
     * @dev Cycle winner token has coefficient bigger than cycle loser token, the
     *      maximimum coefficient is getting by winner after the closest competition possible.
     * @param cycleNumber number of a cycle, a coefficient is requested for.
     * @param sacrificedToken address of a token, a coefficient is requested for.
     * @return Returns number in a range from 1 to 1.25x with 10000 as a precision; 0, if cycle is not completed.
     */
    function getSacrificedTokenCoefficient(
        uint256 cycleNumber,
        address sacrificedToken
    )
        external
        view
        returns (uint256)
    {
        Cycle storage cycle = cycles[cycleNumber];
        return cycle.coefficients[sacrificedToken];
    }

    /**
     * @notice View method returns a totalSacrificeRewardsForToken
     *         for a sacrificed token in a `cycleNumber` cycle.
     * @param cycleNumber number of a cycle, a reward amounts are requested for.
     * @param sacrificedToken address of a token, a reward amounts are requested for.
     * @return totalSacrificeRewardsForToken total amount of default rewards for sacrificing `sacrificedToken` token.
     */
    function getTotalSacrificeRewardsForToken(
        uint256 cycleNumber,
        address sacrificedToken
    )
        external
        view
        returns (uint256 totalSacrificeRewardsForToken)
    {
        Cycle storage cycle = cycles[cycleNumber];
        totalSacrificeRewardsForToken = cycle.totalSacrificeRewardsForToken[sacrificedToken];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    function _getReward(
        uint256 cycleNumber,
        Cycle storage _cycle,
        address _sacrificedToken
    )
        internal
        returns (uint256 rewardAmount)
    {
        uint256 coefficient = _cycle.coefficients[_sacrificedToken];
        uint256 stakeSacrificeRewards = rewards[msg.sender][cycleNumber][_sacrificedToken];
        (uint256 stakeReward, uint256 sacrificeReward) =
            _unpackStakeSacrificeRewards(stakeSacrificeRewards);
        rewards[msg.sender][cycleNumber][_sacrificedToken] = 0;
        rewardAmount = (sacrificeReward * coefficient / DENOMINATOR) + stakeReward;
    }

    function _getRewardForCyclesTokens(
        uint256[] memory _cycles,
        address[] memory _sacrificedTokens
    )
        internal
        returns (uint256 totalRewardAmount)
    {
        for (uint256 i = 0; i < _cycles.length; i++) {
            Cycle storage cycle = cycles[_cycles[i]];
            if (
                cycle.cycleCompletedTimestamp == 0
                    || cycle.cycleCompletedTimestamp >= block.timestamp
            ) {
                revert CycleIsNotCompletedYet();
            }
            for (uint256 k = 0; k < _sacrificedTokens.length; k++) {
                address _sacrificedToken = _sacrificedTokens[k];
                uint256 rewardAmount = _getReward(_cycles[i], cycle, _sacrificedToken);
                totalRewardAmount += rewardAmount;
            }
        }
    }

    function _transferReward(uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        bloodline.transfer(msg.sender, amount);
    }
}
