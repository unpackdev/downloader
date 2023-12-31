//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract FlexibleStakingHT is Ownable, ReentrancyGuard {

    struct Pool {
        uint256 launchTimestamp;
        uint256 endTimestamp;
        uint256 lastUpdateTimestamp;
        uint256 poolLifetime;
        uint256 minDeposit;
        uint256 totalStaked;
        uint256 totalRewards;
        uint256 accRewardPerShare;
        bool isOpen;
        bool exists;
    }

    struct User {
        uint256 stakedAmount;
        uint256 rewardDebt;
    }

    IERC20 private rewardToken;

    mapping(uint256 => Pool) private poolMapping; // Pool ID => Pool struct

    mapping(address => mapping(uint256 => User)) private userInPool; // User address => Pool ID => User struct of this individual pool

    Pool[] private poolList;
    
    uint256 private currentPoolId = 0;

    constructor(address tokenAddress) Ownable(msg.sender) {
        rewardToken = IERC20(tokenAddress);
    }

    function stake(uint256 poolId, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(amount >= poolMapping[poolId].minDeposit, "Amount must be greater than or equal to minimum deposit amount");
        require(poolMapping[poolId].exists, "Pool does not exist");
        require(poolMapping[poolId].isOpen, "Pool is not open");
        
        rewardToken.transferFrom(msg.sender, address(this), amount);

        updatePool(poolId);

        Pool memory pool = poolMapping[poolId];
        User memory user = userInPool[msg.sender][poolId];

        if(user.stakedAmount > 0) {
            uint256 pending = user.stakedAmount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
            if(pending > 0) {
                rewardToken.transfer(msg.sender, pending);
                poolMapping[poolId].totalRewards -= pending;
            }
        }

        userInPool[msg.sender][poolId].stakedAmount += amount;
        userInPool[msg.sender][poolId].rewardDebt = userInPool[msg.sender][poolId].stakedAmount * pool.accRewardPerShare / 1e12;
        poolMapping[poolId].totalStaked += amount;

        emit stakeEvent(msg.sender, poolId, amount);
    }

    function withdraw(uint256 poolId, uint256 amount) external nonReentrant {
        require(poolMapping[poolId].exists, "Pool does not exist");
        
        updatePool(poolId);

        Pool memory pool = poolMapping[poolId];
        User memory user = userInPool[msg.sender][poolId];

        require(user.stakedAmount >= amount, "Amount must be less than or equal to staked amount");

        uint256 pending = user.stakedAmount * pool.accRewardPerShare / 1e12 - user.rewardDebt;

        if(pending > 0) {
            rewardToken.transfer(msg.sender, pending);
            poolMapping[poolId].totalRewards -= pending;
        }

        userInPool[msg.sender][poolId].stakedAmount -= amount;

        userInPool[msg.sender][poolId].rewardDebt = userInPool[msg.sender][poolId].stakedAmount * pool.accRewardPerShare / 1e12;

        poolMapping[poolId].totalStaked -= amount;

        rewardToken.transfer(msg.sender, amount);

        emit withdrawEvent(msg.sender, poolId, amount);
    }

    function claim(uint256 poolId) external nonReentrant {
        require(poolMapping[poolId].exists, "Pool does not exist");

        updatePool(poolId);

        Pool memory pool = poolMapping[poolId];
        User memory user = userInPool[msg.sender][poolId];

        uint256 pending = user.stakedAmount * pool.accRewardPerShare / 1e12 - user.rewardDebt;

        userInPool[msg.sender][poolId].rewardDebt = userInPool[msg.sender][poolId].stakedAmount * pool.accRewardPerShare / 1e12;

        if(pending > 0) {
            rewardToken.transfer(msg.sender, pending);
            poolMapping[poolId].totalRewards -= pending;
        }

        emit claimEvent(msg.sender, poolId, pending);
    }

    function getTotalStakedPool(uint256 poolId) external view returns (uint256) {
        return poolMapping[poolId].totalStaked;
    }

    function getPool(uint256 poolId) external view returns (Pool memory) {
        return poolMapping[poolId];
    }

    function getUserInPool(address user, uint256 poolId) external view returns (User memory) {
        return userInPool[user][poolId];
    }

    function getPoolIsOpen(uint256 poolId) external view returns (bool) {
        return poolMapping[poolId].isOpen;
    }

    function getUserStakedAmount(address user, uint256 poolId) external view returns (uint256) {
        return userInPool[user][poolId].stakedAmount;
    }

