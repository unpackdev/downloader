// SPDX-License-Identifier: WTFPL
pragma solidity =0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

// Interfaces
import "./ILootCitadel.sol";
import "./IUniswapV2PairMinimal.sol";

contract ExpansionUniswapLP is Ownable {
    /***********************************|
    |   Libraries                       |
    |__________________________________*/
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /***********************************|
    |   Constants                       |
    |__________________________________*/

    ILootCitadel public citadel;
    uint256 public lootPerBlock;
    uint256 public rewardStartBlock;
    uint256 public rewardEndBlock;

    /**
     * @notice UserInfo
     * @dev Track account deposits and rewards
     */
    struct UserInfo {
        uint256 amount; // Deposited Tokens
        uint256 rewardDebt; // User Reward Debt
    }

    /**
     * @notice PoolInfo
     * @dev Manage the liquidity pool configuration
     */
    struct PoolInfo {
        IERC20 lpToken; // LP Token Address.
        uint256 allocPoint; // Assigned Allocation Pounts
        uint256 lastRewardBlock; // Last Calculated Reward Block
        uint256 accLootPerShare; // Accumulated LOOT Per Shares
    }

    PoolInfo[] public poolInfo;
    uint256 public totalAllocPoint = 0;

    // User Info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Liquidity Pools
    mapping(address => bool) public poolExists;

    /****************************************|
    |                  Events                |
    |_______________________________________*/
    /**
     * @notice PoolAdded
     * @dev Event fires when a new pool is added
     */
    event PoolAdded(uint256 pid, address token, uint256 points);

    /**
     * @notice PoolAdded
     * @dev Event fires when a user deposits a Uniswap LP tokens
     */
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @notice PoolAdded
     * @dev Event fires when a user withdraw Uniswap LP tokens
     */
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @notice EmergencyWithdraw
     * @dev Event fires when a user executes an emergency withdrawl
     */
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /**
     * @notice RewardClaimed
     * @dev Event fires when a user claims rewards
     */
    event RewardClaimed(address user, uint256 amount);

    /***********************************|
    |     		 Constructor            |
    |__________________________________*/
    constructor(
        address _citadel,
        uint256 _lootPerBlock,
        uint256 _rewardStartBlock,
        uint256 _rewardEndBlock
    ) public {
        citadel = ILootCitadel(_citadel);
        lootPerBlock = _lootPerBlock;
        rewardStartBlock = _rewardStartBlock;
        rewardEndBlock = _rewardEndBlock;
    }

    /***********************************|
    |               Reads               |
    |__________________________________*/

    /**
     * @notice Counts the number of pools
     * @dev Gets the poolInfo length to calculate number of staking pools
     */
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    /***********************************|
    |               Writes              |
    |__________________________________*/

    /**
     * @notice Add LP Token Pool
     * @dev Add a new staking pool for Uniswap LP token to reward LOOT.
     * @param _allocPoint Points allocated
     * @param _lpToken Liquidity Provider token
     * @return true
     */
    function add(uint256 _allocPoint, address _lpToken)
        external
        onlyOwner
        returns (bool)
    {
        // Check if Pool Exists
        require(poolExists[_lpToken] != true, "Pool Exists");
        poolExists[_lpToken] = true;

        // Awlays Mass Update - Ensures no trickery.
        massUpdatePools();

        uint256 pid = poolInfo.length;

        // Set Last Reward Block
        uint256 lastRewardBlock =
            block.number > rewardStartBlock ? block.number : rewardStartBlock;

        poolInfo.push(
            PoolInfo({
                lpToken: IERC20(_lpToken),
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accLootPerShare: 0
            })
        );

        // Adjust Global Allocation Points
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        // Emit PoolAdded
        emit PoolAdded(pid, _lpToken, _allocPoint);

        return true;
    }

    /**
     * @dev Update the given pool's LOOT allocation point.
     * @param _pid Pool ID
     * @param _allocPoint New allocation points
     * @return true
     */
    function set(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
        returns (bool)
    {
        // Update All Pools
        massUpdatePools();

        // Adjust Total Allocation Points
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );

        // Set Pool Allocation Points
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to)
        public
        view
        returns (uint256)
    {
        if (to < rewardEndBlock) {
            return to.sub(from);
        } else if (from > rewardEndBlock) {
            return 0;
        } else {
            return rewardEndBlock.sub(from);
        }
    }

    /**
     * @dev View redeemable LOOT amount
     * @param pid Pool ID
     * @param _user User account
     * @return Pending LOOT reward.
     */
    function pendingLoot(uint256 pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];
        uint256 accLootPerShare = pool.accLootPerShare;

        // Current LP Token supply
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // Calculate released since last reward block.
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);

            // Stop calculating after reward block end.
            if (multiplier > 0) {
                // Calculate LOOT Reward
                uint256 lootReward =
                    multiplier.mul(lootPerBlock).mul(pool.allocPoint).div(
                        totalAllocPoint
                    );

                // Accrued LOOT per Share
                accLootPerShare = accLootPerShare.add(
                    lootReward.mul(1e12).div(lpSupply)
                );
            }
        }

        return user.amount.mul(accLootPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev Update reward variables for all pools.
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     * @param _pid Pool ID
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        // Update Last Reward Block
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // Calculate Multiplier
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        // Check Rewards Still Available
        if (multiplier > 0) {
            // Update LOOT Reward
            uint256 lootReward =
                multiplier.mul(lootPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );

            // Update Released LOOT
            pool.accLootPerShare = pool.accLootPerShare.add(
                lootReward.mul(1e12).div(lpSupply)
            );
        }

        // Update Last Reward Block
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev Deposit tokens and redeem rewards
     * @param pid Pool ID
     * @param amount token deposit amount
     * @return true
     */
    function deposit(uint256 pid, uint256 amount) public returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // Update Pool
        updatePool(pid);

        // Reward User with Active Deposits
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLootPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                // Mint Pending Reward
                _alchemy(msg.sender, pending);

                // Emit RewardClaimed
                emit RewardClaimed(msg.sender, pending);
            }
        }

        if (amount > 0) {
            // Transfer Tokens
            pool.lpToken.safeTransferFrom(msg.sender, address(this), amount);

            // Update User Amount Balance
            user.amount = user.amount.add(amount);
        }

        // Update User Reward Debt
        user.rewardDebt = user.amount.mul(pool.accLootPerShare).div(1e12);

        // Emit Deposit
        emit Deposit(msg.sender, pid, amount);

        return true;
    }

    /**
     * @dev Deposit tokens using permit and redeem rewards
     * @param pid Pool ID
     * @param amount token deposit amount
     * @param deadline timestamp deadline
     * @param v signature v data
     * @param r signature r data
     * @param s signature s data
     * @return true
     */
    function depositWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        IUniswapV2PairMinimal lpToken =
            IUniswapV2PairMinimal(address(poolInfo[pid].lpToken));
        lpToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        deposit(pid, amount);

        return true;
    }

    /**
     * @dev Withdraw tokens and redeem rewards
     * @param pid Pool ID
     * @param amount token withdraw amount
     */
    function withdraw(uint256 pid, uint256 amount) external returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // Update Pool
        updatePool(pid);

        // Amount Matches Available User Balance
        require(user.amount >= amount, "Exceeds Deposited Balance");

        uint256 pending =
            user.amount.mul(pool.accLootPerShare).div(1e12).sub(
                user.rewardDebt
            );

        if (pending > 0) {
            // Mint Pending Reward
            _alchemy(msg.sender, pending);

            // Emit RewardClaimed
            emit RewardClaimed(msg.sender, pending);
        }

        if (amount > 0) {
            user.amount = user.amount.sub(amount);
            pool.lpToken.safeTransfer(address(msg.sender), amount);
        }

        user.rewardDebt = user.amount.mul(pool.accLootPerShare).div(1e12);
        emit Withdraw(msg.sender, pid, amount);

        return true;
    }

    /**
     * @dev Withdraw deposited tokens without rewards
     * @param pid Pool ID
     */
    function emergencyWithdraw(uint256 pid) external returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // Transfer LP Tokens
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);

        // Zero Out User Balances
        user.amount = 0;
        user.rewardDebt = 0;

        // Emit EmergencyWithdraw
        emit EmergencyWithdraw(msg.sender, pid, user.amount);

        return true;
    }

    /**
     * @notice User deposited amount per pool
     * @param pid Pool ID
     * @param _user User Address
     */
    function getDepositedAmount(uint256 pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[pid][_user];
        return user.amount;
    }

    /**
     * @notice Call Citadel alchemy
     * @dev Call Citadel alchemy to mint LOOT token
     * @param to receiver of reward
     * @param amount reward amount
     */
    function _alchemy(address to, uint256 amount) internal {
        // Check Remaining Balance
        uint256 balance = citadel.expansionBalance(address(this));

        // rewardBlockEnd Ensure rewards are awalys accurate, but if a miscalculation
        // exists users can still withdraw total remaining rewards.
        if (amount > balance) {
            citadel.alchemy(to, balance);
        } else {
            citadel.alchemy(to, amount);
        }
    }
}
