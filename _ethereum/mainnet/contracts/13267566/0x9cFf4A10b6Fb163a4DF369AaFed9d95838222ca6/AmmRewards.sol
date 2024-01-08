// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SignedSafeMath.sol";
import "./IRewarder.sol";

contract AmmRewards is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of REWARD_TOKEN entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of REWARD_TOKEN to distribute per block.
    struct PoolInfo {
        uint256 accRewardTokenPerShare;
        uint256 lastRewardTime;
        uint256 allocPoint;
    }

    /// @notice Address of REWARD_TOKEN contract.
    IERC20 public immutable REWARD_TOKEN;

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;

    /// @notice Address of the LP token for each MCV2 pool.
    IERC20[] public lpToken;

    //stores existence of lp tokens to avoid duplicate entries
    mapping (IERC20 => bool) lpTokenExists;

    /// @notice Address of each `IRewarder` contract in MCV2.
    IRewarder[] public rewarder;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public rewardTokenPerSecond;

    uint256 private constant ACC_REWARD_TOKEN_PRECISION = 1e12;

    uint256 private epochRewardAmount;

    address public rewardsManager;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardTime, uint256 lpSupply, uint256 accRewardTokenPerShare);
    event LogRewardTokenPerSecond(uint256 rewardTokenPerSecond);

    constructor(IERC20 rewardToken_) public {
        REWARD_TOKEN = rewardToken_;
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(uint256 allocPoint, IERC20 _lpToken, IRewarder _rewarder) public onlyOwner {
        require(lpTokenExists[_lpToken] == false, "LP token already added");
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        poolInfo.push(PoolInfo({
            allocPoint: allocPoint,
            lastRewardTime: block.timestamp,
            accRewardTokenPerShare: 0
        }));
        lpTokenExists[_lpToken] = true;
        emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's REWARD_TOKEN allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(uint256 _pid, uint256 _allocPoint, IRewarder _rewarder, bool overwrite) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        if (overwrite) { rewarder[_pid] = _rewarder; }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /// @notice Sets the rewardToken per second to be distributed. Can only be called by the owner.
    /// @param rewardTokenPerSecond_ The amount of RewardToken to be distributed per second
    function setRewardTokenPerSecond(uint256 rewardTokenPerSecond_) external onlyOwnerOrRewardsManager {
        rewardTokenPerSecond = rewardTokenPerSecond_;
        emit LogRewardTokenPerSecond(rewardTokenPerSecond);
    }

    /// @notice View function to see pending REWARD_TOKEN on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending REWARD_TOKEN reward for a given user.
    function pendingRewardToken(uint256 _pid, address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 rewardTokenReward = time.mul(rewardTokenPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardTokenPerShare = accRewardTokenPerShare.add(rewardTokenReward.mul(ACC_REWARD_TOKEN_PRECISION).div(lpSupply));
        }
        pending = int256(user.amount.mul(accRewardTokenPerShare).div(ACC_REWARD_TOKEN_PRECISION)).sub(user.rewardDebt).toUInt256();
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
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = lpToken[pid].balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 rewardTokenReward = time.mul(rewardTokenPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
                pool.accRewardTokenPerShare = pool.accRewardTokenPerShare.add((rewardTokenReward.mul(ACC_REWARD_TOKEN_PRECISION).div(lpSupply)));
            }
            pool.lastRewardTime = block.timestamp;
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accRewardTokenPerShare);
        }
    }

    /// @notice Deposit LP tokens to MCV2 for REWARD_TOKEN allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(int256(amount.mul(pool.accRewardTokenPerShare).div(ACC_REWARD_TOKEN_PRECISION)));

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onRewardTokenReward(pid, to, to, 0, user.amount);
        }

        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, to);
    }

    /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt.sub(int256(amount.mul(pool.accRewardTokenPerShare).div(ACC_REWARD_TOKEN_PRECISION)));
        user.amount = user.amount.sub(amount);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onRewardTokenReward(pid, msg.sender, to, 0, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of REWARD_TOKEN rewards.
    function harvest(uint256 pid, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedRewardToken = int256(user.amount.mul(pool.accRewardTokenPerShare).div(ACC_REWARD_TOKEN_PRECISION));
        uint256 _pendingRewardToken = accumulatedRewardToken.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedRewardToken;

        // Interactions
        if (_pendingRewardToken != 0) {
            REWARD_TOKEN.safeTransfer(to, _pendingRewardToken);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onRewardTokenReward( pid, msg.sender, to, _pendingRewardToken, user.amount);
        }

        emit Harvest(msg.sender, pid, _pendingRewardToken);
    }

    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and REWARD_TOKEN rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedRewardToken = int256(user.amount.mul(pool.accRewardTokenPerShare).div(ACC_REWARD_TOKEN_PRECISION));
        uint256 _pendingRewardToken = accumulatedRewardToken.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedRewardToken.sub(int256(amount.mul(pool.accRewardTokenPerShare).div(ACC_REWARD_TOKEN_PRECISION)));
        user.amount = user.amount.sub(amount);

        // Interactions
        REWARD_TOKEN.safeTransfer(to, _pendingRewardToken);

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onRewardTokenReward(pid, msg.sender, to, _pendingRewardToken, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, _pendingRewardToken);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onRewardTokenReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }

    function setRewardsManager(address _rewardsManager) public onlyOwner {
        rewardsManager = _rewardsManager;
    }

    modifier onlyOwnerOrRewardsManager() {
        require(rewardsManager != address(0), "Rewards Manager not set");
        require(owner() == msg.sender || msg.sender == rewardsManager, "Caller is not owner or rewards manager");
        _;
    }
}