function getUserPendingRewards(address userAddr, uint256 poolId) external view returns (uint256) {
    Pool memory pool = poolMapping[poolId];
    User memory user = userInPool[userAddr][poolId];
    
    uint256 accRewardPerShare = pool.accRewardPerShare;
    if (block.timestamp > pool.lastUpdateTimestamp && pool.totalStaked != 0) {
        uint256 poolLifeLeft = pool.endTimestamp > block.timestamp ? pool.endTimestamp - block.timestamp : 0;
        uint256 emissionPerSecond = (poolLifeLeft > 0) ? pool.totalRewards / poolLifeLeft : 0;

        uint256 secondsPassed = block.timestamp - pool.lastUpdateTimestamp;
        uint256 reward = secondsPassed * emissionPerSecond;
        accRewardPerShare = accRewardPerShare + (reward * 1e12 / pool.totalStaked);
    }
    
    uint256 pending = user.stakedAmount * accRewardPerShare / 1e12 - user.rewardDebt;
    return pending;
}

    function getPoolList() external view returns (Pool[] memory) {
        return poolList;
    }

    function getCurrentPoolId() external view returns (uint256) {
        return currentPoolId;
    }

    function getPoolTimeLeft(uint256 poolId) external view returns (uint256) {
        Pool memory pool = poolMapping[poolId];
        if(pool.endTimestamp > block.timestamp) {
            return pool.endTimestamp - block.timestamp;
        } else {
            return 0;
        }
    }

    function createPool(uint256 poolLifetime, uint256 minDeposit) external onlyOwner {
        require(poolLifetime > 0, "Pool lifetime must be greater than 0.");
        require(minDeposit > 0, "Minimum deposit must be greater than 0.");

        Pool memory pool = Pool({
            launchTimestamp: 0,
            endTimestamp: 0,
            lastUpdateTimestamp: 0,
            poolLifetime: poolLifetime,
            minDeposit: minDeposit,
            totalStaked: 0,
            totalRewards: 0,
            accRewardPerShare: 0,
            isOpen: false,
            exists: true
        });

        poolMapping[currentPoolId] = pool;
        poolList.push(pool);
        emit addedNewPool(currentPoolId, poolLifetime, minDeposit);
        currentPoolId++;
    }

    function startPool(uint256 poolId, uint256 initialRewards) external onlyOwner {
        require(poolMapping[poolId].exists, "Pool does not exist.");
        require(poolMapping[poolId].totalRewards == 0, "Pool already has rewards.");
        require(!poolMapping[poolId].isOpen, "Pool is already open.");

        rewardToken.transferFrom(msg.sender, address(this), initialRewards);

        poolMapping[poolId].launchTimestamp = block.timestamp;
        poolMapping[poolId].endTimestamp = block.timestamp + poolMapping[poolId].poolLifetime;
        poolMapping[poolId].lastUpdateTimestamp = block.timestamp;
        poolMapping[poolId].totalRewards = initialRewards;
        poolMapping[poolId].isOpen = true;

        emit startedPool(poolId);
    }

    function closePool(uint256 poolId) external onlyOwner {
        require(poolMapping[poolId].exists, "Pool does not exist.");
        require(poolMapping[poolId].isOpen, "Pool is already closed.");

        poolMapping[poolId].isOpen = false;

        emit poolClosed(poolId);
    }

    function openPool(uint256 poolId) external onlyOwner {
        require(poolMapping[poolId].exists, "Pool does not exist.");
        require(!poolMapping[poolId].isOpen, "Pool is already open.");

        poolMapping[poolId].isOpen = true;

        emit poolOpened(poolId);
    }

    function addRewards(uint256 poolId, uint256 amount) external onlyOwner {
        require(poolMapping[poolId].exists, "Pool does not exist.");

        rewardToken.transferFrom(msg.sender, address(this), amount);

        poolMapping[poolId].totalRewards += amount;

        emit addedRewards(poolId, amount);
    }

    function withdrawRewards(uint256 poolId, uint256 amount) external onlyOwner {
        require(poolMapping[poolId].exists, "Pool does not exist.");
        require(poolMapping[poolId].totalRewards >= amount, "Amount must be less than or equal to total rewards.");

        rewardToken.transfer(msg.sender, amount);

        poolMapping[poolId].totalRewards -= amount;

        emit withdrewRewards(poolId, amount);
    }

    function updatePool(uint256 poolId) public {
        Pool memory pool = poolMapping[poolId];

        if(block.timestamp <= pool.lastUpdateTimestamp) {
            return;
        }

        uint256 totalStaked = pool.totalStaked;

        if(totalStaked == 0) {
            poolMapping[poolId].lastUpdateTimestamp = block.timestamp;
            return;
        }

        uint256 poolLifeLeft = pool.endTimestamp - block.timestamp;
        uint256 poolLastUpdate = pool.lastUpdateTimestamp;
        uint256 poolTotalRewards = pool.totalRewards;
        uint256 emissionPerSecond = poolTotalRewards / poolLifeLeft;
        uint256 secondsPassed = block.timestamp - poolLastUpdate;
        uint256 reward = secondsPassed * emissionPerSecond;
poolMapping[poolId].accRewardPerShare += (reward * 1e12) / pool.totalStaked;
        poolMapping[poolId].lastUpdateTimestamp = block.timestamp;
        emit poolUpdated(poolId);
    }

    event addedNewPool(uint256 poolId, uint256 poolLifetime, uint256 minDeposit);
    event startedPool(uint256 poolId);
    event poolOpened(uint256 poolId);
    event poolClosed(uint256 poolId);
    event poolUpdated(uint256 poolId);

    event addedRewards(uint256 poolId, uint256 amount);
    event withdrewRewards(uint256 poolId, uint256 amount);

    event stakeEvent(address user, uint256 poolId, uint256 amount);
    event withdrawEvent(address user, uint256 poolId, uint256 amount);
    event claimEvent(address user, uint256 poolId, uint256 amount);
    
}