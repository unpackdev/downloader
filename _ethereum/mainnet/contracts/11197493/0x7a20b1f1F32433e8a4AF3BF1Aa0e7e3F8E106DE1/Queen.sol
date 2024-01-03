// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./CheckToken.sol";
// import "./console.sol";


/** Queen is Masterchef but without the migrate, without the dev addr
    without the multiplier. But adds in an end block. to minting.
*/
contract Queen is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CHKs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accChkPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accChkPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CHKs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CHKs distribution occurs.
        uint256 accChkPerShare; // Accumulated CHKs per share, times 1e18. See below.
    }

    // The CHK TOKEN!
    CheckToken public chk;
    // The block number when CHK mining starts.
    uint256 public startBlock;
    uint256 public endBlock;
    // CHK tokens created per block.
    uint256 public chkPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _chk,
        uint256 _chkPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        chk = CheckToken(_chk);
        chkPerBlock = _chkPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accChkPerShare: 0
        }));
    }

    // Update the given pool's CHK allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return Math.min(_to, endBlock).sub(_from);
    }

    // View function to see pending CHKs on frontend.
    function pendingChk(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accChkPerShare = pool.accChkPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // console.log("lpSupply: ", lpSupply);
        // console.log("pool.lastRewardBlock: ", pool.lastRewardBlock);
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            // console.log("multiplier: ", multiplier );
            // console.log("chkPerBlock: ", chkPerBlock);
            // console.log("pool.allocPoint: ", pool.allocPoint);
            // console.log("totalAlloc: ", totalAllocPoint);
            uint256 chkReward = multiplier.mul(chkPerBlock.mul(pool.allocPoint).div(totalAllocPoint));
            // console.log("accChkPerShare: ", accChkPerShare);
            // console.log("chkReward: ", chkReward);
            accChkPerShare = accChkPerShare.add(chkReward.mul(1e18).div(lpSupply));
            // console.log("accChkPerShare: ", accChkPerShare);
        }
        return user.amount.mul(accChkPerShare).div(1e18).sub(user.rewardDebt);
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
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 chkReward = multiplier.mul(chkPerBlock.mul(pool.allocPoint).div(totalAllocPoint));
        // chk.mint(devaddr, chkReward.div(10));
        chk.mint(address(this), chkReward);
        pool.accChkPerShare = pool.accChkPerShare.add(chkReward.mul(1e18).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Chk allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        // console.log("user.amount: ", user.amount);
        if (user.amount > 0) {
            // console.log("pool.accChkPerShare: ", pool.accChkPerShare);
            // console.log("userRewardDebt: ", user.rewardDebt);
            uint256 pending = user.amount.mul(pool.accChkPerShare).div(1e18).sub(user.rewardDebt);
            // console.log("pending: ", pending);
            if(pending > 0) {
                chkSafeTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accChkPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accChkPerShare).div(1e18).sub(user.rewardDebt);
        if(pending > 0) {
            chkSafeTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accChkPerShare).div(1e18);
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
    }

    // Safe chk transfer function, just in case if rounding error causes pool to not have enough CHKs.
    function chkSafeTransfer(address _to, uint256 _amount) internal {
        uint256 chkBal = chk.balanceOf(address(this));
        // console.log("bal: ", chkBal);
        if (_amount > chkBal) {
            chk.transfer(_to, chkBal);
        } else {
            chk.transfer(_to, _amount);
        }
    }
}