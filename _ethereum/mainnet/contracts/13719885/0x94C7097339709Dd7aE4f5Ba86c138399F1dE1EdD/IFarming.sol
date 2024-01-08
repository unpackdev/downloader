// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFarming{
    function userInfo(uint16 poolId, address user) external view returns(uint256 amount, uint256 pendingReward, uint256 totalRewarded, uint256 rewardDebt);
    function poolInfo(uint256 poolId) external view returns(address lpToken, uint64 allocPoint, uint64 startBlock, uint64 endBlock, uint64 lastRewardBlock, uint256 accTokenPerShare, uint256 totalDeposited);
    function depositTo(uint16 _pid, uint256 _amount, address _beneficiary) external;
    function deposit(uint16 _pid, uint256 _amount) external;
    function withdraw(uint16 _pid, uint256 _amount) external;
    function claimReward(uint16 _pid) external;
    function exit(uint16 _pid) external;
    function emergencyWithdraw(uint16 _pid) external;
    function getContractData() external view returns (uint256, uint256, uint64);
    function getPoolLength() external view returns (uint256);
    function getPool(uint16 _index) external view returns (address, uint256, uint64, uint64, uint64, uint256, uint256);
    function getUserInfo(uint16 _pid, address _user) external view returns (uint256, uint256, uint256);

}
