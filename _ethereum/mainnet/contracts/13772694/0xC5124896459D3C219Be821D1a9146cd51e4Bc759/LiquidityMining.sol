// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./SignedSafeMath.sol";
import "./STRM.sol";

/// @title LiquidityMining
/// @notice
/// @dev
contract LiquidityMining is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each masterchef user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of INSTRUMENTAL entitled to the user.
    /// `locked` locked for the first 3 months of liquidity mining, enjoy a 2 times boost
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each LM pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of INSTRUMENTAL to distribute per block.
    struct PoolInfo {
        uint256 accInstrumentalPerShare;
        uint64 lastRewardBlock;
        uint64 end;
        bool locked;
        uint256 instrumentalPerBlock;
        uint256 supply;
    }
    /// @notice Address of INSTRUMENTAL contract.
    STRM public immutable INSTRUMENTAL;
    /// @notice keep track of how much rewards needs to be distributed
    uint256 internal claimableRewards = 0;
    /// @notice Info of each LM pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each LiquidityMining pool.
    IERC20[] public lpToken;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice
    uint256 private constant ACC_INST_PRECISION = 1e12;

    // @notice Pool expiration in blocks (4 months at an average of 13 seconds per block)
    uint256 private constant POOL_EXPIRATION = 800_000;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(
        uint256 indexed pid,
        uint256 instrumentalPerBlock,
        IERC20 indexed lpToken
    );
    event LogSetPool(uint256 indexed pid, uint256 instrumentalPerBlock);
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardBlock,
        uint256 lpSupply,
        uint256 accInstrumentalPerShare
    );
    event LogInit();

    /// @dev
    modifier onlyUnlocked(uint256 pid) {
        require(_isLocked(pid) == false, "LiquidityMining: ONLY_UNLOCKED");
        _;
    }

    /// @notice
    /// @dev
    /// @param _instrumental ()
    constructor(STRM _instrumental) {
        INSTRUMENTAL = _instrumental;
    }

    function _isLocked(uint256 pid) internal view returns (bool) {
        PoolInfo memory pool = poolInfo[pid];
        return (pool.locked == true && pool.end > block.number);
    }

    function _arePoolExpired() internal view returns (bool) {
        uint256 end = 0;
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            end = poolInfo[i].end > end ? poolInfo[i].end : end;
        }
        return block.number > end + POOL_EXPIRATION;
    }

    /// @notice Returns the number of LM pools.
    /// @notice
    /// @dev
    /// @return pools (uint256)
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    function add(
        uint256 instrumentalPerBlock,
        IERC20 _lpToken,
        uint64 end,
        bool locked
    ) public onlyOwner {
        uint256 maxRewards = uint256(end).sub(block.number).mul(instrumentalPerBlock);
        require(
            INSTRUMENTAL.balanceOf(address(this)) >= maxRewards + claimableRewards,
            "LM: Insufficient funds"
        );
        claimableRewards += maxRewards;

        lpToken.push(_lpToken);

        poolInfo.push(
            PoolInfo({
                accInstrumentalPerShare: 0,
                lastRewardBlock: uint64(block.number),
                end: end,
                locked: locked,
                instrumentalPerBlock: instrumentalPerBlock,
                supply: 0
            })
        );
        emit LogPoolAddition(lpToken.length.sub(1), instrumentalPerBlock, _lpToken);
    }

    /// @notice Update the given pool's INSTRUMENTAL allocation point. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _instrumentalPerBlock New rewards of the pool.
    /// disabled for now
    // function set(uint256 _pid, uint256 _instrumentalPerBlock) public onlyOwner {
    //     poolInfo[_pid].instrumentalPerBlock = _instrumentalPerBlock;
    //     emit LogSetPool(_pid, _instrumentalPerBlock);
    // }

    /// @notice View function to see pending INSTRUMENTAL on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending INSTRUMENTAL reward for a given user.
    function pendingInstrumental(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accInstrumentalPerShare = pool.accInstrumentalPerShare;
        if (block.number > pool.lastRewardBlock && pool.supply != 0) {
            uint256 lastValidBlock = block.number > pool.end ? pool.end : block.number;
            uint256 blocks = lastValidBlock.sub(pool.lastRewardBlock);
            uint256 sushiReward = blocks.mul(pool.instrumentalPerBlock);
            accInstrumentalPerShare = accInstrumentalPerShare.add(
                sushiReward.mul(ACC_INST_PRECISION) / pool.supply
            );
        }
        pending = int256(user.amount.mul(accInstrumentalPerShare) / ACC_INST_PRECISION)
            .sub(user.rewardDebt)
            .toUInt256();
    }

    function withdrawLeftovers() public onlyOwner {
        require(_arePoolExpired() == false, "LM: Pools are not expired");
        INSTRUMENTAL.transfer(msg.sender, INSTRUMENTAL.balanceOf(address(this)));
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
        if (block.number > pool.lastRewardBlock && pool.lastRewardBlock < pool.end) {
            uint256 lastValidBlock = block.number > pool.end ? pool.end : block.number;
            if (pool.supply > 0) {
                uint256 blocks = lastValidBlock.sub(pool.lastRewardBlock);
                uint256 sushiReward = blocks.mul(pool.instrumentalPerBlock);
                // mint additional tokens @todo should I mint them or not?
                // INSTRUMENTAL.mint(address(this), sushiReward);
                uint256 rewardFactor = sushiReward.mul(ACC_INST_PRECISION) / pool.supply;
                pool.accInstrumentalPerShare = pool.accInstrumentalPerShare.add(rewardFactor);
                pool.lastRewardBlock = uint64(lastValidBlock);
            }
            poolInfo[pid] = pool;
            emit LogUpdatePool(
                pid,
                pool.lastRewardBlock,
                pool.supply,
                pool.accInstrumentalPerShare
            );
        }
    }

    /// @notice Deposit LP tokens to LM for INSTRUMENTAL allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) public {
        updatePool(pid);
        UserInfo storage user = userInfo[pid][to];
        PoolInfo storage pool = poolInfo[pid];

        // Effects
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(
            int256(amount.mul(pool.accInstrumentalPerShare) / ACC_INST_PRECISION)
        );
        pool.supply = pool.supply.add(amount);

        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, to);
    }

    /// @notice Withdraw LP tokens from LM.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) public onlyUnlocked(pid) {
        updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        PoolInfo storage pool = poolInfo[pid];
        // Effects
        user.rewardDebt = user.rewardDebt.sub(
            int256(amount.mul(pool.accInstrumentalPerShare) / ACC_INST_PRECISION)
        );
        user.amount = user.amount.sub(amount);
        pool.supply = pool.supply.sub(amount);

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of INSTRUMENTAL rewards.
    function harvest(uint256 pid, address to) public onlyUnlocked(pid) {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        require(_arePoolExpired() == false, "LM: Pool has expired");
        int256 accumulatedInstrumental = int256(
            user.amount.mul(pool.accInstrumentalPerShare) / ACC_INST_PRECISION
        );
        uint256 _pendingRewards = accumulatedInstrumental.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedInstrumental;

        // Interactions
        if (_pendingRewards != 0) {
            claimableRewards -= _pendingRewards;
            INSTRUMENTAL.transfer(to, _pendingRewards);
        }

        emit Harvest(msg.sender, pid, _pendingRewards);
    }

    /// @notice Withdraw LP tokens from LM and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and INSTRUMENTAL rewards.
    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) public onlyUnlocked(pid) {
        updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        PoolInfo storage pool = poolInfo[pid];
        require(_arePoolExpired() == false, "LM: Pool has expired");
        int256 accumulatedInstrumental = int256(
            user.amount.mul(pool.accInstrumentalPerShare) / ACC_INST_PRECISION
        );
        uint256 _pendingReward = accumulatedInstrumental.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedInstrumental.sub(
            int256(amount.mul(pool.accInstrumentalPerShare) / ACC_INST_PRECISION)
        );
        user.amount = user.amount.sub(amount);
        pool.supply = pool.supply.sub(amount);

        // Interactions
        claimableRewards -= _pendingReward;
        INSTRUMENTAL.transfer(to, _pendingReward);

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, _pendingReward);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public onlyUnlocked(pid) {
        UserInfo storage user = userInfo[pid][msg.sender];
        PoolInfo storage pool = poolInfo[pid];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.supply = pool.supply.sub(amount);

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
}
