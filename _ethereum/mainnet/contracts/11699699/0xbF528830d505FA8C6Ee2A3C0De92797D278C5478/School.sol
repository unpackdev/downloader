// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./NarwhaleToken.sol";


contract School is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of NAWAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accNarwhalePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accNarwhalePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. NAWAs to distribute per block.
        uint256 lastRewardBlock; // Last block number that NAWAs distribution occurs.
        uint256 accNarwhalePerShare; // Accumulated NAWAs per share, times 1e12. See below.
    }

    // The NAWA TOKEN!
    NarwhaleToken public narwhale;
    // Dev fund (10%, initially)
    uint256 public devFundDivRate = 10;
    // Dev address.
    address public devaddr;
    // Block number when bonus NAWA period ends.
    uint256 public bonusEndBlock;
    // NAWA tokens created per block.
    uint256 public narwhalePerBlock;
    // Bonus muliplier for early narwhale makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when NAWA mining starts.
    uint256 public startBlock;

    // Events
    event Recovered(address token, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionChange(address indexed user, uint256 previousNarwhalePerBlock, uint256 newNarwhalePerBlock);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        NarwhaleToken _narwhale,
        address _devaddr,
        uint256 _narwhalePerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        narwhale = _narwhale;
        devaddr = _devaddr;
        narwhalePerBlock = _narwhalePerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
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
                accNarwhalePerShare: 0
            })
        );
    }

    // Update the given pool's NAWA allocation point. Can only be called by the owner.
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
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending NAWAs on frontend.
    function pendingNarwhale(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNarwhalePerShare = pool.accNarwhalePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 narwhaleReward = multiplier
                .mul(narwhalePerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accNarwhalePerShare = accNarwhalePerShare.add(
                narwhaleReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accNarwhalePerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 narwhaleReward = multiplier
            .mul(narwhalePerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        narwhale.mint(devaddr, narwhaleReward.div(devFundDivRate));
        narwhale.mint(address(this), narwhaleReward);
        pool.accNarwhalePerShare = pool.accNarwhalePerShare.add(
            narwhaleReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to School for NAWA allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accNarwhalePerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeNarwhaleTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accNarwhalePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from School.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accNarwhalePerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeNarwhaleTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accNarwhalePerShare).div(1e12);
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
    }

    // Safe narwhale transfer function, just in case if rounding error causes pool to not have enough NAWAs.
    function safeNarwhaleTransfer(address _to, uint256 _amount) internal {
        uint256 narwhaleBal = narwhale.balanceOf(address(this));
        if (_amount > narwhaleBal) {
            narwhale.transfer(_to, narwhaleBal);
        } else {
            narwhale.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // **** Additional functions separate from the original Masterchef contract ****

    function setNarwhalePerBlock(uint256 _narwhalePerBlock) public onlyOwner {
        require(_narwhalePerBlock > 0, "!narwhalePerBlock-0");
        uint256 previousNarwhalePerBlock = narwhalePerBlock;
        narwhalePerBlock = _narwhalePerBlock;
        emit EmissionChange(msg.sender, previousNarwhalePerBlock, narwhalePerBlock);
    }

    function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }

    function setDevFundDivRate(uint256 _devFundDivRate) public onlyOwner {
        require(_devFundDivRate > 0 && _devFundDivRate <= 10, "!devFundDivRate-0");
        devFundDivRate = _devFundDivRate;
    }
}
