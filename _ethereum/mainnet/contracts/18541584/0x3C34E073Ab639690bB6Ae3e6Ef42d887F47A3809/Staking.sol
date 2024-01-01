// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./console.sol";

contract Staking is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    IERC20 public stakingToken;

    uint256 public pool0CreatedTime;   // early pool created time
    uint256 public pool0LifeTime;      // early pool life time (after this period, the pool cannot be staked)
    uint256 public poolFreezeTime;     // pool freeze time (staked SXS in a pool it is fully locked for this period and can't unstake)

    struct UserInfo {
        uint256 amount;                 // user's staked balance
        uint256 lastStakeTime;
    }

    struct PoolInfo {
        uint256 poolLockupSeconds;      // pool lock time
        uint256 stakeMinAmount;         // stake minimum amount
        uint256 stakeMaxAmount;         // stake maximum amount
        uint256 poolRewardRate;         // pool Reward Rate
        uint256 poolBalanceAllocation;  // pool available balance
        uint256 poolRewardAllocation;   // pool reward allocation
        uint256 poolStakedBalance;      // pool stake balance
        uint256 poolOriginalAllocation; // pool original allocation
    }

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Stake(
        uint8 indexed pid,
        address indexed user,
        uint256 stakedAmount
    );

    event UnStake(uint8 indexed pid, address indexed user, uint256 stakedAmount);

    event UpdateFreezeTime(uint256 freezeTime);

    modifier validStakeAmount(uint8 _pid, uint256 _amount) {
        require(
            _amount != 0 &&
                _amount >= poolInfo[_pid].stakeMinAmount &&
                _amount <= poolInfo[_pid].stakeMaxAmount,
            "Input amount out of range"
        );
        _;
    }

    modifier validPID(uint8 _pid) {
        require(_pid < poolInfo.length, "Invalid pool index");
        _;
    }

    /**
     * @notice initialize function for init contract
     * @param token token address of staking
     * @param earlyPoolData early Pool Info
     * @param lifeTime early Pool life time
     * @param freezeTime Pool freeze time
     */
    function Staking_init(
        address token,
        PoolInfo calldata earlyPoolData,
        uint256 lifeTime,
        uint256 freezeTime
    ) public initializer {
        stakingToken = IERC20(token);
        pool0CreatedTime = block.timestamp;
        poolInfo.push(earlyPoolData);
        pool0LifeTime = lifeTime;
        poolFreezeTime = freezeTime;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @notice stake internal function
     * @param pid pool index
     * @param amount staking amount
     */
    function _stake(uint8 pid, uint256 amount) internal {
        if (pid == 0) {
            // Early pool can only stake while life time
            uint256 currentTime = block.timestamp;
            require(
                currentTime < pool0CreatedTime + pool0LifeTime,
                "Can not stake after life time"
            );
        }
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount == 0, "User already staked");
        require(
            poolInfo[pid].poolBalanceAllocation >= amount,
            "Overflow pool stake allocation"
        );
        // deposit token amount from user to this
        stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );

        // update pool stake balance
        poolInfo[pid].poolStakedBalance += amount;

        // update pool balance and reward allocation
        uint256 rewardAmount = amount * (poolInfo[pid].poolRewardRate) / 10000;
        poolInfo[pid].poolBalanceAllocation -= amount;
        poolInfo[pid].poolRewardAllocation -= rewardAmount;
        // update user amount and last time
        user.amount = amount;
        user.lastStakeTime = block.timestamp;
        emit Stake(pid, msg.sender, amount);
    }

    /**
     * @notice unstake internal function
     * @param pid pool index
     */
    function _unstake(uint8 pid) internal {
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount > 0, "User not staked");
        require(block.timestamp - user.lastStakeTime >= poolFreezeTime, "Pool Freeze Time");
        uint256 unstakeAmount = user.amount;
        uint256 rewardAmount = user.amount * poolInfo[pid].poolRewardRate / 10000;

        if (block.timestamp - user.lastStakeTime < poolInfo[pid].poolLockupSeconds) {
            // recover pool balance and reward allocation when unstake before lockup period
            poolInfo[pid].poolBalanceAllocation += unstakeAmount;
            poolInfo[pid].poolRewardAllocation += rewardAmount;
        } else {
            // add reward when unstake after lockup period
            unstakeAmount += rewardAmount;
        }

        // update pool stake balance
        poolInfo[pid].poolStakedBalance -= user.amount;
        stakingToken.safeTransfer(address(msg.sender), unstakeAmount);
        user.amount = 0;
        user.lastStakeTime = block.timestamp;
        emit UnStake(pid, msg.sender, unstakeAmount);
    }

    /**
     * @notice Depoist staked tokens
     * @param pid pool index
     * @param amount staking amount
     */
    function stake(
        uint8 pid,
        uint256 amount
    ) public virtual validPID(pid) validStakeAmount(pid, amount) {
        _stake(pid, amount);
    }

    /**
     * @notice withdraw staked tokens and collect reward tokens
     * @param pid pool index
     */
    function unstake(uint8 pid) public virtual validPID(pid) {
        _unstake(pid);
    }

    /**
     * @notice withdraw amount only amdin
     */
    function adminWithdraw(uint256 amount) public virtual onlyOwner {
        stakingToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Update pools freeze time
     * @param freezeTime Freeze time
     */
    function setPoolFreezeTime(uint256 freezeTime) public onlyOwner {
        uint8 index;
        for (index = 0; index < poolInfo.length; ) {
            require(freezeTime < poolInfo[index].poolLockupSeconds, "Wrong LockupSeconds");
            unchecked {
                index++;
            }
        }
        poolFreezeTime = freezeTime;
        emit UpdateFreezeTime(freezeTime);
    }

    /**
     * @notice add pool info
     * @param newPoolData pool info data
     */
    function addPoolInfo(PoolInfo calldata newPoolData) public onlyOwner {
        require(newPoolData.stakeMinAmount < newPoolData.stakeMaxAmount, "Wrong amount range");
        require(poolFreezeTime < newPoolData.poolLockupSeconds, "Wrong LockupSeconds");
        poolInfo.push(newPoolData);
    }

    /**
     * @notice update pool info
     * @param pid pool index to update
     * @param newPoolData pool info data to update
     */
    function setPoolInfo(
        uint8 pid,
        PoolInfo calldata newPoolData
    ) public validPID(pid) onlyOwner {
        require(newPoolData.stakeMinAmount < newPoolData.stakeMaxAmount, "Wrong amount range");
        require(poolFreezeTime < newPoolData.poolLockupSeconds, "Wrong LockupSeconds");
        poolInfo[pid] = newPoolData;
    }

    /**
     * @notice read pool info
     * @param pid pool index to read
     */
    function readPoolInfo(
        uint8 pid
    ) public view validPID(pid) returns (PoolInfo memory) {
        return poolInfo[pid];
    }

    /**
     * @notice return user info
     * @param pid pool index
     * @param user user address
     */
    function getUserInfo(
        uint8 pid,
        address user
    ) public view virtual returns (UserInfo memory) {
        return userInfo[pid][user];
    }

    /**
     * @notice sum of staked amount on pools for user
     * @param user address to get amount
     */
    function getUserTotalBalance(
        address user
    ) public view virtual returns (uint256) {
        uint8 index;
        uint256 totalBalance = 0;
        for (index = 0; index < poolInfo.length; ) {
            UserInfo storage userinfo = userInfo[index][user];
            totalBalance += userinfo.amount;
            unchecked {
                index++;
            }
        }
        return totalBalance;
    }

    function getPoolLength() public view returns (uint256) {
        return poolInfo.length;
    }
}
