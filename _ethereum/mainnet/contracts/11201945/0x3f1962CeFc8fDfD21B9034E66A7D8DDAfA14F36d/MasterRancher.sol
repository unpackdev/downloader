//SPDX-License-Identifier: SEE LICENSE FILE
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./AlpacaToken.sol";
import "./IStakingRewards.sol";

interface IMigratorRancher {
    // Perform LP token migration from legacy UniswapV2 to AlpacaSwap's omnipool
    // LP tokens are nullified to 0 during migration so no additional deposit will
    // be allowed after domestication. Only deposit of ALP is allowed.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // Migrator must have allowance access to UniswapV2 LP tokens. In the world of AlpacaSwap,
    // all Uniswaps are wild Alpacas that need to be domesticated. Once the liquidity farming
    // period is over, we domesticate those pools and establish alpaca ranch.
    function domesticate(IERC20 orig)
        external
        returns (
            bool result,
            uint256 index,
            uint256 lpSupply
        );

    function establishRanch() external returns (IERC20 alp);

    function retrieveShares(uint256 index) external returns (uint256 shares);

    function establishTokenSetting() external;

    function liquidateNonalpaca(address token) external;

    function startRanch(
        address _feeTo,
        uint256 _feeToPct,
        address _exitFeeTo,
        uint256 _exitFee,
        address _payOutToken,
        address _controller
    ) external;
}

