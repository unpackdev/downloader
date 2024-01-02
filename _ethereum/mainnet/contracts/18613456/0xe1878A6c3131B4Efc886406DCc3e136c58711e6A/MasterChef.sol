// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract MasterChef is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of LWTFs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. LWTFs to distribute per block.
        uint256 lastRewardTime; // Last time that LWTFs distribution occurs.
        uint256 accTokenPerShare; // Accumulated LWTFs per share, times 1e12. See below.
        uint256 withdrawFee;
    }
    uint256 public constant withdrawFeePrecision = 10000;
    // The LWTF TOKEN!
    IERC20 public lwtf;
    // LWTF tokens created per second.
    uint256 public tokenPerSecond;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when LWTF mining starts.
    uint256 public startTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(
        // IERC20 _token,
        uint256 _tokenPerSecond,
        uint256 _startTime
    ) external initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // lwtf = _token;
        tokenPerSecond = _tokenPerSecond;
        startTime = _startTime;
    }

    function setWtfToken(IERC20 _wtf) external onlyOwner {
        require(address(lwtf) == address(0), "already set");
        lwtf = _wtf;
    }

    function setPause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setTokenPerSecond(uint256 amount) external onlyOwner {
        massUpdatePools();
        tokenPerSecond = amount;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _withdrawFee,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime
            ? block.timestamp
            : startTime;
        totalAllocPoint += _allocPoint;

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accTokenPerShare: 0,
                withdrawFee: _withdrawFee
            })
        );
    }

    // Update the given pool's LWTF allocation point. Can only be called by the owner.
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

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to - _from;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 pid; pid < poolInfo.length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            pool.lastRewardTime,
            block.timestamp
        );
        uint256 reward = (multiplier * tokenPerSecond * pool.allocPoint) /
            totalAllocPoint;
        // lwtf.mint(address(this), reward);
        pool.accTokenPerShare += (reward * 1e12) / lpSupply;
        pool.lastRewardTime = block.timestamp;
    }

    // View function to see pending LWTFs on frontend.
    function pendingLwtf(
        address _user,
        uint256 _pid
    ) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 reward = (multiplier * tokenPerSecond * pool.allocPoint) /
                totalAllocPoint;
            accTokenPerShare = accTokenPerShare + (reward * 1e12) / lpSupply;
        }
        return (user.amount * accTokenPerShare) / 1e12 - user.rewardDebt;
    }

    // Deposit LP tokens to MasterChef for LWTF allocation.
    function deposit(
        address _user,
        uint256 _pid,
        uint256 _amount
    ) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accTokenPerShare) /
                1e12 -
                user.rewardDebt;
            safeLWTFTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount += _amount;
        user.rewardDebt = (user.amount * pool.accTokenPerShare) / 1e12;
        emit Deposit(_user, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(
        address _user,
        uint256 _pid,
        uint256 _amount
    ) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accTokenPerShare) /
            1e12 -
            user.rewardDebt;
        safeLWTFTransfer(msg.sender, pending);
        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accTokenPerShare) / 1e12;
        uint256 fee = (_amount * pool.withdrawFee) / withdrawFeePrecision;
        pool.lpToken.safeTransfer(address(owner()), fee);
        pool.lpToken.safeTransfer(address(msg.sender), _amount - fee);
        emit Withdraw(_user, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(
        address _user,
        uint256 _pid
    ) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(_user, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe LWTF transfer function, just in case if rounding error causes pool to not have enough LWTFs.
    function safeLWTFTransfer(address _to, uint256 _amount) internal {
        require(address(lwtf) != address(0), "WTF token not set!");
        uint256 balance = lwtf.balanceOf(address(this));
        if (_amount > balance) {
            lwtf.transfer(_to, balance);
        } else {
            lwtf.transfer(_to, _amount);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
