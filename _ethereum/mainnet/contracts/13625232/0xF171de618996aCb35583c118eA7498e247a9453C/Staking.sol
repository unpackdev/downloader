// SPDX-License-Identifier: MIT AND AGPL-3.0-only
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./FixedPoint.sol";

import "./IERC900.sol";
import "./Modifiers.sol";


/**
* @title  Domination Finance LP Staking contract
* @notice Distributes $DOM tokens to dominance pair liquidity providers who stake their LP tokens. Once the "staking
*         period" ends, $DOM rewards are reserved for stakers in proportion to their share of the pool. If a user
*         unstakes before the end of the program, only part of the reserved rewards are granted. This partial reward is
*         quadratic over the program duration, and is scaled by an additional linear penalty during the penalty period.
*         Any reserved $DOM given up by early unstakes can be withdrawn by the contract owner.
*/
contract Staking is IERC900, Modifiers, Ownable, ReentrancyGuard {
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;

    /* Variables, Declarations and Constructor */

    // total staked LP tokens at the end of the 7 day staking period
    uint256 private _totalStaked;

    // withdrawn or renounced rewards
    uint256 public unlockedRewards;

    struct Account {
        uint256 staked;
    }
    mapping(address => Account) private _balances;

    struct RewardOutput {
        FixedPoint.Unsigned rewardRatio;
        FixedPoint.Unsigned penaltyRatio;
        FixedPoint.Unsigned amount;
    }

    /**
     * @notice Create a Staking contract for a particular LP token, period, and $DOM allocation.
     * @dev    Contract must be funded and permitted to transfer $DOM (if applicable) before users can stake.
     * @param lpToken address of LP token, i.e. BTC-ALTDOM-Dec-2022/USDC
     * @param domToken address of rewards token
     * @param owner recipient of leftover rewards
     * @param totalDOM maximum DOM to be distributed
     * @param stakingStart timestamp when users can stake
     * @param lspExpiration timestamp when users can claim their entire reserved reward
     */
    constructor(
        address lpToken,
        address domToken,
        address owner,
        uint256 totalDOM,
        uint256 stakingStart,
        uint256 lspExpiration
    )
        Ownable()
        ReentrancyGuard()
    {
        if (owner != _msgSender()) {
            transferOwnership(owner);
        }

        require(totalDOM > 0, ERROR_ZERO_AMOUNT);
        TOTAL_DOM = totalDOM;

        require(stakingStart > block.timestamp, ERROR_PAST_TIMESTAMP);
        STAKING_START_TIMESTAMP = stakingStart;

        require(lspExpiration - STAKING_START_TIMESTAMP > REWARD_PERIOD, ERROR_EXPIRES_TOO_SOON);
        LSP_EXPIRATION = lspExpiration;

        LP_TOKEN = IERC20(lpToken);
        DOM_TOKEN = IERC20(domToken);
    }

    /* State changing functions */

    /**
     * @notice Stake LP tokens
     * @dev    Must approve at least <amount> LP tokens before calling
     * @param amount LP tokens to stake
     **/
    function stake(uint256 amount)
        external
        override
        duringStaking
        nonReentrant
    {
        address sender = _msgSender();
        _stakeFor(sender, sender, amount);
    }

    /**
     * @notice Stake LP tokens on behalf of an address, which will receive the LP tokens and rewards when it unstake()s.
     * @dev    Must approve at least <amount> LP tokens before calling
     * @param amount LP tokens to stake
     * @param beneficiary address which will be able to unstake
     **/
    function stakeFor(
        address beneficiary,
        uint256 amount
    )
        external
        override
        duringStaking
        nonReentrant
    {
        address sender = _msgSender();
        _stakeFor(sender, beneficiary, amount);
    }

    /**
     * @notice Unstake previously-staked LP tokens and receive a $DOM reward, if applicable. Partial unstakes supported.
     * @param amount LP tokens to withdraw
     **/
    function unstake(uint256 amount)
        external
        override
        nonReentrant
    {
        _unstake(_msgSender(), amount);
    }


    /**
    * @notice Withdraw $DOM beyond what is committed to staking rewards.
    * @dev    Unstaking early "unlocks" rewards in excess of those given out. The remaining funds out of TOTAL_DOM have
              been promised to stakers. Contract balance could also be greater than unlocked + locked, in which case
              also withdraw the excess.
              Callable at any time without affecting future rewards, but will revert if contract is underfunded. Likely
              called soon after the end of the staking program, and some time later for any stragglers.
    */
    function withdrawLeftover() external {
        uint256 locked = TOTAL_DOM - unlockedRewards;
        DOM_TOKEN.safeTransfer(owner(), DOM_TOKEN.balanceOf(address(this)) - locked);
    }

    /* View functions */

    function stakingToken() external view override returns (address) {
        return address(LP_TOKEN);
    }

    function rewardToken() external view override returns (address) {
        return address(DOM_TOKEN);
    }

    function totalStaked() external view override returns (uint256) {
        return _totalStaked;
    }

    function totalStakedFor(address user) external view override returns (uint256)  {
        return _balances[user].staked;
    }

    /**
    * @dev This contract doesn't support IERC900's history interface. Use the event log or an archive node.
    */
    function supportsHistory() external pure override returns (bool) {
        return false;
    }

    function isStakingAllowed() external view returns (bool) {
        return _isStakingAllowed();
    }

    function remainingDOM() external view returns (uint256) {
        return DOM_TOKEN.balanceOf(address(this));
    }

    function rewardRatio() external view returns (uint256) {
        return _getRewardRatioAt(block.timestamp).rawValue;
    }

    function penaltyRatio() external view returns (uint256) {
        return _getPenaltyRatioAt(block.timestamp).rawValue;
    }

    function ratios() external view returns (uint256 reward, uint256 penalty) {
        reward = _getRewardRatioAt(block.timestamp).rawValue;
        penalty = _getPenaltyRatioAt(block.timestamp).rawValue;
    }

    function account(address user)
        external
        view
        returns (
            uint256 _rewardRatio,
            uint256 _penaltyRatio,
            uint256 _staked,
            uint256 _rewards
        )
    {
        RewardOutput memory output = _getUserRewards(block.timestamp, user);
        _rewardRatio = output.rewardRatio.rawValue;
        _penaltyRatio = output.penaltyRatio.rawValue;
        _rewards = output.amount.rawValue;
        _staked = _balances[user].staked;
    }

    /* Internal functions */

    function _stakeFor(address from, address user, uint256 amount) internal {
        require(amount > 0, ERROR_ZERO_AMOUNT);
        require(user != address(0), ERROR_ZERO_ADDRESS);

        require(LP_TOKEN.allowance(from, address(this)) >= amount, ERROR_NOT_ENOUGH_ALLOWANCE);
        LP_TOKEN.safeTransferFrom(from, address(this), amount);

        _balances[user].staked += amount;
        _totalStaked += amount;

        emit Staked(from, amount, _balances[user].staked);
    }

    function _unstake(address user, uint256 amount) internal {
        require(amount > 0, ERROR_ZERO_AMOUNT);
        require(amount <= _balances[user].staked, ERROR_NOT_ENOUGH_STAKE);

        RewardOutput memory output =
            _getUserRewards(block.timestamp, user);

        uint256 maxPartialRewards = FixedPoint.Unsigned(amount)
            .div(FixedPoint.Unsigned(_totalStaked))
            .mul(FixedPoint.Unsigned(TOTAL_DOM))
            .rawValue;

        uint256 partialRewards = FixedPoint.Unsigned(amount)
            .div(FixedPoint.Unsigned(_balances[user].staked))
            .mul(output.amount)
            .rawValue;

        _balances[user].staked -= amount;
        if (_isStakingAllowed()) { // during the staking period, withdraws don't waste any rewards
            _totalStaked -= amount;
        }

        // return unstaked LP tokens
        LP_TOKEN.safeTransfer(user, amount);

        unlockedRewards += maxPartialRewards;

        if (partialRewards > 0) {
            DOM_TOKEN.safeTransfer(user, partialRewards);
        }

        emit Unstaked(user, amount, _balances[user].staked);
    }

    function rewardsAt(
        uint256 timestamp,
        address user
    )
        external
        view
        returns (
            uint256 out_rewardRatio,
            uint256 out_penaltyRatio,
            uint256 out_amount
        )
    {
        RewardOutput memory x = _getUserRewards(timestamp, user);
        out_rewardRatio = x.rewardRatio.rawValue;
        out_penaltyRatio = x.penaltyRatio.rawValue;
        out_amount = x.amount.rawValue;
    }

    function _getUserRewards(
        uint256 timestamp,
        address user
    )
        internal
        view
        returns (RewardOutput memory)
    {
        return _computeRewards(
            timestamp,
            _balances[user].staked,
            _totalStaked,
            TOTAL_DOM);
    }

    function _computeRewards(
        uint256 p_timestamp,
        uint256 p_userStaked,
        uint256 p_totalStaked,
        uint256 p_totalRewards
    )
        internal
        view
        returns (RewardOutput memory)
    {
        RewardOutput memory output;
        output.rewardRatio = _getRewardRatioAt(p_timestamp);
        output.penaltyRatio = _getPenaltyRatioAt(p_timestamp);

        if (p_totalStaked > 0) {
            output.amount =
                FixedPoint.Unsigned(p_totalRewards)
                .mul(FixedPoint.Unsigned(p_userStaked)
                    .div(FixedPoint.Unsigned(p_totalStaked)))
                .mul(output.rewardRatio)
                .mul(FixedPoint.fromUnscaledUint(1).sub(output.penaltyRatio))
                
                // share of user out of total staked
            ;
        }
        else {
            output.amount = FixedPoint.fromUnscaledUint(0);
        }

        return output;
    }

    function _getRewardRatioAt(uint256 timestamp)
        internal
        view
        returns (FixedPoint.Unsigned memory)
    {
        FixedPoint.Unsigned memory offset;
        if (timestamp > STAKING_START_TIMESTAMP) {
            offset = FixedPoint.fromUnscaledUint(timestamp).sub(STAKING_START_TIMESTAMP);
        } else {
            offset = FixedPoint.fromUnscaledUint(0);
        }
        
        FixedPoint.Unsigned memory lspLength =
            FixedPoint.fromUnscaledUint(LSP_EXPIRATION).sub(STAKING_START_TIMESTAMP);

        if (offset.isLessThan(STAKING_PERIOD)) {
            return FixedPoint.fromUnscaledUint(0);
        }
        else if (offset.isLessThan(lspLength)) {
            offset = offset.sub(STAKING_PERIOD);
            lspLength = lspLength.sub(STAKING_PERIOD);

            return
                offset.pow(2)
                .div(lspLength.pow(2));
        }
        else {
            return FixedPoint.fromUnscaledUint(1);
        }
    }

    function _getPenaltyRatioAt(uint256 timestamp)
        internal
        view
        returns (FixedPoint.Unsigned memory)
    {
        FixedPoint.Unsigned memory offset;
        if (timestamp > STAKING_START_TIMESTAMP) {
            offset = FixedPoint.fromUnscaledUint(timestamp).sub(STAKING_START_TIMESTAMP);
        } else {
            offset = FixedPoint.fromUnscaledUint(0);
        }

        if (offset.isLessThan(STAKING_PERIOD)) {
            return FixedPoint.fromUnscaledUint(1);
        }
        else if (offset.isLessThan(REWARD_PERIOD)) {
            return
                FixedPoint.fromUnscaledUint(1)
                .sub(
                    offset.sub(STAKING_PERIOD)
                    .div(REWARD_PERIOD - STAKING_PERIOD));
        }
        else {
            return FixedPoint.fromUnscaledUint(0);
        }
    }
}
