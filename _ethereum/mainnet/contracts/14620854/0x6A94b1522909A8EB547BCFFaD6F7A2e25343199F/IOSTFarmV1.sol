// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./BoringBatchable.sol";
import "./BoringERC20.sol";
import "./BoringOwnable.sol";
import "./IRewarder.sol";
import "./SafeMath128.sol";
import "./SafeCast.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";

interface IMigrator {
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    function migrate(IERC20 token) external returns (IERC20);
}

contract IOSTFarmV1 is BoringOwnable, BoringBatchable {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeMath128 for uint128;
    using BoringERC20 for IERC20;
    using SignedSafeMath for int256;
    using SafeCast for int256;


    /// @notice Info of each user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of IOST entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of IOST to distribute per block.
    struct PoolInfo {
        uint128 accIOSTPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    /// @notice Address of IOST contract.
    IERC20 public immutable IOST;
    /// @notice The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each pool.
    IERC20[] public lpToken;
    /// @notice Address of each `IRewarder` contract in MCV2.
    IRewarder[] public rewarder;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    /// @dev Tokens added
    mapping (address => bool) public addedTokens;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public iostPerSecond;
    uint256 private constant ACC_IOST_PRECISION = 1e18;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accIOSTPerShare);
    event LogIOSTPerSecond(uint256 iostPerSecond);

    /// @param _IOST The IOST token contract address.
    constructor(IERC20 _IOST) {
        IOST = _IOST;
    }

    /// @notice Returns the number of  pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /**
    * @notice Add a new LP to the pool. Can only be called by the owner.
    * @notice DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    * @param allocPoint AP of the new pool.
    * @param _lpToken Address of the LP ERC-20 token.
    * @param _rewarder Address of the rewarder delegate.
    */
    function add(uint256 allocPoint, IERC20 _lpToken, IRewarder _rewarder) public onlyOwner {
        require(addedTokens[address(_lpToken)] == false, "Token already added");
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        poolInfo.push(PoolInfo({
            allocPoint: allocPoint.toUint64(),
            lastRewardTime: block.timestamp.toUint64(),
            accIOSTPerShare: 0
        }));
        addedTokens[address(_lpToken)] = true;
        emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken, _rewarder);
    }

    /**
    * @notice Update the given pool's IOST allocation point and `IRewarder` contract. Can only be called by the owner.
    * @param _pid The index of the pool. See `poolInfo`.
    * @param _allocPoint New AP of the pool.
    * @param _rewarder Address of the rewarder delegate.
    * @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    */
    function set(uint256 _pid, uint256 _allocPoint, IRewarder _rewarder, bool overwrite) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint.toUint64();
        if (overwrite) { rewarder[_pid] = _rewarder; }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /**
    * @notice Sets the IOST per second to be distributed. Can only be called by the owner.
    * @param _iostPerSecond The amount of IOST to be distributed per second.
    */
    function setIOSTPerSecond(uint256 _iostPerSecond) public onlyOwner {
        iostPerSecond = _iostPerSecond;
        emit LogIOSTPerSecond(_iostPerSecond);
    }

    /**
    * @notice Set the `migrator` contract. Can only be called by the owner.
    * @param _migrator The contract address to set.
    */
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    /**
    * @notice @notice Migrate LP token to another LP contract through the `migrator` contract.
    * @param _pid The index of the pool. See `poolInfo`.
    */
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "IOSTFarmV1: no migrator set");
        IERC20 _lpToken = lpToken[_pid];
        uint256 bal = _lpToken.balanceOf(address(this));
        _lpToken.approve(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(_lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "IOSTFarmV1: migrated balance must match");
        require(addedTokens[address(newLpToken)] == false, "Token already added");
        addedTokens[address(newLpToken)] = true;
        addedTokens[address(_lpToken)] = false;
        lpToken[_pid] = newLpToken;
    }

    /**
    * @notice View function to see pending IOST on frontend.
    * @param _pid The index of the pool. See `poolInfo`.
    * @param _user Address of user.
    * @return pending IOST reward for a given user.
    */
    function pendingIOST(uint256 _pid, address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accIOSTPerShare = pool.accIOSTPerShare;
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 IOSTReward = time.mul(iostPerSecond).mul(pool.allocPoint) / totalAllocPoint;
            accIOSTPerShare = accIOSTPerShare.add(IOSTReward.mul(ACC_IOST_PRECISION) / lpSupply);
        }
        pending = (user.amount.mul(accIOSTPerShare) / ACC_IOST_PRECISION).toInt256().sub(user.rewardDebt).toUint256();
    }

    /**
    * @notice Update reward variables for all pools. Be careful of gas spending!
    * @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    */
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /**
    * @notice Update reward variables of the given pool.
    * @param pid The index of the pool. See `poolInfo`.
    * @param pool Returns the pool that was updated.
    */
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = lpToken[pid].balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 IOSTReward = time.mul(iostPerSecond).mul(pool.allocPoint) / totalAllocPoint;
                pool.accIOSTPerShare = pool.accIOSTPerShare.add((IOSTReward.mul(ACC_IOST_PRECISION) / lpSupply).toUint128());
            }
            pool.lastRewardTime = block.timestamp.toUint64();
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accIOSTPerShare);
        }
    }

    /**
    * @notice Deposit LP tokens to  for IOST allocation.
    * @param pid The index of the pool. See `poolInfo`.
    * @param amount LP token amount to deposit.
    * @param to The receiver of `amount` deposit benefit.
    */
    function deposit(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add((amount.mul(pool.accIOSTPerShare) / ACC_IOST_PRECISION).toInt256());

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIOSTReward(pid, to, to, 0, user.amount);
        }

        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, to);
    }

    /**
    * @notice Withdraw LP tokens from .
    * @param pid The index of the pool. See `poolInfo`.
    * @param amount LP token amount to withdraw.
    * @param to Receiver of the LP tokens.
    */
    function withdraw(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt.sub((amount.mul(pool.accIOSTPerShare) / ACC_IOST_PRECISION).toInt256());
        user.amount = user.amount.sub(amount);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIOSTReward(pid, msg.sender, to, 0, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /**
    * @notice Harvest proceeds for transaction sender to `to`.
    * @param pid The index of the pool. See `poolInfo`.
    * @param to Receiver of IOST rewards.
    */
    function harvest(uint256 pid, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedIOST = int256(user.amount.mul(pool.accIOSTPerShare) / ACC_IOST_PRECISION);
        uint256 _pendingIOST = accumulatedIOST.sub(user.rewardDebt).toUint256();

        // Effects
        user.rewardDebt = accumulatedIOST;

        // Interactions
        if (_pendingIOST != 0) {
            IOST.safeTransfer(to, _pendingIOST);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIOSTReward( pid, msg.sender, to, _pendingIOST, user.amount);
        }

        emit Harvest(msg.sender, pid, _pendingIOST);
    }

    /**
    * @notice Withdraw LP tokens from and harvest proceeds for transaction sender to `to`.
    * @param pid The index of the pool. See `poolInfo`.
    * @param amount LP token amount to withdraw.
    * @param to Receiver of the LP tokens and IOST rewards.
    */
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedIOST = int256(user.amount.mul(pool.accIOSTPerShare) / ACC_IOST_PRECISION);
        uint256 _pendingIOST = accumulatedIOST.sub(user.rewardDebt).toUint256();

        // Effects
        user.rewardDebt = accumulatedIOST.sub(int256(amount.mul(pool.accIOSTPerShare) / ACC_IOST_PRECISION));
        user.amount = user.amount.sub(amount);

        // Interactions
        IOST.safeTransfer(to, _pendingIOST);

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIOSTReward(pid, msg.sender, to, _pendingIOST, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, _pendingIOST);
    }

    /**
    * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    * @param pid The index of the pool. See `poolInfo`.
    * @param to Receiver of the LP tokens.
    */
    function emergencyWithdraw(uint256 pid, address to) public {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIOSTReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
}