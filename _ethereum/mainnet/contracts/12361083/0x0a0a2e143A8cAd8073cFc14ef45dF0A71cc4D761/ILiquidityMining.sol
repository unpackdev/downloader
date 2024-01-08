// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface ILiquidityMining {
    struct UnlockInfo {
        uint256 block;
        uint256 quota;
    }
    function getAllUnlocks() external view returns (UnlockInfo[] memory);
    function unlocksTotalQuotation() external view returns(uint256);

    struct PoolInfo {
        address token;
        uint256 accRewardPerShare;
        uint256 allocPoint;
        uint256 lastRewardBlock;
    }
    function getAllPools() external view returns (PoolInfo[] memory);
    function totalAllocPoint() external returns(uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claim() external;
    function getPendingReward(uint256 _pid, address _user)
    external view
    returns(uint256 total, uint256 available);

    function rewardToken() external view returns(address);
    function reservoir() external view returns(address);
    function rewardPerBlock() external view returns(uint256);
    function startBlock() external view returns(uint256);
    function endBlock() external view returns(uint256);

    function rewards(address) external view returns(uint256);
    function claimedRewards(address) external view returns(uint256);
    function poolPidByAddress(address) external view returns(uint256);
    function isTokenAdded(address _token) external view returns (bool);
    function calcUnlocked(uint256 reward) external view returns(uint256 claimable);

    struct UserPoolInfo {
        uint256 amount;
        uint256 accruedReward;
    }
    function userPoolInfo(uint256, address) external view returns(UserPoolInfo memory);
}
