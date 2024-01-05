// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

interface IERC20Mintible is IERC20 {
    function mint(address account, uint256 amount) external;
}

// Farm distributes the ERC20 rewards based on staked LP to each user.
contract Farm is Ownable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 pending; // Pending total
        bool exists;
        //
        // We do some fancy math here. Basically, any point in time, the amount of ERC20s
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accERC20PerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accERC20PerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per block.
        uint256 lastRewardBlock; // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
    }

    // Address of the ERC20 Token contract.
    IERC20Mintible public erc20;
    // The total amount of ERC20 that's paid out as reward.
    uint256 public paidOut = 0;
    // ERC20 tokens rewarded per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // All user addresses
    address[] public userAddresses;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when farming starts.
    uint256 public startBlock;
    // The block number when farming ends.
    uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20Mintible _erc20,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) {
        erc20 = _erc20;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _startBlock;
    }

    // Number of LP pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Fund the farm, increase the end block
    function fund(uint256 _amount) public {
        endBlock += _amount / rewardPerBlock;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accERC20PerShare: 0
            })
        );
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function updateOnAir(
        uint256 _allocPoint,
        uint256 _rewardPerBlock,
        uint256 _amount
    ) public onlyOwner {
        updatePool(0);
        PoolInfo storage pool = poolInfo[0];

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];

            if (userInfo[0][userAddress].amount > 0) {
                uint256 pendingAmount =
                    (userInfo[0][userAddress].amount * pool.accERC20PerShare) /
                        1e36 -
                        userInfo[0][userAddress].rewardDebt;
                userInfo[0][userAddress].pending = pendingAmount;
            }
        }

        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolInfo[0].allocPoint = _allocPoint;
        poolInfo[0].lastRewardBlock = lastRewardBlock;
        poolInfo[0].accERC20PerShare = 0;

        rewardPerBlock = _rewardPerBlock;
        startBlock = block.number;
        endBlock = startBlock + _amount / rewardPerBlock;
        updatePool(0);
    }

    // Update the given pool's ERC20 allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see deposited LP for a user.
    function deposited(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    // View function to see pending ERC20s for a user.
    function pending(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accERC20PerShare = pool.accERC20PerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 lastBlock =
                block.number < endBlock ? block.number : endBlock;
            uint256 nrOfBlocks = lastBlock - pool.lastRewardBlock;
            uint256 erc20Reward =
                (nrOfBlocks * (rewardPerBlock) * (pool.allocPoint)) /
                    totalAllocPoint;
            accERC20PerShare =
                accERC20PerShare +
                (erc20Reward * (1e36)) /
                lpSupply;
        }

        return
            (user.amount * accERC20PerShare) /
            1e36 -
            user.rewardDebt +
            user.pending;
    }

    // View function for total reward the farm has yet to pay out.
    function totalPending() external view returns (uint256) {
        if (block.number <= startBlock) {
            return 0;
        }

        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
        return rewardPerBlock * lastBlock - startBlock - paidOut;
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
        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

        if (lastBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = lastBlock;
            return;
        }

        uint256 nrOfBlocks = lastBlock - pool.lastRewardBlock;
        uint256 erc20Reward =
            (nrOfBlocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;

        pool.accERC20PerShare =
            pool.accERC20PerShare +
            (erc20Reward * 1e36) /
            lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Farm for ERC20 allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount =
                (user.amount * pool.accERC20PerShare) /
                    1e36 -
                    user.rewardDebt +
                    user.pending;
            erc20Transfer(msg.sender, pendingAmount);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount + _amount;
        user.rewardDebt = (user.amount * pool.accERC20PerShare) / 1e36;

        if (!user.exists) {
            userAddresses.push(msg.sender);
            user.exists = true;
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Farm.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amount >= _amount,
            "withdraw: can't withdraw more than deposit"
        );
        updatePool(_pid);
        uint256 pendingAmount =
            (user.amount * pool.accERC20PerShare) /
                1e36 -
                user.rewardDebt +
                user.pending;
        erc20Transfer(msg.sender, pendingAmount);
        user.amount = user.amount - _amount;
        user.rewardDebt = (user.amount * pool.accERC20PerShare) / 1e36;
        user.pending = 0;
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.pending = 0;
    }

    // Transfer ERC20 and update the required ERC20 to payout all rewards
    function erc20Transfer(address _to, uint256 _amount) internal {
        erc20.mint(address(this), _amount);
        erc20.transfer(_to, _amount);
        paidOut += _amount;
    }
}
