//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

contract StakingManager is AccessControl {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;

    uint256 private rewardTokensPerBlock;
    uint256 private constant REWARDS_PRECISION = 1e12;
    uint256 public constant MAX_FEE = 100;

    bytes32 public constant POOLE_ROLE = keccak256("POOL_ROLE");

    struct UserStaker {
        uint256 amount;
        uint256 rewards;
        uint256 expireTime;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 stakeToken;
        uint256 lastRewardedBlock;
        uint256 duration;
        uint256 accumulatedRewardsPerShare;
        uint256 harvestFee;
    }

    PoolInfo[] public pools;
    mapping(uint256 => mapping(address => UserStaker)) public userInfo;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event Cashout(address indexed user, uint256 amount);
    event HarvestRewards(address indexed user, uint256 indexed poolId, uint256 amount);
    event PoolCreated(uint256 poolId);

    modifier poolValidated(uint256 _poolId) {
        require(_poolId >= 0, "MasterChefV2: PoolId can't negative");
        require(_poolId <= pools.length, "MasterChefV2: Pool less max length");
        _;
    }
    constructor(address _rewardTokenAddress, uint256 _rewardTokensPerBlock) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(POOLE_ROLE, _msgSender());

        rewardToken = IERC20(_rewardTokenAddress);
        rewardTokensPerBlock = _rewardTokensPerBlock;
    }


    function createPool(IERC20 _stakeToken, uint256 _locktime, uint256 _fee) external {
        require(hasRole(POOLE_ROLE, _msgSender()), "MasterChefV2: Access denied");
        require(_locktime >= 0, "MasterChefV2: Lock Time not validated");
        require(_fee >= 0 && _fee <= MAX_FEE, "MasterChefV2: Fee not validated");
        PoolInfo memory pool;
        pool.stakeToken = _stakeToken;
        pool.accumulatedRewardsPerShare = 0;
        pool.duration = _locktime;
        pool.harvestFee = _fee;
        pools.push(pool);
        uint256 poolId = pools.length - 1;
        updatePoolRewards(poolId);
        emit PoolCreated(poolId);
    }

    function getMultiplier(uint256 lastBlock) internal view returns (uint256){
        require(block.number >= lastBlock, "MasterChefV2: block reward revert");
        uint256 blockReward;
        unchecked {
            blockReward = block.number - lastBlock;
        }
        return blockReward;
    }

    function getAPR(uint256 _poolId) external poolValidated(_poolId) view returns (uint256) {
        PoolInfo storage pool = pools[_poolId];
        uint256 apr = pool.accumulatedRewardsPerShare;
        return apr;
    }

    function getLockTime(uint256 _poolId) external poolValidated(_poolId) view returns (uint256){
        UserStaker storage user = userInfo[_poolId][msg.sender];
        uint256 lockTime = user.expireTime;
        return lockTime;
    }

    function getDurationLockTime(uint256 _poolId) external poolValidated(_poolId) view returns (uint256){
        PoolInfo storage pool = pools[_poolId];
        uint256 lockTime = pool.duration;
        return lockTime;
    }

    function getPoolLength() external view returns (uint256) {
        return pools.length;
    }

    function getPoolHarvestFee(uint256 _poolId) external poolValidated(_poolId) view returns (uint256) {
        PoolInfo storage pool = pools[_poolId];
        uint256 fee = pool.harvestFee;
        return fee;
    }

    function updatePoolHarvestFee(uint256 _poolId, uint256 _fee) external poolValidated(_poolId) {
        require(hasRole(POOLE_ROLE, _msgSender()), "MasterChefV2: Access denied");
        PoolInfo storage pool = pools[_poolId];
        pool.harvestFee = _fee;
    }

    function calcRewardHarvestFee(uint256 _reward, uint256 _fee) internal pure returns (uint256) {
        uint256 rewardFee = _reward * _fee / MAX_FEE;
        uint256 rewardsToHarvest = _reward - rewardFee;
        return rewardsToHarvest;
    }

    function pendingReward(uint256 _poolId) internal view returns (uint256) {
        PoolInfo storage pool = pools[_poolId];
        UserStaker storage user = userInfo[_poolId][msg.sender];
        uint256 rewardsToHarvest = user.amount * pool.accumulatedRewardsPerShare / REWARDS_PRECISION - user.rewardDebt;
        return rewardsToHarvest;
    }

    function getRewardHarvest(uint256 _poolId, address _who) external poolValidated(_poolId) view returns (uint256){
        PoolInfo storage pool = pools[_poolId];
        UserStaker storage user = userInfo[_poolId][_who];
        uint256 rewardsToHarvest = pendingReward(_poolId) + user.rewards;
        if (pool.harvestFee > 0 && rewardsToHarvest > 0) {
            rewardsToHarvest = calcRewardHarvestFee(rewardsToHarvest, pool.harvestFee);
        }
        return rewardsToHarvest;
    }

    function harvestRewards(uint256 _poolId) public poolValidated(_poolId) {
        updatePoolRewards(_poolId);
        PoolInfo storage pool = pools[_poolId];
        UserStaker storage user = userInfo[_poolId][msg.sender];
        uint256 rewardsToHarvest = pendingReward(_poolId) + user.rewards;

        if (rewardsToHarvest == 0) {
            return;
        }

        if (pool.harvestFee > 0) {
            rewardsToHarvest = calcRewardHarvestFee(rewardsToHarvest, pool.harvestFee);
        }

        user.rewards = 0;
        user.rewardDebt = user.amount * pool.accumulatedRewardsPerShare / REWARDS_PRECISION;
        emit HarvestRewards(_msgSender(), _poolId, rewardsToHarvest);
        rewardToken.transfer(_msgSender(), rewardsToHarvest);
    }

    function updatePoolRewards(uint256 _poolId) private {
        PoolInfo storage pool = pools[_poolId];
        uint256 lpSupply = pool.stakeToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardedBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardedBlock);
        uint256 rewards = multiplier * rewardTokensPerBlock;
        pool.accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare + (rewards * REWARDS_PRECISION / lpSupply);
        pool.lastRewardedBlock = block.number;
    }

    function deposit(uint256 _poolId, uint256 _amount) external poolValidated(_poolId) {
        require(_amount > 0, "MasterChefV2: Deposit amount can't be zero");

        PoolInfo storage pool = pools[_poolId];
        UserStaker storage user = userInfo[_poolId][msg.sender];

        require(pool.stakeToken.balanceOf(_msgSender()) >= _amount, "MasterChefV2: Insufficient Balance");


        updatePoolRewards(_poolId);

        if (user.amount > 0) {
            user.rewards += pendingReward(_poolId);
        }
        if (user.amount == 0 && pool.duration > 0) {
            user.expireTime = block.timestamp + pool.duration;
        }

        pool.stakeToken.safeTransferFrom(_msgSender(), address(this), _amount);
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * pool.accumulatedRewardsPerShare / REWARDS_PRECISION;

        emit Deposit(_msgSender(), _poolId, _amount);
    }

    function withdrawAndHarvest(uint256 _poolId) external poolValidated(_poolId) {
        PoolInfo storage pool = pools[_poolId];
        UserStaker storage user = userInfo[_poolId][msg.sender];

        require(block.timestamp > user.expireTime, "MasterChefV2: It is not time to withdraw");

        uint256 amount = user.amount;
        require(amount > 0, "MasterChefV2: Withdraw amount can't be zero");
        require(pool.stakeToken.balanceOf(address(this)) >= amount, "MasterChefV2: Insufficient Balance");

        updatePoolRewards(_poolId);

        uint256 rewardsToHarvest = pendingReward(_poolId) + user.rewards;
        if (rewardsToHarvest == 0) {
            return;
        }

        if (pool.harvestFee > 0) {
            rewardsToHarvest = calcRewardHarvestFee(rewardsToHarvest, pool.harvestFee);
        }

        user.rewards = 0;
        user.amount = 0;
        user.rewardDebt = user.amount * pool.accumulatedRewardsPerShare / REWARDS_PRECISION;

        emit HarvestRewards(_msgSender(), _poolId, rewardsToHarvest);
        rewardToken.transfer(_msgSender(), rewardsToHarvest);
        emit Withdraw(_msgSender(), _poolId, amount);
        pool.stakeToken.safeTransfer(_msgSender(), amount);
    }

    function emergencyWithdraw(uint256 _poolId) external poolValidated(_poolId) {
        PoolInfo storage pool = pools[_poolId];
        UserStaker storage user = userInfo[_poolId][msg.sender];

        require(block.timestamp > user.expireTime, "MasterChefV2: It is not time to withdraw");

        uint256 amount = user.amount;
        require(amount > 0, "MasterChefV2: Withdraw amount can't be zero");
        require(pool.stakeToken.balanceOf(address(this)) >= amount, "MasterChefV2: Insufficient Balance");

        updatePoolRewards(_poolId);
        user.amount = 0;
        user.rewards = 0;
        user.rewardDebt = user.amount * pool.accumulatedRewardsPerShare / REWARDS_PRECISION;

        emit Withdraw(_msgSender(), _poolId, amount);
        pool.stakeToken.safeTransfer(_msgSender(), amount);
    }

}
