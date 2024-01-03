// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";

interface IMigratorConsole {
    // XXXSwap means any swap inherit from uniswap
    // Perform LP token migration from legacy XXXSwap to JoySwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // Migrator must have allowance access to XXXSwap LP tokens.
    // JoySwap must mint EXACTLY the same amount of JoySwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// GameConsole is the controller of Joys. He can make Joys and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract JOYS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract GameConsole is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Joys
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accJoysPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accJoysPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Joys to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Joys distribution occurs.
        uint256 accJoysPerShare; // Accumulated Joys per share, times 1e12. See below.
    }

    // The JOYS TOKEN!
    IERC20 public joys;

    // Address of weth token contract.
    IERC20 public weth;

    // Address of wethLp token contract.
    address public wethLp;

    // JoysVesting contract address
    address public joysVesting;

    // Block number when bonus JOYS period ends.
    uint256 public bonusBeginBlock;
    uint256 public bonusEndBlock;

    // block per day
    uint256 public constant BLOCK_PER_DAY = 6100;

    //  1-12 16
    // 13-24 8
    // 25-36 4
    // 37-48 2
    // Bonus muliplier for early joys makers times 10.
    uint256 public constant BONUS_MULTIPLIER_16 = 160;
    uint256 public constant BONUS_MULTIPLIER_8 = 80;
    uint256 public constant BONUS_MULTIPLIER_4 = 40;
    uint256 public constant BONUS_MULTIPLIER_2 = 20;

    // mined 48 days
    uint256 public constant MINED_DAYS = 48;

    // continue days per every mine stage
    uint256 public constant CONTINUE_DAYS_PER_STAGE = 12;

    struct PeriodInfo {
        uint256 begin;
        uint256 end;
        uint256 multiplier;
    }
    PeriodInfo[] public periodInfo;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorConsole public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Track all added pools to prevent adding the same pool more then once.
    mapping(address => bool) public lpTokenExistsInPool;

    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // default min miner
    uint256 public constant DEFAULT_WETH = 100;
    uint256 public constant MAX_WETH = 1000;
    uint256 public constant JOYS_PER_BLOCK_STEP = 80;
    uint256 public constant MAX_JOYS_PER_BLOCK = 800;
    uint256 public lastWETHAmount;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor (
        IERC20 _joys,
        IERC20 _weth,
        address _vesting
    ) public {
        joys = _joys;
        weth = _weth;
        joysVesting = _vesting;
        bonusBeginBlock = block.number;
        bonusEndBlock = bonusBeginBlock + BLOCK_PER_DAY * MINED_DAYS;
        lastWETHAmount = 0;

        uint256 multiplier = BONUS_MULTIPLIER_16;
        uint256 currentBlock = bonusBeginBlock;
        uint256 lastBlock = currentBlock;
        for (; currentBlock < bonusEndBlock; currentBlock += CONTINUE_DAYS_PER_STAGE*BLOCK_PER_DAY) {
            periodInfo.push(PeriodInfo({
                begin: lastBlock,
                end: currentBlock + CONTINUE_DAYS_PER_STAGE*BLOCK_PER_DAY,
                multiplier: multiplier
            }));

            lastBlock = currentBlock + CONTINUE_DAYS_PER_STAGE*BLOCK_PER_DAY + 1;
            multiplier = multiplier.div(2);
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate, bool _withWethLp) public onlyOwner {
        require(!lpTokenExistsInPool[address(_lpToken)], "GameConsole: LP Token Address already exists in pool");
        if (_withUpdate) {
            massUpdatePools();
        }
        if (_withWethLp) {
            wethLp = address(_lpToken);
        }
        uint256 lastRewardBlock = block.number > bonusBeginBlock? block.number : bonusBeginBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accJoysPerShare: 0
        }));
        lpTokenExistsInPool[address(_lpToken)] = true;
    }

    // Update the given pool's JOYS allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function setWethLp(address _wethLp) public onlyOwner {
        require(_wethLp != address(0), "GameConsole: Invalid address.");
        wethLp = _wethLp;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorConsole _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract.
    // Can be called by anyone.
    // We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(!lpTokenExistsInPool[address(newLpToken)],"MasterChef: New LP Token Address already exists in pool");
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
        lpTokenExistsInPool[address(newLpToken)] = true;
    }

    // Return reward over the given _from to _to block.
    function getReward(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 totalReward;
        for (uint256 i = 0; i < periodInfo.length; ++i) {
            if (_to <= periodInfo[i].end) {
                if (i == 0) {
                    totalReward = totalReward.add(_to.sub(_from).mul(periodInfo[i].multiplier));
                    break;
                } else {
                    uint256 dest = periodInfo[i].begin;
                    if (_from > periodInfo[i].begin) {
                        dest = _from;
                    }
                    totalReward = totalReward.add(_to.sub(dest).mul(periodInfo[i].multiplier));
                    break;
                }
            } else if (_from >= periodInfo[i].end) {
                continue;
            } else {
                totalReward = totalReward.add(periodInfo[i].end.sub(_from).mul(periodInfo[i].multiplier));
                _from = periodInfo[i].end;
            }
        }

        // minersInfo multi times 10
        return totalReward.mul(1e17);
    }

    // View function to see pending JOYS on frontend.
    function pendingJoys(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accJoysPerShare = pool.accJoysPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 joysReward = getReward(pool.lastRewardBlock, block.number).mul(pool.allocPoint).div(totalAllocPoint);
            accJoysPerShare = accJoysPerShare.add(joysReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accJoysPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 joysReward = getReward(pool.lastRewardBlock, block.number).mul(pool.allocPoint).div(totalAllocPoint);
        joys.transfer(joysVesting, joysReward.div(10));
        joys.transfer(address(this), joysReward);
        pool.accJoysPerShare= pool.accJoysPerShare.add(joysReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function updatePeriod() public {
        if (lastWETHAmount >= MAX_WETH) {
            return;
        }

        uint256 amount = weth.balanceOf(wethLp).div(1e18);
        if (amount < lastWETHAmount || amount < lastWETHAmount.add(DEFAULT_WETH)) {
            return;
        }

        uint256 delt = amount.sub(lastWETHAmount).div(DEFAULT_WETH);

        // update last eth amount
        lastWETHAmount = amount;

        for (uint256 i = 0; i < periodInfo.length; ++i) {
            periodInfo[i].multiplier = periodInfo[i].multiplier.add(delt.mul(JOYS_PER_BLOCK_STEP));
            if (periodInfo[i].multiplier > MAX_JOYS_PER_BLOCK) {
                periodInfo[i].multiplier = MAX_JOYS_PER_BLOCK;
            }
        }
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accJoysPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeJoysTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            updatePeriod();
        }
        user.rewardDebt = user.amount.mul(pool.accJoysPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accJoysPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeJoysTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accJoysPerShare).div(1e12);
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

    // Safe joys transfer function, just in case if rounding error causes pool to not have enough JOYS.
    function safeJoysTransfer(address _to, uint256 _amount) internal {
        uint256 joysBal = joys.balanceOf(address(this));
        if (_amount > joysBal) {
            joys.transfer(_to, joysBal);
        } else {
            joys.transfer(_to, _amount);
        }
    }

    function recycleJoysToken(address _address) public onlyOwner {
        require(_address != address(0), "JoysLottery:Invalid address");
        require(joys.balanceOf(address(this)) > 0, "JoysLottery:no JOYS");
        joys.transfer(_address, joys.balanceOf(address(this)));
    }
}
