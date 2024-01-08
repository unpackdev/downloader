pragma solidity ^0.7.0;

/// @title interfaces used by the vesting contract

interface IStakingPoolsVesting {
    function depositVesting(address _account, uint256 _poolId, uint256 _depositAmount) external returns (bool);
    function withdrawOrClaimOrExitVesting(address _account, uint256 _poolId, uint256 _withdrawAmount, bool _doWithdraw, bool _doExit) external returns (bool, uint256);
}