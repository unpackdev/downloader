// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBagBang.sol";

contract BagRadiation is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    struct PoolInfo {
        address stakingToken; // Address of staking token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardBlock; // Last block number that distribution occurs.
        uint256 accRewardPerShare; // Accumulated reward tokens per share, times 1e24. See below.
        uint16 earlyWithdrawalFeeBP; // Early withdrawal fee in basis points
    }

    IERC20 public rewardToken;
    IBagBang public bagBang;
    address public feeAddress; // early withdrawl fees go to feeAddress

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    uint256 public rewardStartBlock;
    uint256 public rewardNumBlocks;
    uint256 public rewardEndBlock;
    uint256 public rewardPerBlock;
    uint256 public feeEndBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IBagBang _bagBang,
        IERC20 _rewardToken,
        address _feeAddress,
        uint256 _feeEndBlock,
        uint256 _rewardStartBlock,
        uint256 _rewardNumBlocks,
        uint256 _totalRewards
    ) public {
        require(_rewardNumBlocks > 0, "constructor: invalid reward blocks");
        bagBang = _bagBang;
        rewardToken = _rewardToken;
        feeAddress = _feeAddress;
        feeEndBlock = _feeEndBlock;
        rewardStartBlock = _rewardStartBlock;
        rewardNumBlocks = _rewardNumBlocks;
        rewardEndBlock = _rewardStartBlock.add(_rewardNumBlocks).sub(1);
        rewardPerBlock = _totalRewards.div(rewardNumBlocks);
    }

    function isDuplicatedPool(address _stakingToken) public view returns (bool) {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; _pid++) {
            if (poolInfo[_pid].stakingToken == _stakingToken) return true;
        }
        return false;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        uint256 _allocPoint,
        address _stakingToken,
        uint16 _earlyWithdrawalFeeBP,
        bool _withUpdate
    ) public onlyOwner {
        require(_earlyWithdrawalFeeBP <= 10000, "addPool: invalid early withdrawal fee");
        require(!isDuplicatedPool(_stakingToken), "addPool: stakingToken dup");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > rewardStartBlock ? block.number : rewardStartBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                earlyWithdrawalFeeBP: _earlyWithdrawalFeeBP
            })
        );
    }

    // Update the given pool's allocation point. Can only be called by the owner.
    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _earlyWithdrawalFeeBP
    ) public onlyOwner {
        require(_earlyWithdrawalFeeBP <= 10000, "setPool: invalid early withdrawal fee");
        massUpdatePools();
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

    // View function to see pending reward on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = IERC20(pool.stakingToken).balanceOf(address(this)); 
        if (block.number > pool.lastRewardBlock &&
            lpSupply > 0 &&
            pool.lastRewardBlock < rewardEndBlock
        ) {
            uint256 updatedRewardBlock = block.number >= rewardEndBlock ? rewardEndBlock : block.number;
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, updatedRewardBlock);
            uint256 reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e24).div(lpSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e24).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
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
        if (pool.lastRewardBlock >= rewardEndBlock) {
            return;
        }
        uint256 updatedRewardBlock = block.number >= rewardEndBlock ? rewardEndBlock : block.number;
        uint256 lpSupply = IERC20(pool.stakingToken).balanceOf(address(this)); // TODO: this isn't right
        if (lpSupply == 0) {
            pool.lastRewardBlock = updatedRewardBlock;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, updatedRewardBlock);
        uint256 reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        bagBang.mintPool(address(this), reward);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e24).div(lpSupply));
        pool.lastRewardBlock = updatedRewardBlock;
    }

    // Deposit LP tokens to BagBang for reward allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e24).sub(user.rewardDebt);
            safeRewardTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            IERC20(pool.stakingToken).safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e24);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from BagBang.
    function withdraw(uint256 _pid, uint256 _amount) public {
        _withdraw(_pid, _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawAll(uint256 _pid) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        _withdraw(_pid, user.amount);
        emit Withdraw(msg.sender, _pid, user.amount);
    }

    function _withdraw(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e24).sub(user.rewardDebt);
        if (pending > 0) {
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e24);
            safeRewardTransfer(msg.sender, pending);
        }

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e24);
        uint256 returnAmount = _amount;
        if (pool.earlyWithdrawalFeeBP > 0 && block.number < feeEndBlock) {
            uint256 withdrawalFee = _amount.mul(pool.earlyWithdrawalFeeBP).div(10000);
            returnAmount = returnAmount.sub(withdrawalFee);
            IERC20(pool.stakingToken).safeTransfer(feeAddress, withdrawalFee);
        }
        IERC20(pool.stakingToken).safeTransfer(address(msg.sender), returnAmount);
    }

    // Harvest BAG reward earned from the pool
    function harvest(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e24).sub(user.rewardDebt);
        require(pending > 0, "harvest: no reward owed");
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e24);
        safeRewardTransfer(msg.sender, pending);
        emit Harvest(msg.sender, _pid, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IERC20(pool.stakingToken).safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe transfer function, just in case if rounding error causes pool to not have enough rewards.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 bagBal = rewardToken.balanceOf(address(this));
        if (_amount > bagBal) {
            rewardToken.transfer(_to, bagBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    // Update fee address
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: not authorized");
        feeAddress = _feeAddress;
    }
}