// MasterRancher is the master of the alpaca farm.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once PACA is sufficiently
// distributed and the community can show to govern itself.
//
// Enjoy!
contract MasterRancher is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PACAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPacaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPacaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. PACAs to distribute per block.
        uint256 lastRewardBlock;    // Last block number that PACAs distribution occurs.
        uint256 accPacaPerShare;    // Accumulated PACAs per share, times 1e12. See below.
        uint256 index;
        uint256 lpSupply;
        address stakingPool;        // UNI staking pool. If none is available, set to address(0). MUST be address(0) for ALPs.
    }

    // The PACA TOKEN!
    AlpacaToken public paca;

    // Dev address.
    address public devaddr;
    // Dev share of PACA
    uint256 public devPctInv = 12;

    // UNI address for collecting rewards
    address public uniaddr;

    // Block number when bonus PACA period ends.
    uint256 public bonusEndBlock;
    // PACA tokens created per block.
    uint256 public pacaPerBlock;
    // Bonus muliplier for early alpaca farmers
    uint256 public bonusMultiplier = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorRancher public migrator;
    // ALP LP token
    IERC20 alp;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Withdraw lock
    bool public withdrawLock;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PACA mining starts.
    uint256 public startBlock;

    bool public ranchEstablished;

    bool public operationPaused;

    uint256 public ranchPid;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Redeem(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPerBlockUpdated(uint256 blockNum, uint256 amount);
    event RanchFinalized(uint256 ranchPid);
    event MintedPACA(uint256 blockNum, uint256 amount);
    constructor(
        AlpacaToken _paca,
        address _devaddr,
        uint256 _pacaPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        bool _withdrawLock
    ) public {
        paca = _paca;
        devaddr = _devaddr;
        pacaPerBlock = _pacaPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        withdrawLock = _withdrawLock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // MUST ADD TOKENS THAT WILL BE PART OF THE OMNIPOOL, MIGRATOR WILL NOT CHECK FOR SHITCOIN
    // Keeping it open after ranch est allows us to migrate to a new CRP if something blows up
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate,
        address _stakingPool
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
                accPacaPerShare: 0,
                index: 5000, //just a random number for now
                lpSupply: 0,
                stakingPool: _stakingPool
            })
        );
        // Approve MAX amount upfront for staking in UNI pool
        if (_stakingPool != address(0)) {
            _lpToken.safeApprove(_stakingPool, uint(-1));
        }
    }

    // Maintain backwards compatability with add() that does not have stakingPool param
    // Defaults to stakingPool = address(0), i.e. no staking will be done
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        add(_allocPoint, _lpToken, _withUpdate, address(0));
    }

    // Update the given pool's PACA allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        require(ranchEstablished == false, "dont touch my alpaca");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function updateRewardsPerBlock(uint256 rewardPerBlock) public onlyOwner {
        massUpdatePools();
        pacaPerBlock = rewardPerBlock;
        emit RewardPerBlockUpdated(block.number, pacaPerBlock);
    }

    //
    // Update reward variables for all pools. Be careful of gas spending!
    function finalizeShares() public onlyOwner {
        require(operationPaused == true, "pause operation first");
        uint256 length = poolInfo.length;
        uint256 legacyTotalAllocPoint = totalAllocPoint;
        totalAllocPoint = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 pacaReward;
            if (block.number <= pool.lastRewardBlock) {
                continue;
            }
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            //we need to do last round of reward updates because migration is an async operation
            if (pool.lpSupply == 0) {
                pool.lastRewardBlock = block.number;
                continue;
            }
            pacaReward = multiplier.mul(pacaPerBlock).mul(pool.allocPoint).div(
                legacyTotalAllocPoint
            );

            // Calculate split of reward between dev and pool holders
            uint256 devReward = pacaReward.div(devPctInv);
            uint256 poolReward = pacaReward.sub(devReward);
            paca.mint(devaddr, devReward);
            paca.mint(address(this), poolReward);

            pool.accPacaPerShare = pool.accPacaPerShare.add(poolReward.mul(1e12).div(pool.lpSupply));

            // After migration, each pool will maintain shares in the ALP until they are redeemed via redeem
            // allocPoint is updated to shares
            pool.allocPoint = migrator.retrieveShares(pool.index);
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
            //update last reward block to the current block. there might be slippage
            //during ranch establishment which is OK.
            pool.lastRewardBlock = block.number;
        }
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorRancher _migrator) public onlyOwner {
        migrator = _migrator;
    }
    function requestToMint(uint256 _amount) external returns (uint256) {
        require(msg.sender == address(migrator), "wut?");
        require(operationPaused == true, "pause the contract first");
        require(ranchEstablished == false, "dont touch my alpaca");
        paca.mint(address(migrator), _amount);
        emit MintedPACA(block.number, _amount);
        return _amount;
    }
    // The migration process is an async operation for AlpacaSwap so only can be called by the owner.
    // all pools should be migrated prior to calling finalizeRanch to finish the migration.
    // pauseOperation -> call migrate on all pools -> finalize ranch -> boom!
    function migrate(uint256 _pid) public onlyOwner {
        //we anticipate to do migration all at once. Pause all other operations.
        require(operationPaused == true, "pause the contract first");
        require(ranchEstablished == false, "dont touch my alpaca");
        require(address(migrator) != address(0), "migrate: no migrator");
        bool result = false;
        uint256 index;
        uint256 lp;
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;

        // unstake any LP tokens earning UNI
        if (pool.stakingPool != address(0)) {
            IStakingRewards usp = IStakingRewards(pool.stakingPool);
            usp.exit();
        }

        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        (result, index, lp) = migrator.domesticate(lpToken);
        require(result == true, "alpacas ran away");
        pool.lpToken = IERC20(0);
        pool.index = index;
        pool.lpSupply = lp;
    }

    // set UNI address
    function setUNI(address _uniAddress) public onlyOwner {
        uniaddr = _uniAddress;
    }

    // send UNI to the glue factory
    function liquidateUNI() public onlyOwner {
        IERC20 uniToken = IERC20(uniaddr);
        uint bal = uniToken.balanceOf(address(this));
        uniToken.safeTransfer(address(migrator), bal);
        migrator.liquidateNonalpaca(uniaddr);
    }

    function pauseOperation() public onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        require(ranchEstablished == false, "dont touch my alpaca");
        //from the moment this function is invoked, all deposit/withdraws are disabled.
        //It is expected that the ranch must be formed shortly.
        operationPaused = true;
    }

    function establishTokenSetting() external onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        require(ranchEstablished == false, "dont touch my alpaca");
        require(operationPaused == true, "pause the contract first");

        migrator.establishTokenSetting();
    }

    function establishRanch() external onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        require(ranchEstablished == false, "dont touch my alpaca");
        require(operationPaused == true, "pause the contract first");
        //only should be called AFTER all swaps are migrated, its not reversible once the ranch is established
        //call

        alp = migrator.establishRanch();
    }

    function finalizeRanch(
        address _feeTo,
        uint256 _feeToPct,
        address _exitFeeTo,
        uint256 _exitFee,
        address _payOutToken
    ) external onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        require(ranchEstablished == false, "dont touch my alpaca");
        require(operationPaused == true, "pause the contract first");

        finalizeShares();

        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;

        // Add AlpacaPool to the list of pools to allow people to deposit their ALPs to earn PACA
        poolInfo.push(
            PoolInfo({
                lpToken: alp,
                allocPoint: 0,
                lastRewardBlock: lastRewardBlock,
                accPacaPerShare: 0,
                index: 5000, //random number.
                lpSupply: 0,
                stakingPool: address(0)
            })
        );
        ranchPid = poolInfo.length - 1;

        migrator.startRanch(
            _feeTo,
            _feeToPct,
            _exitFeeTo,
            _exitFee,
            _payOutToken,
            devaddr
        );
        ranchEstablished = true;
        operationPaused = false;
        // withdraws are always opened after migration
        withdrawLock = false;

        emit RanchFinalized(ranchPid);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonusMultiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(bonusMultiplier).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending PACAs on frontend.
    function pendingPaca(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        require(operationPaused == false, "establishing ranch, relax");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPacaPerShare = pool.accPacaPerShare;
        uint256 lpSupply;
        if (ranchEstablished == true) {
            if (_pid == ranchPid) {
                lpSupply = pool.allocPoint;
            } else {
                lpSupply = pool.lpSupply;
            }
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
            // also account for staked LP tokens
            if (pool.stakingPool != address(0)) {
                IStakingRewards usp = IStakingRewards(pool.stakingPool);
                lpSupply = lpSupply.add(usp.balanceOf(address(this)));
            }
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 pacaReward = multiplier
                .mul(pacaPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            uint256 devReward = pacaReward.div(devPctInv);
            uint256 poolReward = pacaReward.sub(devReward);
            accPacaPerShare = accPacaPerShare.add(
                poolReward.mul(1e12).div(lpSupply)
            );
        }

        return user.amount.mul(accPacaPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        require(operationPaused == false, "establishing ranch, relax");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        require(
            operationPaused == false || msg.sender == owner(),
            "establishing ranch, relax"
        );
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (ranchEstablished == true) {
            if (_pid == ranchPid) {
                lpSupply = totalAllocPoint;
            } else {
                lpSupply = pool.lpSupply;
            }
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
            // also account for staked LP tokens
            if (pool.stakingPool != address(0)) {
                IStakingRewards usp = IStakingRewards(pool.stakingPool);
                lpSupply = lpSupply.add(usp.balanceOf(address(this)));
            }
        }
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 pacaReward = multiplier
            .mul(pacaPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        // Divvy up the PACA reward between pool and devs
        // Fix Chef's bad math
        // dev + pool = total
        // pct = dev / (dev + pool)
        // dev = pool / (1/pct - 1)
        // dev = pct * total
        // pool = total * (1 - pct)
        // paca.mint(devaddr, pacaReward.div(9));
        // paca.mint(address(this), pacaReward);
        // uint256 devPctInv = 11;
        uint256 devReward = pacaReward.div(devPctInv);
        uint256 poolReward = pacaReward.sub(devReward);
        paca.mint(devaddr, devReward);
        paca.mint(address(this), poolReward);
        // pool.accPacaPerShare = pool.accPacaPerShare.add(pacaReward.mul(1e12).div(lpSupply));
        pool.accPacaPerShare = pool.accPacaPerShare.add(poolReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterRanch for PACA allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require(operationPaused == false, "establishing ranch, relax");
        require(_pid < poolInfo.length, "learn how array works");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accPacaPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safePacaTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            // if they try to deposit pools beside ALP past migration this won't work and will be reverted
            // since pool.lpToken is set to IERC20(0) in migrate()
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            // stake _amount to UNI pool to earn $$
            if (pool.stakingPool != address(0)) {
                IStakingRewards usp = IStakingRewards(pool.stakingPool);
                usp.stake(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accPacaPerShare).div(1e12);

        // If depositing ALP shares to earn PACA after migration
        if (ranchEstablished == true) {
            totalAllocPoint = totalAllocPoint.add(_amount);
            pool.allocPoint = pool.allocPoint.add(_amount);
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterRancher.
    function withdraw(uint256 _pid, uint256 _amount) public {
        // If someone wants to withdraw before, they give up their PACA and use emergencyWithdraw()
        require(operationPaused == false, "establishing ranch, relax");
        if (ranchEstablished == true) {
            require(_pid == ranchPid, "use redemption for legacy withdrawal");
        }
        if (_amount > 0) {
            require(!withdrawLock, "withdrawals not allowed, pls wait for migration");
        }
        // if (ranchEstablished == false && _amount > 0) {
        //     require(false, "wait until migration");
        // }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPacaPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safePacaTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            // unstake _amount from UNI pool
            if (pool.stakingPool != address(0)) {
                IStakingRewards usp = IStakingRewards(pool.stakingPool);
                // ensure we don't try to withdraw more than is actually staked (e.g. after an emergency unstake)
                uint256 stakedBalance = usp.balanceOf(address(this));
                uint256 unstakeAmount = _amount;
                if (stakedBalance < _amount) {
                    unstakeAmount = stakedBalance;
                }
                usp.withdraw(unstakeAmount);
            }
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        if (ranchEstablished == true) {
            pool.allocPoint = pool.allocPoint.sub(user.amount);
            totalAllocPoint = totalAllocPoint.sub(user.amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPacaPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Function for Uniswap LP depositers to redeem AlpacaPool LP tokens
    function redeem(uint256 _pid) public {
        require(operationPaused == false, "establishing ranch, relax");
        require(ranchEstablished == true, "use withdraw");
        require(_pid != ranchPid, "use withdraw");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "lol wut?");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPacaPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safePacaTransfer(msg.sender, pending);
        }
        //based on user amount we send back ALP LP tokens.
        uint256 sharesToTransfer = pool.allocPoint.mul(user.amount).div(
            pool.lpSupply
        );
        pool.allocPoint = pool.allocPoint.sub(sharesToTransfer);
        totalAllocPoint = totalAllocPoint.sub(sharesToTransfer);
        poolInfo[ranchPid].lpToken.safeTransfer(
            address(msg.sender),
                sharesToTransfer
        );
        user.rewardDebt = 0;
        pool.lpSupply = pool.lpSupply.sub(user.amount);
        user.amount = 0;
        emit Redeem(msg.sender, _pid, user.amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // Or if you are a rat and want to withdraw before the migration
    function emergencyWithdraw(uint256 _pid) public {
        require(!withdrawLock, "withdrawals not allowed, change via governance");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Unlock contract for withdrawals in an emergency
    function emergencySetWithdrawLock(bool _withdrawLock) public {
        require(msg.sender == devaddr, "dev: wut?");
        require(ranchEstablished == false, "withdraw must be unlocked after migration");
        withdrawLock = _withdrawLock;
    }

    // Unstake all UNI staking pools so the LP tokens can be withdrawn in an emergency
    function emergencyUnstake() public {
        require(msg.sender == devaddr, "dev: wut?");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            // exit (withdraw all) from UNI pool
            if (pool.stakingPool != address(0)) {
                IStakingRewards usp = IStakingRewards(pool.stakingPool);
                usp.exit();
            }
        }
    }

    // Safe PACA transfer function, just in case if rounding error causes pool to not have enough PACAs.
    function safePacaTransfer(address _to, uint256 _amount) internal {
        uint256 pacaBal = paca.balanceOf(address(this));
        if (_amount > pacaBal) {
            paca.transfer(_to, pacaBal);
        } else {
            paca.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }


    function devPctInvUpdate(uint256 _devPctInv) public onlyOwner {
        devPctInv = _devPctInv;
    }
    function bonusMultiplierUpdate(uint256 _bonusMultiplier) public onlyOwner {
        bonusMultiplier = _bonusMultiplier;
    }

}
