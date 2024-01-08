// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ILiquidityMining.sol";
import "./IMigrator.sol";

contract LiquidityMining is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user per pool.
    struct UserPoolInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 accruedReward; // Reward accrued.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 accRewardPerShare; // Accumulated reward token per share, times 1e12. See below.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardBlock; // Last block number that reward token distribution occurs.
    }

    struct UnlockInfo {
        uint256 block;
        uint256 quota;
    }

    // The reward token token
    IERC20 public rewardToken;
    // Reservoir address.
    address public reservoir;
    // rewardToken tokens created per block.
    uint256 public rewardPerBlock;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;

    // Blocks and quotas of rewards unlocks
    UnlockInfo[] public unlocks;
    uint256 public unlocksTotalQuotation;
    // Accumulated rewards
    mapping(address => uint256) public rewards;
    // Claimed rewards
    mapping(address => uint256) public claimedRewards;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Pid of each pool by its address
    mapping(address => uint256) public poolPidByAddress;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserPoolInfo)) public userPoolInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when rewardToken mining starts.
    uint256 public startBlock;
    // The block number when rewardToken mining end.
    uint256 public endBlock;

    event TokenAdded(
        address indexed token,
        uint256 indexed pid,
        uint256 allocPoint
    );
    event Claimed(address indexed user, uint256 amount);
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdrawn(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event TokenMigrated(
        address indexed oldtoken,
        address indexed newToken,
        uint256 indexed pid
    );
    event RewardPerBlockSet(uint256 rewardPerBlock);
    event TokenSet(
        address indexed token,
        uint256 indexed pid,
        uint256 allocPoint
    );
    event MigratorSet(address indexed migrator);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _rewardToken,
        address _reservoir,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) {
        rewardToken = _rewardToken;
        reservoir = _reservoir;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;

        emit RewardPerBlockSet(_rewardPerBlock);
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate
    ) external onlyOwner {
        require(!isTokenAdded(_token), "add: token already added");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        uint256 pid = poolInfo.length;
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0
            })
        );
        poolPidByAddress[address(_token)] = pid;

        emit TokenAdded(address(_token), pid, _allocPoint);
    }

    function accrueReward(uint256 _pid) internal {
        UserPoolInfo memory userPool = userPoolInfo[_pid][msg.sender];
        if (userPool.amount == 0) {
            return;
        }
        rewards[msg.sender] = rewards[msg.sender].add(
            calcReward(poolInfo[_pid], userPool).sub(userPool.accruedReward)
        );
    }

    function calcReward(PoolInfo memory pool, UserPoolInfo memory userPool) internal returns(uint256){
        return userPool.amount.mul(pool.accRewardPerShare).div(1e12);
    }

    function getPendingReward(uint256 _pid, address _user)
        external view
        returns(uint256 total, uint256 unlocked) {

        PoolInfo memory pool = poolInfo[_pid];

        uint256 currentBlock = block.number;
        if (currentBlock < startBlock) {
            return (0, 0);
        }
        if (currentBlock > endBlock) {
            currentBlock = endBlock;
        }

        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (lpSupply == 0) {
            return (0, 0);
        }
        uint256 blockLasted = currentBlock.sub(pool.lastRewardBlock);
        uint256 reward = blockLasted.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(1e12).div(lpSupply)
        );

        UserPoolInfo memory userPool = userPoolInfo[_pid][_user];
        total = userPool.amount
            .mul(accRewardPerShare)
            .div(1e12)
            .sub(userPool.accruedReward);

        unlocked = calcUnlocked(total);
    }

    function calcUnlocked(uint256 reward) public view returns(uint256 claimable) {
        uint256 i;
        for (i = 0; i < unlocks.length; ++i) {
            if (block.number < unlocks[i].block) {
                continue;
            }
            claimable = claimable.add(
                reward.mul(unlocks[i].quota)
                .div(unlocksTotalQuotation)
            );
        }
    }

    // claim rewards
    function claim() external{
        uint256 i;
        for (i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
            accrueReward(i);
            UserPoolInfo storage userPool = userPoolInfo[i][msg.sender];
            userPool.accruedReward = calcReward(poolInfo[i], userPool);
        }
        uint256 unlocked = calcUnlocked(rewards[msg.sender]).sub(claimedRewards[msg.sender]);
        if (unlocked > 0) {
            _safeRewardTransfer(msg.sender, unlocked);
        }
        claimedRewards[msg.sender] = claimedRewards[msg.sender].add(unlocked);
        emit Claimed(msg.sender, unlocked);
    }

    // Deposit tokens to liquidity mining for reward token allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        require(block.number <= endBlock, "LP mining has ended.");
        updatePool(_pid);
        accrueReward(_pid);

        UserPoolInfo storage userPool = userPoolInfo[_pid][msg.sender];

        if (_amount > 0) {
            poolInfo[_pid].token.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );

            userPool.amount = userPool.amount.add(_amount);
        }

        userPool.accruedReward = calcReward(poolInfo[_pid], userPoolInfo[_pid][msg.sender]);
        emit Deposited(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function withdrawEmergency(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserPoolInfo storage userPool = userPoolInfo[_pid][msg.sender];
        pool.token.safeTransfer(address(msg.sender), userPool.amount);
        emit EmergencyWithdrawn(msg.sender, _pid, userPool.amount);
        userPool.amount = 0;
        userPool.accruedReward = 0;
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    function reallocatePool(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;

        emit TokenSet(address(poolInfo[_pid].token), _pid, _allocPoint);
    }

    // Set reward per block. Can only be called by the owner.
    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;

        emit RewardPerBlockSet(_rewardPerBlock);
    }

    // Set unlocks infos - block number and quota.
    function setUnlocks(uint256[] calldata _blocks, uint256[] calldata _quotas) external onlyOwner {
        require(_blocks.length == _quotas.length, "Should be same length");
        for (uint256 i = 0; i < _blocks.length; ++i) {
            unlocks.push(UnlockInfo(_blocks[i], _quotas[i]));
            unlocksTotalQuotation = unlocksTotalQuotation.add(_quotas[i]);
        }
    }

    // Withdraw tokens from rewardToken liquidity mining.
    function withdraw(uint256 _pid, uint256 _amount) external {
        require(userPoolInfo[_pid][msg.sender].amount >= _amount, "withdraw: not enough amount");
        updatePool(_pid);
        accrueReward(_pid);
        UserPoolInfo storage userPool = userPoolInfo[_pid][msg.sender];
        if (_amount > 0) {
            userPool.amount = userPool.amount.sub(_amount);
            poolInfo[_pid].token.safeTransfer(address(msg.sender), _amount);
        }

        userPool.accruedReward = calcReward(poolInfo[_pid], userPoolInfo[_pid][msg.sender]);
        emit Withdrawn(msg.sender, _pid, _amount);
    }

    // Number of pools.
    function poolCount() external view returns (uint256) {
        return poolInfo.length;
    }

    function unlockCount() external view returns (uint256) {
        return unlocks.length;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 currentBlock = block.number;
        if (currentBlock > endBlock) {
            currentBlock = endBlock;
        }
        if (currentBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = currentBlock;
            return;
        }

        uint256 blockLasted = currentBlock.sub(pool.lastRewardBlock);
        uint256 reward =
            blockLasted.mul(rewardPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        rewardToken.transferFrom(reservoir, address(this), reward);
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = currentBlock;
    }

    // Return bool - is token added or not
    function isTokenAdded(IERC20 _token) public view returns (bool) {
        uint256 pid = poolPidByAddress[address(_token)];
        return
            poolInfo.length > pid &&
            address(poolInfo[pid].token) == address(_token);
    }

    // Safe rewardToken transfer function.
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (_amount > balance) {
            rewardToken.transfer(_to, balance);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigrator _migrator) external onlyOwner {
        migrator = _migrator;
        emit MigratorSet(address(_migrator));
    }

    // Migrate token to another lp contract. Can be called by anyone.
    function migrate(uint256 _pid) external {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 token = pool.token;
        uint256 bal = token.balanceOf(address(this));
        token.safeApprove(address(migrator), bal);
        IERC20 newToken = migrator.migrate(token);
        require(bal == newToken.balanceOf(address(this)), "migrate: bad");
        pool.token = newToken;

        delete poolPidByAddress[address(token)];
        poolPidByAddress[address(newToken)] = _pid;

        emit TokenMigrated(address(token), address(newToken), _pid);
    }

    function getAllPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    function getAllUnlocks() external view returns (UnlockInfo[] memory) {
        return unlocks;
    }
}
