// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BoringMath.sol";
import "./BoringBatchable.sol";
import "./BoringOwnable.sol";
import "./SignedSafeMath.sol";

/*

 __    __  ___    __        _   
/ / /\ \ \/___\/\ \ \/\ /\ /_\  
\ \/  \/ //  //  \/ / //_///_\\ 
 \  /\  / \_// /\  / __ \/  _  \
  \/  \/\___/\_\ \/\/  \/\_/ \_/
                                

*/

contract TheChocolateFactory is BoringOwnable, BoringBatchable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each GFV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of rewards tokens entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each GFV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of reward tokens to distribute per block.
    struct PoolInfo {
        uint128 accRewardTokensPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    /// @dev Address of Reward Token contract.
    IERC20 public immutable REWARD_TOKEN;

    /// @notice Info of each GFV2 pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each GFV2 pool.
    IERC20[] public lpToken;
    /// @dev List of all added LP tokens.
    mapping(address => bool) private addedLPs;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    /// @notice rewards tokens created per block.
    uint256 public rewardTokensPerBlock;

    /// @dev Extra decimals for pool's accTokensPerShare attribute. Needed in order to accomodate different types of LPs.
    uint256 private constant ACC_TOKEN_PRECISION = 1e18;

    /// @dev nonReentrant flag used to secure functions with external calls.
    bool private nonReentrant;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken
    );
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardBlock,
        uint256 lpSupply,
        uint256 accRewardTokensPerShare
    );
    event SetRewardTokensPerBlock(
        uint256 rewardTokensPerBlock,
        bool withUpdate
    );

    /// @param _rewardToken The reward token contract address.
    /// @param _rewardTokensPerBlock reward tokens created per block.
    constructor(IERC20 _rewardToken, uint256 _rewardTokensPerBlock) public {
        REWARD_TOKEN = _rewardToken;
        rewardTokensPerBlock = _rewardTokensPerBlock;
        totalAllocPoint = 0;
    }

    /// @notice Update number of reward tokens created per block. Can only be called by the owner.
    /// @param _rewardTokensPerBlock reward tokens created per block.
    /// @param _withUpdate true if massUpdatePools should be triggered as well.
    function setRewardTokensPerBlock(
        uint256 _rewardTokensPerBlock,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdateAllPools();
        }
        rewardTokensPerBlock = _rewardTokensPerBlock;
        emit SetRewardTokensPerBlock(_rewardTokensPerBlock, _withUpdate);
    }

    /// @notice Set the nonReentrant flag. Could be used to pause/resume the farm operations. Can only be called by the owner.
    /// @param _val nonReentrant flag value to be set.
    function setNonReentrant(bool _val) external onlyOwner returns (bool) {
        nonReentrant = _val;
        return nonReentrant;
    }

    /// @notice Returns the number of GFV2 pools.
    function poolLength() external view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Returns the reward value for a specific pool.
    function poolReward(uint256 _pid) external view returns (uint256) {
        if (totalAllocPoint == 0) return 0;
        return
            rewardTokensPerBlock.mul(poolInfo[_pid].allocPoint) /
            totalAllocPoint;
    }

    /// @notice Returns the total number of LPs staked in the farm.
    function getLPSupply(uint256 _pid) public view returns (uint256) {
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        return lpSupply;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    function add(uint256 allocPoint, IERC20 _lpToken) external onlyOwner {
        require(
            !addedLPs[address(_lpToken)],
            "genericFarmV2::there is already a pool with this LP"
        );
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        lpToken.push(_lpToken);
        addedLPs[address(_lpToken)] = true;

        poolInfo.push(
            PoolInfo({
                allocPoint: allocPoint.to64(),
                lastRewardBlock: lastRewardBlock.to64(),
                accRewardTokensPerShare: 0
            })
        );
        emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken);
    }

    /// @notice Update the given pool's reward tokens allocation point. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint.to64();
        emit LogSetPool(_pid, _allocPoint);
    }

    /// @notice View function to see pending rewards on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending reward for a given user.
    function pendingReward(
        uint256 _pid,
        address _user
    ) public view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardTokensPerShare = pool.accRewardTokensPerShare;
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        if (
            block.number > pool.lastRewardBlock &&
            lpSupply > 0 &&
            totalAllocPoint > 0
        ) {
            uint256 blocks = block.number.sub(pool.lastRewardBlock);
            accRewardTokensPerShare = accRewardTokensPerShare.add(
                (blocks.mul(rewardTokensPerBlock).mul(pool.allocPoint).mul(
                    ACC_TOKEN_PRECISION
                ) / totalAllocPoint) / lpSupply
            );
        }
        pending = int256(
            user.amount.mul(accRewardTokensPerShare) / ACC_TOKEN_PRECISION
        ).sub(user.rewardDebt).toUInt256();
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdateAllPools() public {
        uint256 len = poolInfo.length;
        for (uint256 pid = 0; pid < len; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Update reward variables for specified pools. Be careful of gas spending!
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
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = lpToken[pid].balanceOf(address(this));
            if (lpSupply > 0 && totalAllocPoint > 0) {
                uint256 blocks = block.number.sub(pool.lastRewardBlock);
                pool.accRewardTokensPerShare = pool.accRewardTokensPerShare.add(
                    ((blocks.mul(rewardTokensPerBlock).mul(pool.allocPoint).mul(
                        ACC_TOKEN_PRECISION
                    ) / totalAllocPoint) / lpSupply).to128()
                );
            }
            pool.lastRewardBlock = block.number.to64();
            poolInfo[pid] = pool;
            emit LogUpdatePool(
                pid,
                pool.lastRewardBlock,
                lpSupply,
                pool.accRewardTokensPerShare
            );
        }
    }

    /// @notice Deposit LP tokens to GFV2 for rewards allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) external {
        require(!nonReentrant, "genericFarmV2::nonReentrant - try again");
        nonReentrant = true;

        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(
            int256(
                amount.mul(pool.accRewardTokensPerShare) / ACC_TOKEN_PRECISION
            )
        );

        // Interactions
        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, to);
        nonReentrant = false;
    }

    /// @notice Withdraw LP tokens from GFV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) external {
        require(!nonReentrant, "genericFarmV2::nonReentrant - try again");
        nonReentrant = true;

        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt.sub(
            int256(
                amount.mul(pool.accRewardTokensPerShare) / ACC_TOKEN_PRECISION
            )
        );
        user.amount = user.amount.sub(amount);

        // Interactions
        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
        nonReentrant = false;
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the rewards.
    function harvest(uint256 pid, address to) public {
        require(!nonReentrant, "genericFarmV2::nonReentrant - try again");
        nonReentrant = true;

        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedRewardTokens = int256(
            user.amount.mul(pool.accRewardTokensPerShare) / ACC_TOKEN_PRECISION
        );
        uint256 _pendingRewardTokens = accumulatedRewardTokens
            .sub(user.rewardDebt)
            .toUInt256();

        // Effects
        user.rewardDebt = accumulatedRewardTokens;

        // Interactions
        if (_pendingRewardTokens > 0) {
            REWARD_TOKEN.safeTransfer(to, _pendingRewardTokens);
        }

        emit Harvest(msg.sender, pid, _pendingRewardTokens);
        nonReentrant = false;
    }

    function harvestAll(address to) external {
        uint256 len = poolInfo.length;
        for (uint256 pid; pid < len; pid++) {
            harvest(pid, to);
        }
    }

    function getAllPendingRewards(address to)
        external view
        returns (uint256 _totalRewards)
    {

        uint256 len = poolInfo.length;
        for (uint256 pid; pid < len; pid++) {

            _totalRewards += pendingReward(pid, to);

        }

    }

    function balanceOf(uint256 pid, address user)
        external view
        returns (uint256 _balance)
    {

        _balance = userInfo[pid][user].amount;

    }

    function poolShare(uint256 pid, address user)
        external view
        returns (uint256 _share)
    {

        uint256 _totalSupply = getLPSupply(pid);
        uint256 _balance = userInfo[pid][user].amount;

        if (_totalSupply > 0)
        _share = (_balance.mul(1e18) / _totalSupply) * 100;
        else
        _share = 0;
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        require(
            address(0) != to,
            "genericFarmV2::can't withdraw to address zero"
        );
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
}
