// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.5;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ChilliToken.sol";

contract CHILLIFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 entryTimestamp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of CHILLIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCHILLIPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCHILLIPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CHILLIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that CHILLIs distribution occurs.
        uint256 accCHILLIPerShare; // Accumulated CHILLIs per share, times 1e12.
    }
    // The CHILLI TOKEN!
    ChilliToken public chilli;
    // Dev address.
    address public devaddr;
    // Block number when bonus CHILLI period ends.
    uint256 public bonusEndBlock;
    // CHILLI tokens created per block.
    uint256 public chilliPerBlock;
    // Bonus muliplier for early chilli makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // store pending CHILLIs
    mapping(address => uint256) public pendingChillies;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CHILLI mining starts.
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
        uint256 _chilliPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _lockPeriod
    ) {
        require(_devaddr != address(0), "zero address");
        devaddr = _devaddr;
        chilliPerBlock = _chilliPerBlock;
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
                accCHILLIPerShare: 0
            })
        );
        supportedPools[_lpToken] = true;
    }

    // Update the given pool's CHILLI allocation point. Can only be called by the owner.
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

    // View function to see pending CHILLIs on frontend.
    function pendingCHILLI(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCHILLIPerShare = pool.accCHILLIPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 chilliReward =
                multiplier.mul(chilliPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accCHILLIPerShare = accCHILLIPerShare.add(
                chilliReward.mul(1e12).div(lpSupply)
            );
        }
        uint256 pending = user.amount.mul(accCHILLIPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(pendingChillies[_user]);
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
        uint256 chilliReward =
            multiplier.mul(chilliPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accCHILLIPerShare = pool.accCHILLIPerShare.add(
            chilliReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;

        // chilli.mint(address(this), chilliReward);
    }

    // Deposit LP tokens to CHILLIFarm for CHILLI allocation.
    function deposit(uint256 _pid, uint256 _amount) public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accCHILLIPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            // store pending Chilli
            pendingChillies[msg.sender] = pendingChillies[msg.sender].add(pending);
        }

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accCHILLIPerShare).div(1e12);
        user.entryTimestamp = block.timestamp;

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from CHILLIFarm.
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
            user.amount.mul(pool.accCHILLIPerShare).div(1e12).sub(
                user.rewardDebt
            );

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accCHILLIPerShare).div(1e12);

        safeCHILLITransfer(msg.sender, pending.add(pendingChillies[msg.sender]));
        pendingChillies[msg.sender] = 0;
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

    // Safe chilli transfer function, just in case if rounding error causes pool to not have enough CHILLIs.
    function safeCHILLITransfer(address _to, uint256 _amount) internal {
        uint256 chilliBal = chilli.balanceOf(address(this));
        if (_amount > chilliBal) {
            chilli.transfer(_to, chilliBal);
        } else {
            chilli.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function addChilliAddress(address _chilliTokenAddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        require(address(chilli) == address(0), "already added");
        chilli = ChilliToken(_chilliTokenAddr);

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
