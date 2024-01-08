// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.5;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./KokoToken.sol";

contract KOKOFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 entryTimestamp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of KOKOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accKOKOPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accKOKOPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. KOKOs to distribute per block.
        uint256 lastRewardBlock; // Last block number that KOKOs distribution occurs.
        uint256 accKOKOPerShare; // Accumulated KOKOs per share, times 1e12.
    }
    // The KOKO TOKEN!
    KokoToken public koko;
    // Dev address.
    address public devaddr;
    // Block number when bonus KOKO period ends.
    uint256 public bonusEndBlock;
    // KOKO tokens created per block.
    uint256 public kokoPerBlock;
    // Bonus muliplier for early koko makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // store pending KOKOs
    mapping(address => uint256) public pendingKokoes;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when KOKO mining starts.
    uint256 public startBlock;
    // the time period at which the users should be able to unlock
    uint256 public lockPeriod;
    // stableccoin fees accumulated
    uint256 public feesAccumulated;
    // mapping of allowed pool tokens
    mapping(IERC20 => bool) public supportedPools;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        address _devaddr,
        uint256 _kokoPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _lockPeriod
    ) {
        require(_devaddr != address(0), "zero address");
        devaddr = _devaddr;
        kokoPerBlock = _kokoPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        lockPeriod = _lockPeriod;
    }

    modifier validatePool(uint256 _pid) {
        require(_pid < poolInfo.length, "farm: pool do not exists");
        _;
    }

    // function to get number of users in the pool
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.

    function checkPoolDuplicate(IERC20 _lpToken) public {
        require(supportedPools[_lpToken] == false, "add: existing pool?");
    }

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        checkPoolDuplicate(_lpToken);
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accKOKOPerShare: 0
            })
        );
        supportedPools[_lpToken] = true;
    }

    // Update the given pool's KOKO allocation point. Can only be called by the owner.
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

    // View function to see pending KOKOs on frontend.
    function pendingKOKO(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accKOKOPerShare = pool.accKOKOPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 kokoReward =
                multiplier.mul(kokoPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accKOKOPerShare = accKOKOPerShare.add(
                kokoReward.mul(1e12).div(lpSupply)
            );
        }
        uint256 pending = user.amount.mul(accKOKOPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(pendingKokoes[_user]);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePool(_pid) {
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
        uint256 kokoReward =
            multiplier.mul(kokoPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accKOKOPerShare = pool.accKOKOPerShare.add(
            kokoReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;

        // koko.mint(address(this), kokoReward);
    }

    // Deposit LP tokens to KOKOFarm for KOKO allocation.
    function deposit(uint256 _pid, uint256 _amount) public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accKOKOPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            // store pending Koko
            pendingKokoes[msg.sender] = pendingKokoes[msg.sender].add(pending);
        }

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accKOKOPerShare).div(1e12);
        user.entryTimestamp = block.timestamp;

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from KOKOFarm.
    function withdraw(uint256 _pid, uint256 _amount)  public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        // check if the time period has been passed
        require(
            block.timestamp >= user.entryTimestamp.add(lockPeriod),
            "Lock period is not passed yet"
        );
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accKOKOPerShare).div(1e12).sub(
                user.rewardDebt
            );

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accKOKOPerShare).div(1e12);

        safeKOKOTransfer(msg.sender, pending.add(pendingKokoes[msg.sender]));
        pendingKokoes[msg.sender] = 0;
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amt = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amt);

        emit EmergencyWithdraw(msg.sender, _pid, amt);
    }

    // Safe koko transfer function, just in case if rounding error causes pool to not have enough KOKOs.
    function safeKOKOTransfer(address _to, uint256 _amount) internal {
        uint256 kokoBal = koko.balanceOf(address(this));
        if (_amount > kokoBal) {
            koko.transfer(_to, kokoBal);
        } else {
            koko.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function addKokoAddress(address _kokoTokenAddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        require(address(koko) == address(0), "already added");
        koko = KokoToken(_kokoTokenAddr);

    }

    function changeLockPeriod(uint256 _newLockPeriod) public {
        require(msg.sender == devaddr, "dev: wut?");
        lockPeriod = _newLockPeriod;
    }

    function changeFeesAccumulated(uint256 _newFees) public {
        require(msg.sender == devaddr, "dev: wut?");
        feesAccumulated = _newFees;
    }
}
