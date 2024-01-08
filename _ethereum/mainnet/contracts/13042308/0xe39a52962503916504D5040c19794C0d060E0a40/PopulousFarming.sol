// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract PopulousFarming is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // At any point in time, the amount of PXTs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPXTPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPXTPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. PXTs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that PXTs distribution occured.
        uint256 accPXTPerShare;   // Accumulated PXTs per share, times 1e12. See below.
        uint256 totalDeposit;
    }

    // The PXT token for rewards
    IERC20 public PXT;
    // PXT tokens created per block.
    uint256 public PXTPerBlock;
    // Bonus muliplier for early PXT makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PXT mining starts.
    uint256 public startBlock;

    event PoolAdded(uint256 indexed pid, address indexed lpTokenAddress);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 goosePerBlock);

    constructor(
        IERC20 _PXT,
        uint256 _PXTPerBlock,
        uint256 _startBlock
    ) {
        PXT = _PXT;
        PXTPerBlock = _PXTPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(address(_lpToken) != address(0), "add: invalid lp token address");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accPXTPerShare : 0,
        totalDeposit: 0
        }));
        emit PoolAdded(poolInfo.length - 1, address(_lpToken));
    }

    // Update the given pool's PXT allocation point. Can only be called by the contract owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to view pending PXTs.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPXTPerShare = pool.accPXTPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 PXTReward = multiplier.mul(PXTPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPXTPerShare = accPXTPerShare.add(PXTReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accPXTPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 PXTReward = multiplier.mul(PXTPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        pool.accPXTPerShare = pool.accPXTPerShare.add(PXTReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens for PXT allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPXTPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safePXTTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalDeposit = pool.totalDeposit.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPXTPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPXTPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safePXTTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.totalDeposit = pool.totalDeposit.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPXTPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe PXT transfer function, just in case if rounding error causes pool to not have enough PXTs.
    function safePXTTransfer(address _to, uint256 _amount) internal {
        uint256 PXTBal = PXT.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > PXTBal) {
            transferSuccess = PXT.transfer(_to, PXTBal);
        } else {
            transferSuccess = PXT.transfer(_to, _amount);
        }
        require(transferSuccess, "safePXTTransfer: transfer failed");
    }

    function updateEmissionRate(uint256 _PXTPerBlock) public onlyOwner {
        massUpdatePools();
        PXTPerBlock = _PXTPerBlock;
        emit UpdateEmissionRate(msg.sender, _PXTPerBlock);
    }

    function getAddedPools() external view returns (PoolInfo [] memory) {
        return poolInfo;
    }

    // Return total user deposited amount per pool 
    function getUserDepositedAmount(uint256 _pid, address _userAddress) external view returns (uint256) {
        return (userInfo[_pid][_userAddress]).amount;
    }

    // Return total user reward debt - reward amount collected per pool 
    function getUserRewardDebt(uint256 _pid, address _userAddress) external view returns (uint256) {
        return (userInfo[_pid][_userAddress]).rewardDebt;
    }

    function getTotalDeposit(uint256 _pid) external view returns (uint256) {
        return (poolInfo[_pid]).totalDeposit;
    }

    function getPoolInfo(uint256 _pid) external view returns (PoolInfo memory) {
        return poolInfo[_pid];
    }

}
