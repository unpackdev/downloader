// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

import "./console.sol";

contract CmsnStaking is Ownable {
    using SafeERC20 for IERC20;

    struct PoolType {
        uint256 poolSize; // Pool size in CMSN
        uint256 minAmount; // Minimum number of tokens required to participate in staking
        uint256 maxAmount; // Maximum number of tokens can be deposited to the pool in percentage
        uint256 period; // Pool staking period
        uint256 timeAccepting; // time duration allowed for deposit to the pool
        uint256 penalty;
    }

    struct Pool {
        uint256 poolTypeId; // PoolType index in poolTypes mapping
        uint256 startedAt; // Pool start time in unix timestamp
        uint256 endsAt; // Pool end time in unix timestamp
        uint256 stakedAmount; // Total staked amount in the pool
        address rewardToken; // Reward token address
        uint256 rewardAmount; // Reward token amount
    }

    uint256 public constant MIN_POOL_SIZE = 1000_000; // 1000,000 CMSN as minimum pool size
    uint256 public constant MIN_PERIOD = 3 days;
    uint256 public constant MIN_TIME_ACCEPTING = 1 days;

    mapping(uint256 => PoolType) private poolTypes; // poolTypeId => PoolType (PoolType array as mapping)
    mapping(uint256 => Pool) private pools; // poolId => Pool (Only one Pool is open for each type)
    mapping(address => mapping(uint256 => uint256)) private activeStakingAmount; // wallet => poolId => stakedAmount
    mapping(address => mapping(uint256 => bool)) private withdrawStatus; // wallet => poolId => withdrawn?

    uint256 public poolTypeCount;
    uint256 public poolCount;

    IERC20 public immutable cmsn;

    address private marketing;

    event PoolTypeAdded(bytes _poolType);
    event PoolCreated(
        uint256 indexed _poolTypeId,
        uint256 _startedAt,
        uint256 _endsAt
    );
    event PoolStarted(uint256 indexed _poolId, uint256 _timestamp);
    event RewardAdded(uint256 indexed _poolId, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _rewardAmount);

    modifier poolExists(uint256 _poolId) {
        require(_poolId < poolCount, "invalid pool");
        _;
    }

    receive() external payable {}

    constructor(address _marketing) {
        // CMSN token address
        cmsn = IERC20(0xaeB813653bb20d5Fa4798dc4fc63Af9cad4f3f67);
        marketing = _marketing;
    }

    function deposit(uint256 _poolId, uint256 _amount)
        external
        poolExists(_poolId)
    {
        require(
            withdrawStatus[msg.sender][_poolId] == false,
            "already withdrawn before"
        );

        Pool memory pool = pools[_poolId];
        require(block.timestamp <= pool.endsAt, "pool ended");

        PoolType memory poolType = poolTypes[pool.poolTypeId];
        require(
            block.timestamp <= pool.startedAt + poolType.timeAccepting,
            "pool does not accept deposits"
        );
        require(
            _amount >= poolType.minAmount && _amount <= poolType.maxAmount,
            "deposit amount invalid"
        );
        require(
            pool.stakedAmount + _amount <= poolType.poolSize,
            "pool size overflow"
        );

        cmsn.safeTransferFrom(msg.sender, address(this), _amount);
        activeStakingAmount[msg.sender][_poolId] += _amount;
        pool.stakedAmount += _amount;
        pools[_poolId] = pool;
    }

    function addReward(uint256 _poolId, uint256 _amount)
        external
        onlyOwner
        poolExists(_poolId)
    {
        require(_amount > 0, "invalid reward amount");

        Pool memory pool = pools[_poolId];
        require(block.timestamp < pool.endsAt, "pool ended");

        IERC20(pool.rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        pool.rewardAmount += _amount;
        pools[_poolId] = pool;

        emit RewardAdded(_poolId, _amount);
    }

    function withdraw(uint256 _poolId) external poolExists(_poolId) {
        Pool memory pool = pools[_poolId];

        if (block.timestamp >= pool.endsAt) {
            uint256 amount = activeStakingAmount[msg.sender][_poolId];

            activeStakingAmount[msg.sender][_poolId] = 0;
            cmsn.safeTransfer(msg.sender, amount);

            uint256 rewardAmount = (pool.rewardAmount * amount) /
                pool.stakedAmount;

            IERC20(pool.rewardToken).safeTransfer(msg.sender, rewardAmount);

            emit Withdraw(msg.sender, rewardAmount);
        } else {
            PoolType memory poolType = poolTypes[pool.poolTypeId];
            uint256 amount = activeStakingAmount[msg.sender][_poolId];

            pool.stakedAmount -= amount;

            uint256 amountForTax = (amount * poolType.penalty) / 100;
            uint256 amountToSend = amount - amountForTax;

            activeStakingAmount[msg.sender][_poolId] = 0;

            // apply penalty for early withdraw
            cmsn.safeTransfer(msg.sender, amountToSend);
            cmsn.safeTransfer(marketing, amountForTax);

            emit Withdraw(msg.sender, 0);
        }
        withdrawStatus[msg.sender][_poolId] = true;
    }

    function setMarketingWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "invalid address");

        marketing = _wallet;
    }

    function getPoolType(uint256 _poolTypeId)
        public
        view
        returns (PoolType memory)
    {
        return poolTypes[_poolTypeId];
    }

    function getPool(uint256 _poolId)
        public
        view
        poolExists(_poolId)
        returns (Pool memory)
    {
        return pools[_poolId];
    }

    function isPoolActive(uint256 _poolId)
        public
        view
        poolExists(_poolId)
        returns (bool)
    {
        return
            block.timestamp <= pools[_poolId].endsAt &&
            block.timestamp >= pools[_poolId].startedAt;
    }

    function canWithdraw(address _user, uint256 _poolId)
        public
        view
        poolExists(_poolId)
        returns (bool)
    {
        return withdrawStatus[_user][_poolId];
    }

    function getStakeAmount(address _user, uint256 _poolId)
        public
        view
        poolExists(_poolId)
        returns (uint256)
    {
        return activeStakingAmount[_user][_poolId];
    }

    function addPoolType(bytes calldata _poolType) public onlyOwner {
        PoolType memory poolType = abi.decode(_poolType, (PoolType));

        require(poolType.poolSize >= MIN_POOL_SIZE, "pool size too small");
        require(
            poolType.maxAmount <= poolType.poolSize,
            "maximum amount exceeds pool size"
        );
        require(poolType.period >= MIN_PERIOD, "invalid period");
        require(
            poolType.timeAccepting >= MIN_TIME_ACCEPTING &&
                poolType.timeAccepting < poolType.period,
            "invalid time accepting"
        );
        require(poolType.penalty > 0, "invalid penalty");

        poolTypes[poolTypeCount] = poolType;
        poolTypeCount++;

        emit PoolTypeAdded(_poolType);
    }

    function createPool(
        uint256 _poolTypeId,
        address _rewardToken,
        uint256 _rewardAmount
    ) public onlyOwner {
        require(_poolTypeId < poolTypeCount, "invalid pool type");
        require(_rewardToken != address(0), "invalid reward token");

        pools[poolCount] = Pool({
            poolTypeId: _poolTypeId,
            startedAt: 0,
            endsAt: 0,
            stakedAmount: 0,
            rewardToken: _rewardToken,
            rewardAmount: _rewardAmount
        });

        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _rewardAmount
        );

        poolCount++;

        emit PoolCreated(_poolTypeId, 0, 0);
        emit RewardAdded(poolCount - 1, _rewardAmount);
    }

    function startPool(uint256 _poolId) external onlyOwner poolExists(_poolId) {
        Pool memory pool = pools[_poolId];
        require(pool.startedAt == 0, "pool already started");

        pool.startedAt = block.timestamp;
        pool.endsAt = block.timestamp + poolTypes[pool.poolTypeId].period;
        pools[_poolId] = pool;

        emit PoolStarted(_poolId, block.timestamp);
    }

    function withdraw(address _address) external onlyOwner {
        require(_address != address(0), "invalid address");
        uint256 amount = address(this).balance;

        (bool success, ) = payable(_address).call{value: amount}("");
        require(success, "failed to send eth");
    }
}
