// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

interface IVestable {
    function vest(address _receiver, uint256 _amount) external;
}

interface IMigrator {
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    function migrate(IERC20 token) external returns (IERC20);
}

contract LPTokenStaker is Ownable {
    using SafeERC20 for IERC20;

    IVestable public vesting;

    /// @notice Info of each user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of GRO entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// which will determine the share of GRO token rewards the pool will get
    struct PoolInfo {
        uint256 accGroPerShare;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        IERC20 lpToken;
    }

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public maxGroPerBlock;
    uint256 public groPerBlock;

    address public manager;
    mapping(address => bool) public activeLpTokens;

    uint256 private constant ACC_GRO_PRECISION = 1e12;

    /// @notice The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;

    event LogAddPool(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accGroPerShare);
    event LogDeposit(address indexed user, uint256 indexed pid, uint256 amount);
    event LogWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event LogClaim(address indexed user, uint256 indexed pid, uint256 amount);
    event LogLpTokenAdded(address token);
    event LogEmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event LogNewManagment(address newManager);
    event LogMaxGroPerBlock(uint256 newMax);
    event LogGroPerBlock(uint256 newGro);
    event LogNewVester(address newVester);
    event LogNewMigrator(address newMigrator);

    function setVesting(address _vesting) external onlyOwner {
        vesting = IVestable(_vesting);
        emit LogNewVester(_vesting);
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
        emit LogNewManagment(_manager);
    }

    function setMaxGroPerBlock(uint256 _maxGroPerBlock) external onlyOwner {
        maxGroPerBlock = _maxGroPerBlock;
        emit LogMaxGroPerBlock(_maxGroPerBlock);
    }

    function setGroPerBlock(uint256 _groPerBlock) external {
        require(msg.sender == manager, "setGroPerBlock: !manager");
        require(_groPerBlock <= maxGroPerBlock, "setGroPerBlock: > maxGroPerBlock");
        groPerBlock = _groPerBlock;
        emit LogGroPerBlock(_groPerBlock);
    }

    /// @notice Returns the number of pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the manager.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    function add(uint256 allocPoint, IERC20 _lpToken) external {
        require(msg.sender == manager, 'add: !manager');
        totalAllocPoint += allocPoint;

        require(!activeLpTokens[address(_lpToken)], 'add: lpToken already added');
        poolInfo.push(
            PoolInfo({allocPoint: allocPoint, lastRewardBlock: block.number, accGroPerShare: 0, lpToken: _lpToken})
        );
        activeLpTokens[address(_lpToken)] = true;
        emit LogLpTokenAdded(address(_lpToken));
        emit LogAddPool(poolInfo.length - 1, allocPoint, _lpToken);
    }

    /// @notice Update the given pool's allocation point. Can only be called by the manager.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(uint256 _pid, uint256 _allocPoint) external {
        require(msg.sender == manager, "set: !manager");
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;

        emit LogSetPool(_pid, _allocPoint);
    }

    /// @notice Set the `migrator` contract. Can only be called by the owner.
    /// @param _migrator The contract address to set.
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
        emit LogNewMigrator(address(_migrator));
    }

    /// @notice Migrate LP token to another LP contract through the `migrator` contract.
    /// @param _pid The index of the pool. See `poolInfo`.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: !migrator");
        PoolInfo memory pool = poolInfo[_pid];
        uint256 bal = pool.lpToken.balanceOf(address(this));
        pool.lpToken.approve(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(pool.lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: migrated balance must match");
        pool.lpToken = newLpToken;
        poolInfo[_pid] = pool;
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        uint256 _totalAllocPoint = totalAllocPoint;
        require(_totalAllocPoint > 0, 'updatePool: totalAllocPoint == 0');
        pool = poolInfo[pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 blocks = block.number - pool.lastRewardBlock;
                uint256 groReward = (blocks * groPerBlock * pool.allocPoint) / _totalAllocPoint;
                pool.accGroPerShare = pool.accGroPerShare + (groReward * ACC_GRO_PRECISION) / lpSupply;
            }
            pool.lastRewardBlock = block.number;
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accGroPerShare);
        }
    }

    /// @notice View function to see claimable GRO on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return claimable GRO reward for a given user.
    function claimable(uint256 _pid, address _user) external view returns (uint256) {
        uint256 _totalAllocPoint = totalAllocPoint;
        if (_totalAllocPoint == 0) return 0;
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accPerShare = pool.accGroPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 groReward = (blocks * groPerBlock * pool.allocPoint) / _totalAllocPoint;
            accPerShare = accPerShare + (groReward * ACC_GRO_PRECISION) / lpSupply;
        }
        return uint256(int256((user.amount * accPerShare) / ACC_GRO_PRECISION) - user.rewardDebt);
    }

    /// @notice Deposit LP tokens for GRO reward.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    function deposit(uint256 pid, uint256 amount) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo memory user = userInfo[pid][msg.sender];

        // Effects
        user.amount = user.amount + amount;
        user.rewardDebt = user.rewardDebt + int256((amount * pool.accGroPerShare) / ACC_GRO_PRECISION);
        userInfo[pid][msg.sender] = user;

        pool.lpToken.safeTransferFrom(msg.sender, address(this), amount);

        emit LogDeposit(msg.sender, pid, amount);
    }

    /// @notice Withdraw LP tokens.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    function withdraw(uint256 pid, uint256 amount) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo memory user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt - int256((amount * pool.accGroPerShare) / ACC_GRO_PRECISION);
        user.amount = user.amount - amount;
        userInfo[pid][msg.sender] = user;

        pool.lpToken.safeTransfer(msg.sender, amount);

        emit LogWithdraw(msg.sender, pid, amount);
    }

    /// @notice Claim proceeds for transaction sender.
    /// @param pid The index of the pool. See `poolInfo`.
    function claim(uint256 pid) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo memory user = userInfo[pid][msg.sender];

        int256 accumulatedGro = int256((user.amount * pool.accGroPerShare) / ACC_GRO_PRECISION);
        uint256 pending = uint256(accumulatedGro - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedGro;
        userInfo[pid][msg.sender] = user;

        // Interactions
        if (pending > 0) {
            vesting.vest(msg.sender, pending);
        }

        emit LogClaim(msg.sender, pid, pending);
    }

    /// @notice Withdraw LP tokens and claim proceeds for transaction sender.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    function withdrawAndClaim(uint256 pid, uint256 amount) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo memory user = userInfo[pid][msg.sender];
        int256 accumulatedGro = int256((user.amount * pool.accGroPerShare) / ACC_GRO_PRECISION);
        uint256 pending = uint256(accumulatedGro - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedGro - int256((amount * pool.accGroPerShare) / ACC_GRO_PRECISION);
        user.amount = user.amount - amount;
        userInfo[pid][msg.sender] = user;

        // Interactions
        if (pending > 0) {
            vesting.vest(msg.sender, pending);
        }
        pool.lpToken.safeTransfer(msg.sender, amount);

        emit LogWithdraw(msg.sender, pid, amount);
        emit LogClaim(msg.sender, pid, pending);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 pid) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        pool.lpToken.safeTransfer(msg.sender, amount);
        emit LogEmergencyWithdraw(msg.sender, pid, amount);
    }
}
