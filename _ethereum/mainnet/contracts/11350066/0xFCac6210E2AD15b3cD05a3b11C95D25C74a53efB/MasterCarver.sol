// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./CarveToken.sol";

import "./console.sol";

interface IMigrator {
    // Perform LP token migration from legacy UniswapV2 to CarveSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // CarveSwap must mint EXACTLY the same amount of CarveSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterCarver is the master of Carve.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CARVE is sufficiently
// distributed and the community can show to govern itself.
//
contract MasterCarver is Ownable, ReentrancyGuard {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CARVE
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCarvePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCarvePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CARVE to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CARVE distribution occurs.
        uint256 accCarvePerShare; // Accumulated CARVE per share, times 1e12. See below.
    }

    // The CARVE TOKEN
    CarveToken public carve;
    // Dev address.
    address public treasuryAddress;
    // Staking reward pool address.
    address public rewardPoolAddress;
    // Reward pool fee
    uint256 public rewardPoolFee;
    // Block number when bonus CARVE period ends.
    uint256 public bonusEndBlock;
    // CARVE tokens created per block.
    uint256 public carvePerBlock;
    // Bonus muliplier for early carve makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when CARVE mining starts.
    uint256 public startBlock;
    // Control whether contracts can make deposits
    bool public acceptContractDepositor = false;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claimed(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier onlyTreasury() {
        require(treasuryAddress == _msgSender(), "not treasury");
        _;
    }

    modifier checkContract() {
        if (!acceptContractDepositor) {
            // solhint-disable-next-line avoid-tx-origin
            require(!address(msg.sender).isContract() && msg.sender == tx.origin, "contracts-not-allowed");
        }
        _;
    }

    constructor(
        CarveToken carve_,
        address rewardPoolAddress_,
        address treasuryAddress_,
        uint256 carvePerBlock_,
        uint256 startBlock_,
        uint256 bonusEndBlock_
    ) {
        carve = carve_;
        rewardPoolAddress = rewardPoolAddress_;
        treasuryAddress = treasuryAddress_;
        carvePerBlock = carvePerBlock_;
        bonusEndBlock = bonusEndBlock_;
        startBlock = startBlock_;
        rewardPoolFee = 15; // 1.5%
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Sets whether deposits can be made from contracts
     * @param acceptContractDepositor_ true or false
     */
    function setAcceptContractDepositor(bool acceptContractDepositor_) external onlyOwner {
        acceptContractDepositor = acceptContractDepositor_;
    }

    /**
     * @notice Sets the staking reward pool
     * @param rewardPoolAddress_ address where rewards are sent
     */
    function setRewardPool(address rewardPoolAddress_) external onlyOwner {
        rewardPoolAddress = rewardPoolAddress_;
    }

    /**
     * @notice Sets the claim fee percentage. Maximum of 5%.
     * @param rewardPoolFee_ percentage using decimal base of 1000 ie: 10% = 100
     */
    function setRewardPoolFee(uint256 rewardPoolFee_) external onlyOwner {
        require(rewardPoolFee_ <= 50, "invalid fee value");
        rewardPoolFee = rewardPoolFee_;
    }

    /**
     * @notice Sets the rewards per block
     * @param rewardPerBlock the amount of rewards minted per block
     */
    function setRewardPerBlock(uint256 rewardPerBlock) external onlyOwner {
        massUpdatePools();
        carvePerBlock = rewardPerBlock;
    }

    /**
     * @notice Update treasury address by the previous treasury.
     * @param treasuryAddress_ the new treasury address
     */
    function updateTreasuryAddress(address treasuryAddress_) external onlyTreasury {
        treasuryAddress = treasuryAddress_;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 allocPoint, IERC20 lpToken) external onlyOwner {
        massUpdatePools();
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: lpToken,
            allocPoint: allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCarvePerShare: 0
        }));
    }

    // Update the given pool's CARVE allocation point. Can only be called by the owner.
    function set(uint256 pid, uint256 allocPoint) external onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid].allocPoint).add(allocPoint);
        poolInfo[pid].allocPoint = allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigrator _migrator) external onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to) public view returns (uint256) {
        if (to <= bonusEndBlock) {
            return to.sub(from).mul(BONUS_MULTIPLIER);
        } else if (from >= bonusEndBlock) {
            return to.sub(from);
        } else {
            return bonusEndBlock.sub(from).mul(BONUS_MULTIPLIER).add(
                to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending CARVE on frontend.
    function pendingCarve(uint256 pid_, address user_) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid_];
        UserInfo storage user = userInfo[pid_][user_];
        uint256 accCarvePerShare = pool.accCarvePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 carveReward = multiplier.mul(carvePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCarvePerShare = accCarvePerShare.add(carveReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCarvePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 carveReward = multiplier.mul(carvePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        carve.mint(treasuryAddress, carveReward.div(10));
        carve.mint(address(this), carveReward);
        pool.accCarvePerShare = pool.accCarvePerShare.add(carveReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterCarver for CARVE allocation.
    function deposit(uint256 pid, uint256 amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        if (user.amount > 0) {
            _claim(pid);
        }
        if (amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), amount);
            user.amount = user.amount.add(amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCarvePerShare).div(1e12);
        emit Deposit(msg.sender, pid, amount);
    }

    // Withdraw LP tokens from MasterCarver.
    function withdraw(uint256 pid, uint256 amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amount, "withdraw: not good");
        updatePool(pid);
        _claim(pid);

        if (amount > 0) {
            user.amount = user.amount.sub(amount);
            pool.lpToken.safeTransfer(address(msg.sender), amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCarvePerShare).div(1e12);
        emit Withdraw(msg.sender, pid, amount);
    }

    // Claim rewards from pool
    function claim(uint256 pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        _claim(pid);
        user.rewardDebt = user.amount.mul(pool.accCarvePerShare).div(1e12);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, pid, amount);
    }

    // This function allows owner to take unsupported tokens out of the contract, since this pool exists longer than the other pools.
    // This is in an effort to make someone whole, should they seriously mess up.
    // It also allows for removal of airdropped tokens.
    function recoverUnsupported(IERC20 token, uint256 amount, address to) external onlyOwner {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            // cant take staked asset
            require(token != pool.lpToken, "!pool.lpToken");
        }
        // transfer to
        token.safeTransfer(to, amount);
    }

    // Claim rewards from pool
    function _claim(uint256 pid) internal {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 pending = user.amount.mul(pool.accCarvePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            uint256 fee = pending.mul(rewardPoolFee).div(1000);
            _safeCarveTransfer(msg.sender, pending.sub(fee));
            _safeCarveTransfer(rewardPoolAddress, fee);
            emit Claimed(msg.sender, pid, pending);
        }
    }

    // Safe carve transfer function, just in case if rounding error causes pool to not have enough CARVE.
    function _safeCarveTransfer(address to, uint256 amount) internal {
        uint256 carveBal = carve.balanceOf(address(this));
        if (amount > carveBal) {
            carve.transfer(to, carveBal);
        } else {
            carve.transfer(to, amount);
        }
    }
}