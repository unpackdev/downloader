// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./StackToken.sol";

// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once  is sufficiently
// distributed and the community can show to govern itself.
//
contract StackFarmer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of stacks
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accStackPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accStackPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. stacks to distribute per block.
        uint256 lastRewardBlock; // Last block number that stacks distribution occurs.
        uint256 accStackPerShare; // Accumulated stacks per share, times 1e12. See below.
    }

    // The stack TOKEN!
    StackToken public stack;
    // Block number when bonus stack period ends.
    uint256 public bonusEndBlock;
    // stack tokens created per block.
    uint256 public stackPerBlock;
    // Bonus muliplier for early liquidity providers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when stack mining starts.
    uint256 public startBlock;
    //The rewards added by Dev
    uint256 public rewards;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        StackToken _stack,
        uint256 _stackPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        stack = _stack;
        stackPerBlock = _stackPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addRewards(uint256 _amount) public onlyOwner {
        stack.transferFrom(address(msg.sender), address(this), _amount);
        rewards = rewards.add(_amount);
    }

    function changeStackPerBlock(uint256 _stackPerBlock) public onlyOwner {
        massUpdatePools();
        stackPerBlock = _stackPerBlock;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accStackPerShare: 0
            })
        );
    }

    // Update the given pool's stack allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    // View function to see pending stacks on frontend.
    function pendingStack(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accStackPerShare = pool.accStackPerShare;
        uint256 lpSupply;
        if (pool.lpToken == stack) {
            lpSupply = pool.lpToken.balanceOf(address(this)).sub(rewards);
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }

        if (totalAllocPoint == 0) {
            if (user.amount == 0) {
                return 0;
            }
            return
                user.amount.mul(accStackPerShare).div(1e12).sub(
                    user.rewardDebt
                );
        }
        if (user.amount == 0) {
            return 0;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 stackReward = multiplier
            .mul(stackPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
            accStackPerShare = accStackPerShare.add(
                stackReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accStackPerShare).div(1e12).sub(user.rewardDebt);
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
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply;
        if (pool.lpToken == stack) {
            lpSupply = pool.lpToken.balanceOf(address(this)).sub(rewards);
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }

        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        if (totalAllocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 stackReward = multiplier
        .mul(stackPerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint);
        pool.accStackPerShare = pool.accStackPerShare.add(
            stackReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens for stack rewards.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
            .amount
            .mul(pool.accStackPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
            if (pending > 0) {
                distributeReward(_pid, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accStackPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accStackPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            if (pending < rewards) {
                distributeReward(_pid, pending);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accStackPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function distributeReward(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount <= rewards, "Not enough Rewards");
        uint256 pending = user.amount.mul(pool.accStackPerShare).div(1e12).sub(
            user.rewardDebt
        );
        require(pending <= _amount, "Amount greater than pending rewards.");
        rewards = rewards.sub(_amount);
        safestackTransfer(address(msg.sender), _amount);
    }

    // Safe stack transfer function, just in case if rounding error causes pool to not have enough stacks.
    function safestackTransfer(address _to, uint256 _amount) internal {
        uint256 stackBal = stack.balanceOf(address(this));
        if (_amount > stackBal) {
            stack.transfer(_to, stackBal);
        } else {
            stack.transfer(_to, _amount);
        }
    }
}

