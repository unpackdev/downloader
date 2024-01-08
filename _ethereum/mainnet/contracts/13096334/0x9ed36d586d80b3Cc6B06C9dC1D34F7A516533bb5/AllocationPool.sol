//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract AllocationPool is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeCastUpgradeable for uint256;

    uint64 private constant ACCUMULATED_MULTIPLIER = 1e12;

    uint64 public constant ALLOC_MAXIMUM_DELAY_DURATION = 35 days; // maximum 35 days delay

    // Info of each user.
    struct AllocUserInfo {
        uint128 amount; // How many LP tokens the user has provided.
        uint128 rewardDebt; // Reward debt. See explanation below.
        uint128 pendingReward; // Reward but not harvest
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct AllocPoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint128 lpSupply; // Total lp tokens deposited to this pool.
        uint64 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint64 lastRewardBlock; // Last block number that rewards distribution occurs.
        uint128 accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
        uint128 delayDuration; // The duration user need to wait when withdraw.
    }

    struct AllocPendingWithdrawal {
        uint128 amount;
        uint128 applicableAt;
    }

    // The reward token!
    IERC20 public allocRewardToken;
    // Total rewards for each block.
    uint128 public allocRewardPerBlock;
    // The reward distribution address
    address public allocRewardDistributor;
    // Allow emergency withdraw feature
    bool public allocAllowEmergencyWithdraw;

    // Info of each pool.
    AllocPoolInfo[] public allocPoolInfo;
    // A record status of LP pool.
    mapping(IERC20 => bool) public allocIsAdded;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => AllocUserInfo)) public allocUserInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint64 public totalAllocPoint;
    // The block number when rewards mining starts.
    uint64 public allocStartBlockNumber;
    // The block number when rewards mining ends.
    uint64 public allocEndBlockNumber;
    // Info of pending withdrawals.
    mapping(uint256 => mapping(address => AllocPendingWithdrawal))
        public allocPendingWithdrawals;

    event AllocPoolCreated(
        uint256 indexed pid,
        address indexed token,
        uint256 allocPoint
    );
    event AllocDeposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AllocWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AllocPendingWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AllocEmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AllocRewardsHarvested(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /**
     * @notice Initialize the contract, get called in the first time deploy
     * @param _rewardToken the reward token address
     * @param _rewardPerBlock the number of reward tokens that got unlocked each block
     * @param _startBlock the block number when farming start
     */
    function __AllocationPool_init(
        IERC20 _rewardToken,
        uint128 _rewardPerBlock,
        uint64 _startBlock
    ) public initializer {
        __Ownable_init();

        require(
            address(_rewardToken) != address(0),
            "AllocStakingPool: invalid reward token address"
        );
        allocRewardToken = _rewardToken;
        allocRewardPerBlock = _rewardPerBlock;
        allocStartBlockNumber = _startBlock;

        totalAllocPoint = 0;
    }

    /**
     * @notice Validate pool by pool ID
     * @param _pid id of the pool
     */
    modifier allocValidatePoolById(uint256 _pid) {
        require(
            _pid < allocPoolInfo.length,
            "AllocStakingPool: pool are not exist"
        );
        _;
    }

    /**
     * @notice Return total number of pools
     */
    function allocPoolLength() external view returns (uint256) {
        return allocPoolInfo.length;
    }

    /**
     * @notice Add a new lp to the pool. Can only be called by the owner.
     * @param _allocPoint the allocation point of the pool, used when calculating total reward the whole pool will receive each block
     * @param _lpToken the token which this pool will accept
     * @param _delayDuration the time user need to wait when withdraw
     */
    function allocAddPool(
        uint64 _allocPoint,
        IERC20 _lpToken,
        uint128 _delayDuration
    ) external onlyOwner {
        require(
            !allocIsAdded[_lpToken],
            "AllocStakingPool: pool already is added"
        );
        require(
            _delayDuration <= ALLOC_MAXIMUM_DELAY_DURATION,
            "AllocStakingPool: delay duration is too long"
        );
        allocMassUpdatePools();

        uint64 lastRewardBlock = block.number > allocStartBlockNumber
            ? block.number.toUint64()
            : allocStartBlockNumber;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        allocPoolInfo.push(
            AllocPoolInfo({
                lpToken: _lpToken,
                lpSupply: 0,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                delayDuration: _delayDuration
            })
        );
        allocIsAdded[_lpToken] = true;
        emit AllocPoolCreated(
            allocPoolInfo.length - 1,
            address(_lpToken),
            _allocPoint
        );
    }

    /**
     * @notice Update the given pool's reward allocation point. Can only be called by the owner.
     * @param _pid id of the pool
     * @param _allocPoint the allocation point of the pool, used when calculating total reward the whole pool will receive each block
     * @param _delayDuration the time user need to wait when withdraw
     */
    function allocSetPool(
        uint256 _pid,
        uint64 _allocPoint,
        uint128 _delayDuration
    ) external onlyOwner allocValidatePoolById(_pid) {
        require(
            _delayDuration <= ALLOC_MAXIMUM_DELAY_DURATION,
            "AllocStakingPool: delay duration is too long"
        );
        allocMassUpdatePools();

        totalAllocPoint =
            totalAllocPoint -
            allocPoolInfo[_pid].allocPoint +
            _allocPoint;
        allocPoolInfo[_pid].allocPoint = _allocPoint;
        allocPoolInfo[_pid].delayDuration = _delayDuration;
    }

    /**
     * @notice Set the reward distributor. Can only be called by the owner.
     * @param _allocRewardDistributor the reward distributor
     */
    function allocSetRewardDistributor(address _allocRewardDistributor)
        external
        onlyOwner
    {
        require(
            _allocRewardDistributor != address(0),
            "AllocStakingPool: invalid reward distributor"
        );
        allocRewardDistributor = _allocRewardDistributor;
    }

    /**
     * @notice Set the end block number. Can only be called by the owner.
     */
    function allocSetEndBlock(uint64 _endBlockNumber) external onlyOwner {
        require(
            _endBlockNumber > block.number,
            "AllocStakingPool: invalid reward distributor"
        );
        allocEndBlockNumber = _endBlockNumber;
    }

    /**
     * @notice Return time multiplier over the given _from to _to block.
     * @param _from the number of starting block
     * @param _to the number of ending block
     */
    function allocTimeMultiplier(uint128 _from, uint128 _to)
        public
        view
        returns (uint128)
    {
        if (allocEndBlockNumber > 0 && _to > allocEndBlockNumber) {
            return
                allocEndBlockNumber > _from ? allocEndBlockNumber - _from : 0;
        }
        return _to - _from;
    }

    /**
     * @notice Update number of reward per block
     * @param _rewardPerBlock the number of reward tokens that got unlocked each block
     */
    function allocSetRewardPerBlock(uint128 _rewardPerBlock)
        external
        onlyOwner
    {
        allocMassUpdatePools();
        allocRewardPerBlock = _rewardPerBlock;
    }

    /**
     * @notice View function to see pending rewards on frontend.
     * @param _pid id of the pool
     * @param _user the address of the user
     */
    function allocPendingReward(uint256 _pid, address _user)
        public
        view
        allocValidatePoolById(_pid)
        returns (uint128)
    {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][_user];
        uint128 accRewardPerShare = pool.accRewardPerShare;
        uint128 lpSupply = pool.lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint128 multiplier = allocTimeMultiplier(
                pool.lastRewardBlock,
                block.number.toUint128()
            );
            uint128 poolReward = (multiplier *
                allocRewardPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accRewardPerShare =
                accRewardPerShare +
                ((poolReward * ACCUMULATED_MULTIPLIER) / lpSupply);
        }
        return
            user.pendingReward +
            (((user.amount * accRewardPerShare) / ACCUMULATED_MULTIPLIER) -
                user.rewardDebt);
    }

    /**
     * @notice Update reward vairables for all pools. Be careful of gas spending!
     */
    function allocMassUpdatePools() public {
        uint256 length = allocPoolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            allocUpdatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param _pid id of the pool
     */
    function allocUpdatePool(uint256 _pid) public allocValidatePoolById(_pid) {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number.toUint64();
            return;
        }
        uint256 multiplier = allocTimeMultiplier(
            pool.lastRewardBlock,
            block.number.toUint128()
        );
        uint256 poolReward = (multiplier *
            allocRewardPerBlock *
            pool.allocPoint) / totalAllocPoint;
        pool.accRewardPerShare = (pool.accRewardPerShare +
            ((poolReward * ACCUMULATED_MULTIPLIER) / lpSupply)).toUint128();
        pool.lastRewardBlock = block.number.toUint64();
    }

    /**
     * @notice Deposit LP tokens to the farm for reward allocation.
     * @param _pid id of the pool
     * @param _amount amount to deposit
     */
    function allocDeposit(uint256 _pid, uint128 _amount)
        external
        allocValidatePoolById(_pid)
    {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][msg.sender];
        allocUpdatePool(_pid);
        uint128 pending = ((user.amount * pool.accRewardPerShare) /
            ACCUMULATED_MULTIPLIER) - user.rewardDebt;
        user.pendingReward = user.pendingReward + pending;
        user.amount = user.amount + _amount;
        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) /
            ACCUMULATED_MULTIPLIER;
        pool.lpSupply = pool.lpSupply + _amount;
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit AllocDeposit(msg.sender, _pid, _amount);
    }

    /**
     * @notice Withdraw LP tokens from Pool.
     * @param _pid id of the pool
     * @param _amount amount to withdraw
     * @param _harvestReward whether the user want to claim the rewards or not
     */
    function allocWithdraw(
        uint256 _pid,
        uint128 _amount,
        bool _harvestReward
    ) external allocValidatePoolById(_pid) {
        _allocWithdraw(_pid, _amount, _harvestReward);

        AllocPoolInfo storage pool = allocPoolInfo[_pid];

        if (pool.delayDuration == 0) {
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            emit AllocWithdraw(msg.sender, _pid, _amount);
            return;
        }

        AllocPendingWithdrawal
            storage pendingWithdraw = allocPendingWithdrawals[_pid][msg.sender];
        pendingWithdraw.amount = pendingWithdraw.amount + _amount;
        pendingWithdraw.applicableAt =
            block.timestamp.toUint128() +
            pool.delayDuration;
    }

    /**
     * @notice Claim pending withdrawal
     * @param _pid id of the pool
     */
    function allocClaimPendingWithdraw(uint256 _pid)
        external
        allocValidatePoolById(_pid)
    {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];

        AllocPendingWithdrawal
            storage pendingWithdraw = allocPendingWithdrawals[_pid][msg.sender];
        uint256 amount = pendingWithdraw.amount;
        require(amount > 0, "AllocStakingPool: nothing is currently pending");
        require(
            pendingWithdraw.applicableAt <= block.timestamp,
            "AllocStakingPool: not released yet"
        );
        delete allocPendingWithdrawals[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit AllocWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @notice Update allowance for emergency withdraw
     * @param _shouldAllow should allow emergency withdraw or not
     */
    function allocSetAllowEmergencyWithdraw(bool _shouldAllow)
        external
        onlyOwner
    {
        allocAllowEmergencyWithdraw = _shouldAllow;
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _pid id of the pool
     */
    function allocEmergencyWithdraw(uint256 _pid)
        external
        allocValidatePoolById(_pid)
    {
        require(
            allocAllowEmergencyWithdraw,
            "AllocStakingPool: emergency withdrawal is not allowed yet"
        );
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][msg.sender];
        uint128 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpSupply = pool.lpSupply - amount;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit AllocEmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @notice Compound rewards to reward pool
     * @param _rewardPoolId id of the reward pool
     */
    function allocCompoundReward(uint256 _rewardPoolId)
        external
        allocValidatePoolById(_rewardPoolId)
    {
        AllocPoolInfo storage pool = allocPoolInfo[_rewardPoolId];
        AllocUserInfo storage user = allocUserInfo[_rewardPoolId][msg.sender];
        require(
            pool.lpToken == allocRewardToken,
            "AllocStakingPool: invalid reward pool"
        );

        uint128 totalPending = allocPendingReward(_rewardPoolId, msg.sender);

        require(totalPending > 0, "AllocStakingPool: invalid reward amount");

        user.pendingReward = 0;
        allocSafeRewardTransfer(address(this), totalPending);
        emit AllocRewardsHarvested(msg.sender, _rewardPoolId, totalPending);

        allocUpdatePool(_rewardPoolId);

        user.amount = user.amount + totalPending;
        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) /
            ACCUMULATED_MULTIPLIER;
        pool.lpSupply = pool.lpSupply + totalPending;

        emit AllocDeposit(msg.sender, _rewardPoolId, totalPending);
    }

    /**
     * @notice Harvest proceeds msg.sender
     * @param _pid id of the pool
     */
    function allocClaimReward(uint256 _pid)
        public
        allocValidatePoolById(_pid)
        returns (uint128)
    {
        allocUpdatePool(_pid);
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][msg.sender];
        uint128 totalPending = allocPendingReward(_pid, msg.sender);

        user.pendingReward = 0;
        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) /
            (ACCUMULATED_MULTIPLIER);
        if (totalPending > 0) {
            allocSafeRewardTransfer(msg.sender, totalPending);
        }
        emit AllocRewardsHarvested(msg.sender, _pid, totalPending);
        return totalPending;
    }

    /**
     * @notice Harvest proceeds of all pools for msg.sender
     * @param _pids ids of the pools
     */
    function allocClaimAll(uint256[] memory _pids) external {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            allocClaimReward(pid);
        }
    }

    /**
     * @notice Withdraw LP tokens from Pool.
     * @param _pid id of the pool
     * @param _amount amount to withdraw
     * @param _harvestReward whether the user want to claim the rewards or not
     */
    function _allocWithdraw(
        uint256 _pid,
        uint128 _amount,
        bool _harvestReward
    ) internal {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][msg.sender];
        require(user.amount >= _amount, "AllocStakingPool: invalid amount");
        if (_harvestReward || user.amount == _amount) {
            allocClaimReward(_pid);
        } else {
            allocUpdatePool(_pid);
            uint128 pending = ((user.amount * pool.accRewardPerShare) /
                ACCUMULATED_MULTIPLIER) - user.rewardDebt;
            if (pending > 0) {
                user.pendingReward = user.pendingReward + pending;
            }
        }
        user.amount -= _amount;
        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) /
            ACCUMULATED_MULTIPLIER;
        pool.lpSupply = pool.lpSupply - _amount;
    }

    /**
     * @notice Safe reward transfer function, just in case if reward distributor dose not have enough reward tokens.
     * @param _to address of the receiver
     * @param _amount amount of the reward token
     */
    function allocSafeRewardTransfer(address _to, uint128 _amount) internal {
        uint256 bal = allocRewardToken.balanceOf(allocRewardDistributor);

        require(_amount <= bal, "AllocStakingPool: not enough reward token");

        allocRewardToken.safeTransferFrom(allocRewardDistributor, _to, _amount);
    }
}
