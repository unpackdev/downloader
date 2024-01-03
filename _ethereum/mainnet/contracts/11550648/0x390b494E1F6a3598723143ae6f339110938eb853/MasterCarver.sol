// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./CarveToken.sol";
import "./ChiGasSaver.sol";

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
// The ownership will be transferred to a governance smart contract once CARVE
// is sufficiently distributed and the community can show to govern itself.
//
contract MasterCarver is Ownable, ReentrancyGuard, ChiGasSaver {
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
    // Reward updater
    address public rewardUpdater;
    // Staking reward pool address.
    address public rewardPoolAddress;
    // Reward pool fee
    uint256 public rewardPoolFee;
    // CARVE tokens created per block.
    uint256 public carvePerBlock;
    // Percentage referrers get when farmer claims
    uint256 public referralCommissionPercent = 10; // 1%
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Keep track of which pools exist already
    mapping (address => bool) public poolMap;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Map of farmer to referrer
    mapping (address => address) public referralMap;
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

    modifier onlyRewardUpdater() {
        require(rewardUpdater == _msgSender(), "not reward updater");
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
        uint256 startBlock_
    ) {
        carve = carve_;
        rewardPoolAddress = rewardPoolAddress_;
        treasuryAddress = treasuryAddress_;
        rewardUpdater = _msgSender();
        carvePerBlock = carvePerBlock_;
        startBlock = startBlock_;
        rewardPoolFee = 15; // 1.5%
    }

    /// Return the number of pools
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
     * @notice Sets the reward updater address
     * @param rewardUpdaterAddress_ address where rewards are sent
     */
    function setRewardUpdater(address rewardUpdaterAddress_) external onlyRewardUpdater {
        rewardUpdater = rewardUpdaterAddress_;
    }

    /**
     * @notice Sets the staking reward pool
     * @param rewardPoolAddress_ address where rewards are sent
     */
    function setRewardPool(address rewardPoolAddress_) external onlyRewardUpdater {
        rewardPoolAddress = rewardPoolAddress_;
    }

    /**
     * @notice Sets the claim fee percentage. Maximum of 5%.
     * @param rewardPoolFee_ percentage using decimal base of 1000 ie: 10% = 100
     */
    function setRewardPoolFee(uint256 rewardPoolFee_) external onlyRewardUpdater {
        require(rewardPoolFee_ <= 50, "invalid fee value");
        rewardPoolFee = rewardPoolFee_;
    }

    /**
     * @notice Sets the rewards per block
     * @param rewardPerBlock amount of rewards minted per block
     */
    function setRewardPerBlock(uint256 rewardPerBlock) external onlyRewardUpdater {
        massUpdatePools();
        carvePerBlock = rewardPerBlock;
    }

    /**
     * @notice Sets referral commission
     * @param referralCommissionPercent_ percentage using decimal base of 1000 ie: 1% = 10
     */
    function setReferralCommission(uint256 referralCommissionPercent_) external onlyRewardUpdater {
        referralCommissionPercent = referralCommissionPercent_;
    }

    /**
     * @notice Update treasury address by the previous treasury.
     * @param treasuryAddress_ new treasury address
     */
    function updateTreasuryAddress(address treasuryAddress_) external onlyTreasury {
        treasuryAddress = treasuryAddress_;
    }

    /**
     * @notice Set the migrator contract
     * @param migrator_ address of migration contract
     */
    function setMigrator(IMigrator migrator_) external onlyOwner {
        migrator = migrator_;
    }

    /**
     * @notice Add a new LP to the farm
     * @param allocPoint reward allocation
     * @param lpToken ERC20 LP token
     */
    function add(uint256 allocPoint, IERC20 lpToken, uint8 flag) external onlyOwner saveGas(flag) {
        address tokenAddress = address(lpToken);
        require(!poolMap[tokenAddress], "pool-already-exists");
        require(_isERC20(tokenAddress), "lp-token-not-erc20");
        massUpdatePools();
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: lpToken,
            allocPoint: allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCarvePerShare: 0
        }));
        poolMap[address(lpToken)] = true;
    }

    /**
     * @notice Update the given pool's CARVE allocation point
     * @param pid pool index
     * @param allocPoint reward allocation
     */
    function set(uint256 pid, uint256 allocPoint, uint8 flag) external onlyOwner saveGas(flag) {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid].allocPoint).add(allocPoint);
        poolInfo[pid].allocPoint = allocPoint;
    }

    /**
     * @notice Migrate LP token to another LP contract. Can be called by anyone. We trust that migrator contract is good.
     * @param pid pool index
     */
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

    /**
     * @notice View function to see pending CARVE on frontend.
     * @param pid pool index
     * @param user_ user to lookup
     */
    function pendingCarve(uint256 pid, address user_) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][user_];
        uint256 accCarvePerShare = pool.accCarvePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
            uint256 carveReward = multiplier.mul(carvePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCarvePerShare = accCarvePerShare.add(carveReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCarvePerShare).div(1e12).sub(user.rewardDebt);
    }

    /// Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param pid pool index
     */
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
        uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
        uint256 carveReward = multiplier.mul(carvePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        _safeCarveMint(address(this), carveReward);
        _safeCarveMint(treasuryAddress, carveReward.div(10));
        pool.accCarvePerShare = pool.accCarvePerShare.add(carveReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice Deposit LP tokens. Pending rewards are claimed.
     * @param pid pool index
     * @param amount amount of LP tokens to deposit
     */
    function deposit(uint256 pid, uint256 amount, address referrer, uint8 flag) external checkContract nonReentrant saveGas(flag) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        if (referrer != address(0)) {
            require(referrer != msg.sender, "cannot refer yourself");
            referralMap[msg.sender] = referrer;
        }
        if (user.amount > 0) {
            _claim(pid);
        }
        if (amount > 0) {
            pool.lpToken.safeTransferFrom(msg.sender, address(this), amount);
            user.amount = user.amount.add(amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCarvePerShare).div(1e12);
        emit Deposit(msg.sender, pid, amount);
    }

    /**
     * @notice Withdraw LP tokens. Pending rewards are claimed.
     * @param pid pool index
     * @param amount amount of LP tokens to withdraw
     */
    function withdraw(uint256 pid, uint256 amount, uint8 flag) external nonReentrant saveGas(flag) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amount, "withdraw: not good");
        updatePool(pid);
        _claim(pid);

        if (amount > 0) {
            user.amount = user.amount.sub(amount);
            pool.lpToken.safeTransfer(msg.sender, amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCarvePerShare).div(1e12);
        emit Withdraw(msg.sender, pid, amount);
    }

    /**
     * @notice Claim rewards from pool
     * @param pid pool index
     */
    function claim(uint256 pid, uint8 flag) external nonReentrant saveGas(flag) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        _claim(pid);
        user.rewardDebt = user.amount.mul(pool.accCarvePerShare).div(1e12);
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param pid pool index
     */
    function emergencyWithdraw(uint256 pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount);
    }


    /**
     * @notice This function allows owner to take unsupported tokens out of the contract, since this pool exists longer than the other pools.
     * This is in an effort to make someone whole, should they seriously mess up.
     * It also allows for removal of airdropped tokens.
     */
    function recoverUnsupported(IERC20 token, uint256 amount, address to) external onlyOwner {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            // can't take staked asset
            require(token != pool.lpToken, "!pool.lpToken");
        }
        token.safeTransfer(to, amount);
    }

    /// Claim rewards from pool
    function _claim(uint256 pid) internal {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 pending = user.amount.mul(pool.accCarvePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            uint256 fee = pending.mul(rewardPoolFee).div(1000);

            address referrer = referralMap[msg.sender];
            if (referrer != address(0)) {
                uint256 commission = pending.mul(referralCommissionPercent).div(1000);
                _safeCarveTransfer(referrer, commission);
                pending = pending.sub(commission);
            }

            pending = pending.sub(fee);
            _safeCarveTransfer(msg.sender, pending);
            _safeCarveTransfer(rewardPoolAddress, fee);
            emit Claimed(msg.sender, pid, pending);
        }
    }

    /**
     * @notice Safe CARVE mint to ensure we cannot mint over cap
     */
    function _safeCarveMint(address to, uint256 amount) internal {
        if (to != address(0)) {
            uint256 totalSupply = carve.totalSupply();
            uint256 cap = carve.CAP();
            if (totalSupply.add(amount) > cap) {
                carve.mint(to, cap.sub(totalSupply));
            } else {
                carve.mint(to, amount);
            }
        }
    }

    /**
     * @notice Safe carve transfer function, just in case if rounding error causes pool to not have enough CARVE.
     */
    function _safeCarveTransfer(address to, uint256 amount) internal {
        uint256 carveBal = carve.balanceOf(address(this));
        if (amount > carveBal) {
            carve.transfer(to, carveBal);
        } else {
            carve.transfer(to, amount);
        }
    }

    /**
     * @notice Return reward multiplier over the given `from` to `to` block.
     * @param from start of block range
     * @param to end of block range
     */
    function _getMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        return to.sub(from);
    }

    /**
     * @notice Simple check to see if address looks like ERC20
     * @param target address to check
     */
    function _isERC20(address target) internal view returns (bool) {
        bytes memory selector = abi.encodeWithSelector(bytes4(keccak256("balanceOf(address)")), msg.sender);
        (bool success,) = target.staticcall(selector);
        if (!success) {
            return false;
        }
        selector = abi.encodeWithSelector(bytes4(keccak256("totalSupply()")));
        (success,) = target.staticcall(selector);
        return success;
    }
}