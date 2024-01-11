// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IMigratorChef.sol";
import "./IReferralRegister.sol";
import "./HelixToken.sol";

interface IMasterChef {
    function helixToken() external view returns (HelixToken);
    function percentDec() external view returns (uint256);
    function stakingPercent() external view returns (uint256);
    function devPercent() external view returns (uint256);
    function devaddr() external view returns (address);
    function lastBlockDevWithdraw() external view returns (uint256);
    function HelixTokenPerBlock() external view returns (uint256);
    function BONUS_MULTIPLIER() external view returns (uint256);
    function migrator() external view returns (IMigratorChef);
    function refRegister() external view returns (IReferralRegister);
    // function poolInfo() external view returns (PoolInfo[])
    function totalAllocPoint() external view returns (uint256);
    function startBlock() external view returns (uint256);
    function depositedHelix() external view returns (uint256);
    function poolIds(address lpToken) external view returns (uint256);

    function bucketInfo(
        uint256 _poolId, 
        address _depositorAddress, 
        uint256 _bucketId
    ) external view returns (uint256, uint256, uint256);

    function initialize(
        HelixToken _HelixToken,
        address _devaddr,
        uint256 _HelixTokenPerBlock,
        uint256 _startBlock,
        uint256 _stakingPercent,
        uint256 _devPercent,
        IReferralRegister _referralRegister
    ) external;

    function updateMultiplier(uint256 _multiplierNumber) external;
    function withdrawDevAndRefFee() external;
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external;
    function set( uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;
    function setMigrator(IMigratorChef _migrator) external;
    function pause() external;
    function unpause() external;
    function migrate(uint256 _pid) external;
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
    function setReferralRegister(address _address) external;
    function pendingHelixToken(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function bucketDeposit(uint256 _bucketId, uint256 _poolId, uint256 _amount) external;
    function bucketWithdraw(uint256 _bucketId, uint256 _poolId, uint256 _amount) external;
    function bucketWithdrawAmountTo(address _recipient, uint256 _bucketId, uint256 _poolId, uint256 _amount) external;
    function bucketWithdrawYieldTo(address _recipient, uint256 _bucketId, uint256 _poolId, uint256 _yield) external;
    function updateBucket(uint256 _bucketId, uint256 _poolId) external;
    function getBucketYield(uint256 _bucketId, uint256 _poolId) external view returns(uint256 yield);
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
    function poolLength() external view returns(uint256);
    function getLpToken(uint256 _pid) external view returns(address);
    function getPoolId(address _lpToken) external view returns (uint256);
    function massUpdatePools() external;
    function setDevAddress(address _devaddr) external;
    function updateHelixPerBlock(uint256 newAmount) external;
}
