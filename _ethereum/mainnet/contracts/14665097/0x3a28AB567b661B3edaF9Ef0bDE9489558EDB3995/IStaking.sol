// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ICompoundRateKeeperV2.sol";

interface IStaking is ICompoundRateKeeperV2 {
    /// @notice Update lock period.
    /// @param _lockPeriod Timestamp
    function setLockPeriod(uint64 _lockPeriod) external;

    /// @notice Stake tokens to contract.
    /// @param _amount Stake amount
    function stake(uint256 _amount) external returns (bool);

    /// @notice Withdraw tokens from stake.
    /// @param _withdrawAmount Tokens amount to withdraw
    function withdraw(uint256 _withdrawAmount) external returns (bool);

    /// @notice Return amount of tokens + percents at this moment.
    /// @param _address Staker address
    function getDenormalizedAmount(address _address) external view returns (uint256);

    /// @notice Return amount of tokens + percents at given timestamp.
    /// @param _address Staker address
    /// @param _timestamp Given timestamp (seconds)
    function getPotentialAmount(address _address, uint64 _timestamp) external view returns (uint256);

    /// @notice Transfer tokens to contract as reward.
    /// @param _amount Token amount
    function supplyRewardPool(uint256 _amount) external returns (bool);

    /// @notice Return total reward amount.
    function getTotalRewardAmount() external view returns (uint256);

    /// @notice Return aggregated staked amount (without percents).
    function getAggregatedAmount() external view returns (uint256);

    /// @notice Return aggregated normalized amount.
    function getAggregatedNormalizedAmount() external view returns (uint256);

    /// @notice Return coefficient in decimals. If coefficient more than 1, all holders will be able to receive awards.
    function monitorSecurityMargin() external view returns (uint256);

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external returns (bool);

    /// @notice Transfer stuck native tokens.
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckNativeToken(address payable _to, uint256 _amount) external;
}
