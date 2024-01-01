// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./BaseRewardPool.sol";
import "./BaseRewardPoolV3.sol";

/// @title A contract for managing rewards for a pool
/// @author Magpie Team
/// @notice You can use this contract for getting informations about rewards for a specific pools
contract BribeRewardPool is BaseRewardPoolV3 {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    uint256 public totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== Errors ========== */

    error OnlyOperator();    

    /* ============ Constructor ============ */

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _operator,
        address _rewardManager
    ) BaseRewardPoolV3(_stakingToken, _rewardToken, _operator, _rewardManager) {}

    /* ============ Modifiers ============ */

    modifier onlyOperator() {
        if (msg.sender != operator)
            revert OnlyOperator();
        _;
    }

    /* ============ External Getters ============ */

    function balanceOf(address _account) public override virtual view returns (uint256) {
        return _balances[_account];
    }

    function totalStaked() public override virtual view returns (uint256) {
        return totalSupply;
    }

    /* ============ External Functions ============ */

    /// @notice Updates information for a user in case of staking. Can only be called by the Masterchief operator
    /// @param _for Address account
    /// @param _amount Amount of newly staked tokens by the user on masterchief
    function stakeFor(address _for, uint256 _amount)
        external
        virtual
        onlyOperator
        updateRewards(_for, rewardTokens)
    {
        totalSupply = totalSupply + _amount;
        _balances[_for] = _balances[_for] + _amount;

        emit Staked(_for, _amount);
    }

    /// @notice Updates informaiton for a user in case of a withdraw. Can only be called by the Masterchief operator
    /// @param _for Address account
    /// @param _amount Amount of withdrawed tokens by the user on masterchief
    function withdrawFor(
        address _for,
        uint256 _amount,
        bool claim
    ) external virtual onlyOperator updateRewards(_for, rewardTokens) {
        totalSupply = totalSupply - _amount;
        _balances[_for] = _balances[_for] - _amount;

        emit Withdrawn(_for, _amount);

        if (claim) {
            _getReward(_for);
        }
    }

    /* ============ Internal Functions ============ */

    function _getReward(address _account) internal virtual {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            uint256 reward = earned(_account, rewardToken);
            if (reward > 0) {
                userRewards[rewardToken][_account] = 0;
                IERC20(rewardToken).safeTransfer(_account, reward);
                emit RewardPaid(_account, _account, reward, rewardToken);
            }
        }
    }    
}