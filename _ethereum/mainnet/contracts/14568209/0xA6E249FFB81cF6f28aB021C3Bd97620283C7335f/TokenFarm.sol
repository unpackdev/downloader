// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./BoringERC20.sol";

contract TokenFarm is Ownable, ReentrancyGuard {
    using BoringERC20 for IBoringERC20;
    using SafeMath for uint256;

    // Info of each user for each farm.
    struct UserInfo {
        uint256 amount; // How many Staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each reward distribution pool.
    struct PoolInfo {
        IBoringERC20 stakingToken; // Address of Staking token contract.
        IBoringERC20 rewardToken; // Address of Reward token contract
        uint256 precision; //reward token precision
        uint256 startTimestamp; // start timestamp of the pool
        uint256 lastRewardTimestamp; // Last timestamp that Reward Token distribution occurs.
        uint256 accRewardPerShare; // Accumulated Reward Token per share. See below.
        uint256 totalStaked; // total staked amount each pool's stake token, typically, each pool has the same stake token, so need to track it separatedly
        uint256 totalRewards;
    }

    // Reward info
    struct RewardInfo {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 rewardPerSec;
    }

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    // @dev this is mostly used for extending reward period
    // @notice Reward info is a set of {endTimestamp, rewardPerTimestamp}
    // indexed by pool ID
    mapping(uint256 => RewardInfo[]) public poolRewardInfo;

    // Info of each user that stakes Staking tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // @notice limit length of reward info
    // how many phases are allowed
    uint256 public rewardInfoLimit;

    event Deposit(address indexed user, uint256 amount, uint256 pool, uint256 accRewardPerShare, uint256 rewardDebit);
    event Withdraw(address indexed user, uint256 amount, uint256 pool, uint256 accRewardPerShare, uint256 rewardDebit);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount,
        uint256 pool
    );
    event AddPoolInfo(
        uint256 indexed poolID,
        IBoringERC20 stakingToken,
        IBoringERC20 rewardToken,
        uint256 startTimestamp,
        uint256 precision
    );

    event AddRewardInfo(
        uint256 indexed poolID,
        uint256 indexed phase,
        uint256 endTimestamp,
        uint256 rewardPerTimestamp
    );
    event UpdatePoolInfo(uint256 indexed poolID, uint256 indexed lastRewardTimestamp);
    event SetRewardInfoLimit(uint256 rewardInfoLimit);

    // constructor
    constructor() {
        rewardInfoLimit = 53;
    }

    // @notice set new reward info limit
    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit)
    external
    onlyOwner
    {
        rewardInfoLimit = _updatedRewardInfoLimit;
        emit SetRewardInfoLimit(rewardInfoLimit);
    }

    // @notice reward pool, one pool represents a pair of staking and reward token, last reward Timestamp and acc reward Per Share
    function addPoolInfo(
        IBoringERC20 _stakingToken,
        IBoringERC20 _rewardToken
    ) external onlyOwner {
        uint256 decimalsRewardToken = uint256(_rewardToken.safeDecimals());

        require(
            decimalsRewardToken < 30,
            "constructor: reward token decimals must be inferior to 30"
        );

        uint256 precision = uint256(10**(uint256(30) - (decimalsRewardToken)));

        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                rewardToken: _rewardToken,
                precision: precision,
                startTimestamp: block.timestamp,
                lastRewardTimestamp: block.timestamp,
                accRewardPerShare: 0,
                totalStaked: 0,
                totalRewards: 0
            })
        );
        emit AddPoolInfo(
            poolInfo.length - 1,
            _stakingToken,
            _rewardToken,
            block.timestamp,
            precision
        );
    }

    // @notice if the new reward info is added, the reward & its end timestamp will be extended by the newly pushed reward info.
    function addRewardInfo(
        uint256 _pid,
        uint256 _endTimestamp,
        uint256 _rewardPerSec
    ) external onlyOwner {
        RewardInfo[] storage rewardInfo = poolRewardInfo[_pid];
        PoolInfo storage pool = poolInfo[_pid];
        require(
            rewardInfo.length < rewardInfoLimit,
            "addRewardInfo::reward info length exceeds the limit"
        );
        require(
            rewardInfo.length == 0 ||
            rewardInfo[rewardInfo.length - 1].endTimestamp >=
            block.timestamp,
            "addRewardInfo::reward period ended"
        );
        require(
            rewardInfo.length == 0 ||
            rewardInfo[rewardInfo.length - 1].endTimestamp < _endTimestamp,
            "addRewardInfo::bad new endTimestamp"
        );
        uint256 startTimestamp = rewardInfo.length == 0
        ? pool.startTimestamp
        : rewardInfo[rewardInfo.length - 1].endTimestamp;

        uint256 timeRange = _endTimestamp.sub(startTimestamp);

        uint256 totalRewards = timeRange.mul(_rewardPerSec);
        pool.rewardToken.safeTransferFrom(
            msg.sender,
            address(this),
            totalRewards
        );
        pool.totalRewards = pool.totalRewards.add(totalRewards);

        rewardInfo.push(
            RewardInfo({
                startTimestamp: startTimestamp,
                endTimestamp: _endTimestamp,
                rewardPerSec: _rewardPerSec
            })
        );

        emit AddRewardInfo(
            _pid,
            rewardInfo.length - 1,
            _endTimestamp,
            _rewardPerSec
        );
    }

    function rewardInfoLen(uint256 _pid)
    external
    view
    returns (uint256)
    {
        return poolRewardInfo[_pid].length;
    }

    function poolInfoLen() external view returns (uint256) {
        return poolInfo.length;
    }

    // @notice this will return  end block based on the current block timestamp.
    function currentEndTimestamp(uint256 _pid)
    external
    view
    returns (uint256)
    {
        return _endTimestampOf(_pid, block.timestamp);
    }

    function _endTimestampOf(uint256 _pid, uint256 _timestamp)
    internal
    view
    returns (uint256)
    {
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_timestamp <= rewardInfo[i].endTimestamp)
                return rewardInfo[i].endTimestamp;
        }

        // @dev when couldn't find any reward info, it means that _blockTimestamp exceed endTimestamp
        // so return the latest reward info.
        return rewardInfo[len - 1].endTimestamp;
    }

    // @notice this will return reward per block based on the current block timestamp.
    function currentRewardPerSec(uint256 _pid)
    external
    view
    returns (uint256)
    {
        return _rewardPerSecOf(_pid, block.timestamp);
    }

    function _rewardPerSecOf(uint256 _pid, uint256 _blockTimestamp)
    internal
    view
    returns (uint256)
    {
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockTimestamp <= rewardInfo[i].endTimestamp)
                return rewardInfo[i].rewardPerSec;
        }
        // @dev when couldn't find any reward info, it means that timestamp exceed endtimestamp
        // so return 0
        return 0;
    }

    // @notice Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(
        uint256 _from,
        uint256 _to,
        uint256 _endTimestamp
    ) public pure returns (uint256) {
        if ((_from >= _endTimestamp) || (_from > _to)) {
            return 0;
        }
        if (_to <= _endTimestamp) {
            return _to - _from;
        }
        return _endTimestamp - _from;
    }

    // @notice View function to see pending Reward on frontend.
    function pendingReward(uint256 _pid, address _user)
    external
    view
    returns (uint256)
    {
        return
        _pendingReward(
            _pid,
            userInfo[_pid][_user].amount,
            userInfo[_pid][_user].rewardDebt
        );
    }


    function _pendingReward(
        uint256 _pid,
        uint256 _amount,
        uint256 _rewardDebt
    ) internal view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (
            block.timestamp > pool.lastRewardTimestamp &&
            pool.totalStaked != 0
        ) {
            uint256 cursor = pool.lastRewardTimestamp;
            for (uint256 i = 0; i < rewardInfo.length; ++i) {
                uint256 multiplier = getMultiplier(
                    cursor,
                    block.timestamp,
                    rewardInfo[i].endTimestamp
                );
                if (multiplier == 0) continue;
                cursor = rewardInfo[i].endTimestamp;
                uint256 tokenReward = multiplier.mul(rewardInfo[i].rewardPerSec);
                accRewardPerShare = accRewardPerShare.add(tokenReward.mul(pool.precision).div(pool.totalStaked));
            }
        }

        return uint256(_amount.mul(accRewardPerShare).div(pool.precision)).sub(_rewardDebt);
    }

    function updatePool(uint256 _pid) external nonReentrant {
        _updatePool(_pid);
    }

    // @notice Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        RewardInfo[] memory rewardInfo = poolRewardInfo[_pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        if (pool.totalStaked == 0) {
            // if there is no total supply, return and use the pool's start block timestamp as the last reward block timestamp
            // so that ALL reward will be distributed.
            // however, if the first deposit is out of reward period, last reward block will be its block timestamp
            // in order to keep the multiplier = 0
            if (
                block.timestamp > _endTimestampOf(_pid, block.timestamp)
            ) {
                pool.lastRewardTimestamp = block.timestamp;
            }
            return;
        }
        // @dev for each reward info
        for (uint256 i = 0; i < rewardInfo.length; ++i) {
            // @dev get multiplier based on current Block and rewardInfo's end block
            // multiplier will be a range of either (current block - pool.lastRewardBlock)
            // or (reward info's endblock - pool.lastRewardTimestamp) or 0
            uint256 multiplier = getMultiplier(
                pool.lastRewardTimestamp,
                block.timestamp,
                rewardInfo[i].endTimestamp
            );
            if (multiplier == 0) continue;
            // @dev if currentTimestamp exceed end block, use end block as the last reward block
            // so that for the next iteration, previous endTimestamp will be used as the last reward block
            if (block.timestamp > rewardInfo[i].endTimestamp) {
                pool.lastRewardTimestamp = rewardInfo[i].endTimestamp;
            } else {
                pool.lastRewardTimestamp = block.timestamp;
            }
            uint256 tokenReward = multiplier.mul(rewardInfo[i].rewardPerSec);
            pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(pool.precision).div(pool.totalStaked));
        }
        emit UpdatePoolInfo(_pid, pool.lastRewardTimestamp);
    }

    // @notice Update reward variables for all pools. gas spending is HIGH in this method call, BE CAREFUL
    function massUpdateCampaigns() external nonReentrant {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    // @notice Stake Staking tokens to TokenFarm
    function deposit(uint256 _pid, uint256 _amount)
    external
    nonReentrant
    {
        _deposit(_pid, _amount);
    }

    // @notice Stake Staking tokens to TokenFarm
    function _deposit(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = uint256(user.amount.mul(pool.accRewardPerShare).div(pool.precision)).sub(user.rewardDebt);
            if (pending > 0) {
                pool.rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            pool.stakingToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            pool.totalStaked = pool.totalStaked.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(pool.precision);
        emit Deposit(msg.sender, _amount, _pid, pool.accRewardPerShare, user.rewardDebt);
    }

    // @notice Withdraw Staking tokens from STAKING.
    function withdraw(uint256 _pid, uint256 _amount)
    external
    nonReentrant
    {
        _withdraw(_pid, _amount);
    }

    // @notice internal method for withdraw (withdraw and harvest method depend on this method)
    function _withdraw(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw::bad withdraw amount");
        _updatePool(_pid);
        uint256 pending = uint256(user.amount.mul(pool.accRewardPerShare).div(pool.precision)).sub(user.rewardDebt);
        if (pending > 0) {
            pool.rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakingToken.safeTransfer(address(msg.sender), _amount);
            pool.totalStaked = pool.totalStaked.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(pool.precision);

        emit Withdraw(msg.sender, _amount, _pid, pool.accRewardPerShare, user.rewardDebt);
    }

    // @notice method for harvest pools (used when the user want to claim their reward token based on specified pools)
    function harvest(uint256 _pid) external nonReentrant {
        _withdraw(_pid, 0);
    }

    // @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        pool.totalStaked = pool.totalStaked.sub(_amount);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.stakingToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount, _pid);
    }

    function rescueFunds(uint256 _pid, address _beneficiary) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 amount = pool.rewardToken.balanceOf(address(this));
        pool.rewardToken.safeTransfer(_beneficiary, amount);
    }
}