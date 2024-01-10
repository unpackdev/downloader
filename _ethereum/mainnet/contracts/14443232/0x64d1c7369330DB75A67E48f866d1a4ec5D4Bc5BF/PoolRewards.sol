// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./PoolBase.sol";

abstract contract PoolRewards is PoolBase {
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Amount of CPOOL rewards per block for liquidity providers in this pool
    uint256 public rewardPerBlock;

    /// @notice Value by which all rewards are magnified for calculation
    uint256 internal constant REWARD_MAGNITUDE = 2**128;

    /// @notice Block when last staking reward distribution occured
    uint256 internal _lastRewardDistribution;

    /// @notice Reward per LP token, magnified by 2**128 for increased precision
    uint256 internal _magnifiedRewardPerShare;

    /// @notice Reward corrections of accounts (to remain previous rewards unchanged when user's balance changes)
    mapping(address => int256) internal _magnifiedRewardCorrections;

    /// @notice Reward withdrawals of accounts
    mapping(address => uint256) internal _withdrawals;

    // EVENTS

    /// @notice Event emitted when account withdraws his reward
    event RewardWithdrawn(address indexed account, uint256 amount);

    /// @notice Event emitted when new reward per block is set
    event RewardPerBlockSet(uint256 newRewardPerBlock);

    // PUBLIC FUNCTIONS

    /**
     * @notice Function is called through Factory to withdraw reward for some user
     * @param account Account to withdraw reward for
     * @return Withdrawn amount
     */
    function withdrawReward(address account)
        external
        onlyFactory
        returns (uint256)
    {
        _accrueInterest();
        _distributeReward();

        uint256 withdrawable = withdrawableRewardOf(account);
        if (withdrawable > 0) {
            _withdrawals[account] += withdrawable;
            emit RewardWithdrawn(account, withdrawable);
        }

        return withdrawable;
    }

    /**
     * @notice Function is called by Factory to set new reward speed per block
     * @param rewardPerBlock_ New reward per block
     */
    function setRewardPerBlock(uint256 rewardPerBlock_) external onlyFactory {
        _accrueInterest();
        _distributeReward();
        if (_lastRewardDistribution == 0) {
            _lastRewardDistribution = _info.lastAccrual;
        }
        rewardPerBlock = rewardPerBlock_;

        emit RewardPerBlockSet(rewardPerBlock_);
    }

    // VIEW FUNCTIONS

    /**
     * @notice Gets total accumulated reward of some account
     * @return Total accumulated reward of account
     */
    function accumulativeRewardOf(address account)
        public
        view
        returns (uint256)
    {
        BorrowInfo memory info = _accrueInterestVirtual();
        uint256 currentRewardPerShare = _magnifiedRewardPerShare;
        if (
            _lastRewardDistribution != 0 &&
            info.lastAccrual > _lastRewardDistribution &&
            totalSupply() > 0
        ) {
            uint256 period = info.lastAccrual - _lastRewardDistribution;
            currentRewardPerShare +=
                (REWARD_MAGNITUDE * period * rewardPerBlock) /
                totalSupply();
        }

        return
            ((balanceOf(account) * currentRewardPerShare).toInt256() +
                _magnifiedRewardCorrections[account]).toUint256() /
            REWARD_MAGNITUDE;
    }

    /**
     * @notice Gets withdrawn part of reward of some account
     * @return Withdrawn reward of account
     */
    function withdrawnRewardOf(address account) public view returns (uint256) {
        return _withdrawals[account];
    }

    /**
     * @notice Gets currently withdrawable reward of some account
     * @return Withdrawable reward of account
     */
    function withdrawableRewardOf(address account)
        public
        view
        returns (uint256)
    {
        return accumulativeRewardOf(account) - withdrawnRewardOf(account);
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Internal function for rewards distribution
     */
    function _distributeReward() internal {
        if (
            rewardPerBlock > 0 &&
            _lastRewardDistribution != 0 &&
            _info.lastAccrual > _lastRewardDistribution &&
            totalSupply() > 0
        ) {
            uint256 period = _info.lastAccrual - _lastRewardDistribution;
            _magnifiedRewardPerShare +=
                (REWARD_MAGNITUDE * period * rewardPerBlock) /
                totalSupply();
        }
        _lastRewardDistribution = _info.lastAccrual;
    }

    /**
     * @notice Override of mint function with rewards corrections
     * @param account Account to mint for
     * @param value Amount to mint
     */
    function _mint(address account, uint256 value) internal virtual override {
        _distributeReward();
        super._mint(account, value);
        _magnifiedRewardCorrections[account] -= (_magnifiedRewardPerShare *
            value).toInt256();
    }

    /**
     * @notice Override of burn function with rewards corrections
     * @param account Account to burn from
     * @param value Amount to burn
     */
    function _burn(address account, uint256 value) internal virtual override {
        _distributeReward();
        super._burn(account, value);
        _magnifiedRewardCorrections[account] += (_magnifiedRewardPerShare *
            value).toInt256();
    }
}
