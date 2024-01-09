// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV3CrossPoolOracle.sol";
import "./IGStakingVault.sol";
import "./Mintable.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapPoolV3.sol";
import "./IUniswapV3Factory.sol";
import "./SqrtPriceMath.sol";
import "./LiquidityMath.sol";
import "./TickMath.sol";

contract GStakingManager is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint64 private constant ACCUMULATED_MULTIPLIER = 1e12;
    // keccak256("BIG_GUARDIAN_ROLE")
    bytes32 public constant BIG_GUARDIAN_ROLE = 0x05c653944982f4fec5b037dad255d4ecd85c5b85ea2ec7654def404ae5f686ec;
    // keccak256("GUARDIAN_ROLE")
    bytes32 public constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;
    // keccak256("MINTER_ROLE")
    bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;

    uint256 public constant USDC_THRESHOLD = 1000 * 10**6;
    uint256 public constant SILVER_PIVOT = 50 days;
    uint256 public constant GOLD_PIVOT = 100 days;
    uint256 public constant MAX_FAUCET = 50;
    uint256 public constant PERCENT = 10000;

    // Reward of each user.
    struct RewardInfo {
        mapping(StakeType => uint256) rewardDebt; // Reward debt. See explanation below.
        uint256 pendingReward; // Reward but not harvest
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 rewardToken;
        mapping(StakeType => uint256) totalReward;
        uint256 openTime;
        uint256 closeTime;
        mapping(StakeType => uint256) lastRewardSecond; // Last block number that rewards distribution occurs.
        mapping(StakeType => uint256) accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
        uint128 chainId;
        PoolType poolType;
    }

    struct StakeInfo {
        //for gpool
        uint256 amount;
        uint256 startStake; // start stake time
        // for nft
        uint256 nftInGpoolAmount;
    }

    struct SetTierParam {
        address account;
        Tier tier;
    }

    struct LockedReward {
        address rewardToken;
        uint256 amount;
    }

    struct NFTInfo {
        address pool;
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
    }

    enum Tier {
        NORANK,
        BRONZE,
        SILVER,
        GOLD
    }

    enum PoolType {
        CLAIMABLE,
        REWARD_CALC
    }

    enum StakeType {
        GPOOL,
        NFT
    }

    // locking Amount if withdraw earlier
    mapping(uint256 => mapping(address => LockedReward)) public lockingAmounts;
    mapping(address => bool) public hadStake;

    mapping(address => StakeInfo) public stakeInfo;
    // Info of each pool reward
    mapping(uint256 => mapping(address => RewardInfo)) public rewardInfo;
    // Classify pools into CLAIMABLE AND REWARD_CALC
    mapping(PoolType => uint256[]) public poolTypes;
    //when you requestTokens address and blocktime+1 day is saved in Time Lock
    mapping(address => uint256) public lockTime;

    //nft record
    //address user => tokenId => value.
    mapping(address => mapping(uint256 => uint256)) public nftRecords;

    PoolInfo[] public poolInfo;

    uint256 public totalGpoolStaked;
    uint256 public totalNFTStaked; // calculate by gpool
    uint32 public twapPeriod;
    uint256 public gpoolRewardPercent = 5000;

    uint256 public firstStakingFee; //eth
    address payable public feeTo;

    // oracle state
    IERC20 public gpoolToken;

    address public weth;
    IERC20 public usdc;
    IGStakingVault public vault;
    IUniswapV3CrossPoolOracle public oracle;
    INonfungiblePositionManager public positionManager;
    IUniswapV3Factory public uniswapFactory;

    event Stake(address sender, uint256 amount, uint256 startStake);
    event StakeNFT(address sender, uint256 tokenId, uint256 amount, uint256 startStake);
    event Unstake(address sender, uint256 amount, uint256 startStake);
    event UnstakeNFT(address sender, uint256 tokenId, uint256 amount, uint256 startStake);
    event ClaimLockedReward(address sender, uint256 poolId, uint256 amount);
    event ClaimReward(address sender, uint256 poolId, uint256 amount);
    event CreatePool(uint256 poolId, PoolType poolType, uint128 chainId, address rewardToken, uint256 totalReward, uint256 openTime, uint256 closeTime);
    event UpdatePoolReward(uint256 poolId, uint256 amountReward);
    event UpdatePoolRewardRate(uint256 oldRate, uint256 newRate);
    event UpdatePoolTime(uint256 poolId, uint256 startTime, uint256 endTime);
    event SetTier(address account, Tier tier, uint256 startStake);
    event VaultUpdated(address oldVault, address newVault);
    event UpdateFirstStakingFee(uint256 _fee, address payable _feeTo);

    /**
     * @notice Validate pool by pool ID
     * @param pid id of the pool
     */
    modifier validatePoolById(uint256 pid) {
        require(pid < poolInfo.length, "StakingPool: pool is not exist");
        _;
    }

    constructor(
        IGStakingVault _vault,
        IUniswapV3CrossPoolOracle _oracle,
        IERC20 _gpoolToken,
        IERC20 _usdc,
        address _weth,
        INonfungiblePositionManager _positionManager,
        IUniswapV3Factory _uniswapFactory,
        address payable _feeTo,
        uint256 _firstStakingFee,
        address[] memory _admins
    ) {
        vault = _vault;
        oracle = _oracle;
        gpoolToken = _gpoolToken;
        usdc = _usdc;
        weth = _weth;
        positionManager = _positionManager;
        uniswapFactory = _uniswapFactory;
        twapPeriod = 1;
        firstStakingFee = _firstStakingFee;
        feeTo = _feeTo;

        for (uint256 i = 0; i < _admins.length; ++i) {
            _setupRole(GUARDIAN_ROLE, _admins[i]);
        }

        _setRoleAdmin(GUARDIAN_ROLE, BIG_GUARDIAN_ROLE);
        _setupRole(GUARDIAN_ROLE, msg.sender);
        _setupRole(BIG_GUARDIAN_ROLE, msg.sender);
    }

    function transferBigGuardian(address _newGuardian) public onlyRole(BIG_GUARDIAN_ROLE) {
        require(_newGuardian != address(0) && _newGuardian != msg.sender, "Invalid new guardian");
        renounceRole(BIG_GUARDIAN_ROLE, msg.sender);
        _setupRole(BIG_GUARDIAN_ROLE, _newGuardian);
    }

    function updateVaultAddress(address _vault) public onlyRole(BIG_GUARDIAN_ROLE) {
        require(_vault != address(0), "Vault address is invalid");
        require(_vault != address(vault), "Vault address is exactly the same");

        emit VaultUpdated(address(vault), _vault);
        vault = IGStakingVault(_vault);
    }

    /**
     * @notice allow users to call the requestTokens function to mint tokens
     * @param amount amount to min, in ether format
     */
    function requestTokens(uint256 amount) external {
        ERC20Mintable gptoken = ERC20Mintable(address(gpoolToken));

        require(amount <= MAX_FAUCET, "Can faucet max 50 token per time");
        //perform a few check to make sure function can execute
        require(block.timestamp > lockTime[msg.sender], "lock time has not expired. Please try again later");

        //set role minter
        _setupRole(MINTER_ROLE, msg.sender);

        //mint tokens
        gptoken.mint(msg.sender, amount);

        //updates locktime 1 day from now
        lockTime[msg.sender] = block.timestamp + 1 days;
    }

    function getTotalStake(StakeType stakeType) public view returns (uint256) {
        return stakeType == StakeType.GPOOL ? totalGpoolStaked : totalNFTStaked;
    }

    /**
     * @notice stake gpool to manager.
     * @param amount amount to stake
     */
    function stake(uint256 amount) external payable nonReentrant {
        require(gpoolToken.balanceOf(msg.sender) >= amount, "not enough gpool");
        _getStakeFeeIfNeed(msg.value, msg.sender);
        StakeInfo storage staker = stakeInfo[msg.sender];
        require(
            gpoolInUSDC(staker.amount + amount + staker.nftInGpoolAmount) >= USDC_THRESHOLD,
            "minimum stake does not match"
        );

        gpoolToken.safeTransferFrom(msg.sender, address(this), amount);
        if (staker.startStake == 0) {
            staker.startStake = block.timestamp;
        }

        StakeType stakeType = StakeType.GPOOL;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            if (block.timestamp <= pool.openTime) {
                continue;
            }

            RewardInfo storage user = rewardInfo[pid][msg.sender];
            updatePool(pid, stakeType);
            uint256 pending = ((staker.amount * pool.accRewardPerShare[stakeType]) / ACCUMULATED_MULTIPLIER) -
                user.rewardDebt[stakeType];
            user.pendingReward = user.pendingReward + pending;
            user.rewardDebt[stakeType] =
                ((staker.amount + amount) * pool.accRewardPerShare[stakeType]) /
                ACCUMULATED_MULTIPLIER;
        }

        staker.amount += amount;
        totalGpoolStaked += amount;

        emit Stake(msg.sender, amount, staker.startStake);
    }

    function stakeNFT(uint256 tokenId) public payable nonReentrant {
        _getStakeFeeIfNeed(msg.value, msg.sender);
        StakeInfo storage staker = stakeInfo[msg.sender];
        NFTInfo memory ntfInfo = getAmountFromTokenId(tokenId);
        uint256 amout0InGpool = (ntfInfo.token0 == address(gpoolToken))
            ? ntfInfo.amount0
            : tokenInGpool(ntfInfo.token0, ntfInfo.amount0);
        uint256 amout1InGpool = (ntfInfo.token1 == address(gpoolToken))
            ? ntfInfo.amount1
            : tokenInGpool(ntfInfo.token1, ntfInfo.amount1);
        uint256 amount = amout0InGpool + amout1InGpool;
        require(
            gpoolInUSDC(staker.amount + amount + staker.nftInGpoolAmount) >= USDC_THRESHOLD,
            "minimum stake does not match"
        );

        positionManager.transferFrom(msg.sender, address(this), tokenId);

        if (staker.startStake == 0) {
            staker.startStake = block.timestamp;
        }

        StakeType stakeType = StakeType.NFT;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            if (block.timestamp <= pool.openTime) {
                continue;
            }

            RewardInfo storage user = rewardInfo[pid][msg.sender];
            updatePool(pid, stakeType);
            uint256 pending = ((staker.nftInGpoolAmount * pool.accRewardPerShare[stakeType]) / ACCUMULATED_MULTIPLIER) -
                user.rewardDebt[stakeType];
            user.pendingReward = user.pendingReward + pending;
            user.rewardDebt[stakeType] =
                ((staker.nftInGpoolAmount + amount) * pool.accRewardPerShare[stakeType]) /
                ACCUMULATED_MULTIPLIER;
        }

        staker.nftInGpoolAmount += amount;
        totalNFTStaked += amount;
        nftRecords[msg.sender][tokenId] = amount;

        emit StakeNFT(msg.sender, tokenId, amount, staker.startStake);
    }

    /**
     * @notice unstake Gpool.
     * @param amount amount to withdraw
     */
    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage staker = stakeInfo[msg.sender];
        require(amount <= staker.amount, "not enough balance");

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updateUserReward(pid, amount, StakeType.GPOOL);
        }

        staker.amount -= amount;
        totalGpoolStaked -= amount;
        if (
            (staker.amount + staker.nftInGpoolAmount) == 0 ||
            gpoolInUSDC(staker.amount + staker.nftInGpoolAmount) < USDC_THRESHOLD
        ) {
            staker.startStake = 0;
        } else {
            staker.startStake = block.timestamp;
        }

        gpoolToken.safeTransfer(msg.sender, amount);
        emit Unstake(msg.sender, amount, staker.startStake);
    }

    /**
     * @notice unstake NFT.
     * @param tokenId amount to withdraw
     */
    function unstakeNFT(uint256 tokenId) external nonReentrant {
        StakeInfo storage staker = stakeInfo[msg.sender];
        uint256 amount = nftRecords[msg.sender][tokenId];
        require(amount > 0, "invalid tokenId");

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updateUserReward(pid, amount, StakeType.NFT);
        }

        staker.nftInGpoolAmount -= amount;
        totalNFTStaked -= amount;
        if (
            (staker.amount + staker.nftInGpoolAmount) == 0 ||
            gpoolInUSDC(staker.amount + staker.nftInGpoolAmount) < USDC_THRESHOLD
        ) {
            staker.startStake = 0;
        } else {
            staker.startStake = block.timestamp;
        }

        nftRecords[msg.sender][tokenId] = 0;
        positionManager.transferFrom(address(this), msg.sender, tokenId);
        emit UnstakeNFT(msg.sender, tokenId, amount, staker.startStake);
    }

    function _getStakeFeeIfNeed(uint256 amount, address user) private {
        if (!hadStake[user]) {
            require(amount == firstStakingFee, "Fee is not valid");
            hadStake[user] = true;
            feeTo.transfer(amount);
        } else {
            require(amount == 0, "Fee only apply in first staking");
        }
    }

    function _updateUserReward(
        uint256 pid,
        uint256 amount,
        StakeType stakeType
    ) internal {
        PoolInfo storage pool = poolInfo[pid];
        if (block.timestamp <= pool.openTime) {
            return;
        }

        RewardInfo storage user = rewardInfo[pid][msg.sender];
        StakeInfo storage staker = stakeInfo[msg.sender];

        uint256 userAmountByType = (stakeType == StakeType.GPOOL) ? staker.amount : staker.nftInGpoolAmount;

        updatePool(pid, stakeType);
        uint256 pending = ((userAmountByType * pool.accRewardPerShare[stakeType]) / ACCUMULATED_MULTIPLIER) -
            user.rewardDebt[stakeType];
        if (pending > 0) {
            user.pendingReward = user.pendingReward + pending;
        }
        user.rewardDebt[stakeType] =
            ((userAmountByType - amount) * pool.accRewardPerShare[stakeType]) /
            ACCUMULATED_MULTIPLIER;
    }

    function claimLockedReward(uint256 pid) public validatePoolById(pid) returns (uint256) {
        require(getTier(msg.sender) == Tier.GOLD, "Be gold to claim!");

        LockedReward memory lockedReward = lockingAmounts[pid][msg.sender];
        require(lockedReward.amount > 0, "Nothing to claim!");

        vault.claimReward(address(lockedReward.rewardToken), msg.sender, lockedReward.amount);

        emit ClaimLockedReward(msg.sender, pid, lockedReward.amount);
        delete lockingAmounts[pid][msg.sender];

        return lockedReward.amount;
    }

    /**
     * @notice Harvest proceeds msg.sender
     * @param pid id of the pool
     */
    function claimReward(uint256 pid) public validatePoolById(pid) returns (uint256) {
        Tier userTier = getTier(msg.sender);

        require(getTier(msg.sender) != Tier.NORANK, "only tier");
        require(
            gpoolInUSDC(stakeInfo[msg.sender].amount + stakeInfo[msg.sender].nftInGpoolAmount) >= USDC_THRESHOLD,
            "minimum stake does not match"
        );
        PoolInfo storage pool = poolInfo[pid];

        require(pool.poolType == PoolType.CLAIMABLE, "Not able to claim from reward_calc pool!");

        if (block.timestamp <= pool.openTime) {
            return 0;
        }

        updatePool(pid, StakeType.GPOOL);
        updatePool(pid, StakeType.NFT);

        RewardInfo storage user = rewardInfo[pid][msg.sender];
        StakeInfo storage staker = stakeInfo[msg.sender];
        LockedReward memory lockedReward = lockingAmounts[pid][msg.sender];

        uint256 totalPending = pendingReward(pid, msg.sender);
        user.pendingReward = 0;
        user.rewardDebt[StakeType.GPOOL] =
            (staker.amount * pool.accRewardPerShare[StakeType.GPOOL]) /
            (ACCUMULATED_MULTIPLIER);
        user.rewardDebt[StakeType.NFT] =
            (staker.nftInGpoolAmount * pool.accRewardPerShare[StakeType.NFT]) /
            (ACCUMULATED_MULTIPLIER);

        if (totalPending > 0) {
            uint256 rewardByTier = (totalPending * uint256(userTier)) / uint256(Tier.GOLD);
            uint256 lockedAmount = totalPending - rewardByTier;

            _lockUserReward(msg.sender, pid, lockedAmount);

            vault.claimReward(address(pool.rewardToken), msg.sender, rewardByTier);

            totalPending = rewardByTier;
        }

        if (userTier == Tier.GOLD && lockedReward.amount > 0) {
            vault.claimReward(address(pool.rewardToken), msg.sender, lockedReward.amount);

            emit ClaimLockedReward(msg.sender, pid, lockedReward.amount);
            delete lockingAmounts[pid][msg.sender];
        }

        emit ClaimReward(msg.sender, pid, totalPending);
        return totalPending;
    }

    /**
     * @notice Harvest proceeds of all pools for msg.sender
     * @param pids ids of the pools
     */
    function claimAll(uint256[] memory pids) external {
        uint256 length = pids.length;
        for (uint256 i = 0; i < length; ++i) {
            claimReward(pids[i]);
        }
    }

    /**
     * @notice View function to see pending rewards on frontend.
     * @param pid id of the pool
     * @param userAddress the address of the user
     */
    function pendingReward(uint256 pid, address userAddress) public view validatePoolById(pid) returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        RewardInfo storage user = rewardInfo[pid][userAddress];
        StakeInfo memory staker = stakeInfo[userAddress];

        uint256 accRewardPerShareGpool = pool.accRewardPerShare[StakeType.GPOOL];
        uint256 accRewardPerShareNFT = pool.accRewardPerShare[StakeType.NFT];
        uint256 endTime = pool.closeTime < block.timestamp ? pool.closeTime : block.timestamp;

        // gpool
        if (endTime > pool.lastRewardSecond[StakeType.GPOOL] && totalGpoolStaked != 0) {
            uint256 poolReward = (pool.totalReward[StakeType.GPOOL] *
                (endTime - pool.lastRewardSecond[StakeType.GPOOL])) / (pool.closeTime - pool.openTime);
            accRewardPerShareGpool = (accRewardPerShareGpool +
                ((poolReward * ACCUMULATED_MULTIPLIER) / totalGpoolStaked));
        }

        // nft
        if (endTime > pool.lastRewardSecond[StakeType.NFT] && totalNFTStaked != 0) {
            uint256 poolReward = (pool.totalReward[StakeType.NFT] * (endTime - pool.lastRewardSecond[StakeType.NFT])) /
                (pool.closeTime - pool.openTime);
            accRewardPerShareNFT = (accRewardPerShareNFT + ((poolReward * ACCUMULATED_MULTIPLIER) / totalNFTStaked));
        }

        uint256 totalUserDebt = user.rewardDebt[StakeType.NFT] + user.rewardDebt[StakeType.GPOOL];

        uint256 totalPendingReward = (user.pendingReward +
            (((staker.amount * accRewardPerShareGpool + staker.nftInGpoolAmount * accRewardPerShareNFT) /
                ACCUMULATED_MULTIPLIER) - totalUserDebt));
        return totalPendingReward;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param pid id of the pool
     */
    function updatePool(uint256 pid, StakeType stakeType) public validatePoolById(pid) {
        PoolInfo storage pool = poolInfo[pid];
        uint256 endTime = pool.closeTime < block.timestamp ? pool.closeTime : block.timestamp;
        if (endTime <= pool.lastRewardSecond[stakeType]) {
            return;
        }
        uint256 totalStake = getTotalStake(stakeType);
        if (totalStake == 0) {
            pool.lastRewardSecond[stakeType] = endTime;
            return;
        }
        uint256 poolReward = (pool.totalReward[stakeType] * (endTime - pool.lastRewardSecond[stakeType])) /
            (pool.closeTime - pool.openTime);
        uint256 deltaRewardPerShare = (poolReward * ACCUMULATED_MULTIPLIER) / totalStake;
        if (deltaRewardPerShare == 0 && block.timestamp < pool.closeTime) {
            // wait for delta > 0
            return;
        }
        pool.accRewardPerShare[stakeType] = pool.accRewardPerShare[stakeType] + deltaRewardPerShare;
        pool.lastRewardSecond[stakeType] = endTime;
    }

    /**
     * @notice Update reward vairables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid, StakeType.GPOOL);
            updatePool(pid, StakeType.NFT);
        }
    }

    // create new pool reward
    function createPool(
        IERC20 rewardToken,
        uint256 totalReward,
        uint256 openTime,
        uint256 closeTime,
        PoolType poolType,
        uint128 chainId
    ) external onlyRole(GUARDIAN_ROLE) {
        require(block.timestamp <= openTime, "only future");
        require(closeTime > openTime, "invalid time");
        require(totalReward > 0, "invalid totalReward");
        massUpdatePools();

        if (poolType == PoolType.CLAIMABLE) {
            require(rewardToken.balanceOf(msg.sender) >= totalReward, "not enough token balance");
            rewardToken.safeTransferFrom(msg.sender, address(vault), totalReward);
        }

        poolInfo.push();
        PoolInfo storage pool = poolInfo[poolInfo.length - 1];

        pool.rewardToken = rewardToken;
        pool.totalReward[StakeType.GPOOL] = (totalReward * gpoolRewardPercent) / PERCENT;
        pool.totalReward[StakeType.NFT] = totalReward - pool.totalReward[StakeType.GPOOL];
        pool.openTime = openTime;
        pool.closeTime = closeTime;
        pool.lastRewardSecond[StakeType.GPOOL] = openTime;
        pool.lastRewardSecond[StakeType.NFT] = openTime;
        pool.poolType = poolType;
        pool.chainId = chainId;

        uint256 pid = poolInfo.length - 1;
        poolTypes[poolType].push(pid);

        emit CreatePool(pid, poolType, chainId, address(rewardToken), totalReward, openTime, closeTime);
    }

    // update startTime, endTime of pool
    function updatePoolTime(
        uint256 pid,
        uint256 startTime,
        uint256 endTime
    ) external onlyRole(GUARDIAN_ROLE) validatePoolById(pid) {
        PoolInfo storage pool = poolInfo[pid];
        require(pool.openTime > block.timestamp, "pool started");
        require(block.timestamp <= startTime, "only future");
        require(endTime > startTime, "invalid time");

        pool.openTime = startTime;
        pool.closeTime = endTime;
        pool.lastRewardSecond[StakeType.GPOOL] = startTime;
        pool.lastRewardSecond[StakeType.NFT] = startTime;
        emit UpdatePoolTime(pid, startTime, endTime);
    }

    // update total Reward of pool
    function updatePoolReward(uint256 pid, uint256 amountReward)
        external
        onlyRole(GUARDIAN_ROLE)
        validatePoolById(pid)
    {
        PoolInfo storage pool = poolInfo[pid];
        require(pool.openTime > block.timestamp, "pool started");
        require(amountReward > 0, "invalid totalReward");

        uint256 oldTotalReward = pool.totalReward[StakeType.NFT] + pool.totalReward[StakeType.GPOOL];
        pool.totalReward[StakeType.GPOOL] = (amountReward * gpoolRewardPercent) / PERCENT;
        pool.totalReward[StakeType.NFT] = amountReward - pool.totalReward[StakeType.GPOOL];

        if (pool.poolType == PoolType.CLAIMABLE) {
            if (amountReward > oldTotalReward) {
                pool.rewardToken.safeTransferFrom(msg.sender, address(vault), amountReward - oldTotalReward);
            } else if (amountReward < oldTotalReward) {
                vault.claimReward(address(pool.rewardToken), msg.sender, oldTotalReward - amountReward);
            }
        }

        emit UpdatePoolReward(pid, amountReward);
    }

    function updatePoolRewardRate(uint256 _gpoolRewardPercent) public onlyRole(GUARDIAN_ROLE) {
        require(_gpoolRewardPercent <= PERCENT, "Rate is not valid");
        uint256 oldRate = gpoolRewardPercent;
        gpoolRewardPercent = _gpoolRewardPercent;
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            if (block.timestamp >= pool.openTime) {
                continue;
            }
            uint256 totalRewardByPool = pool.totalReward[StakeType.NFT] + pool.totalReward[StakeType.GPOOL];
            pool.totalReward[StakeType.GPOOL] = (totalRewardByPool * gpoolRewardPercent) / PERCENT;
            pool.totalReward[StakeType.NFT] = totalRewardByPool - pool.totalReward[StakeType.GPOOL];
        }
        emit UpdatePoolRewardRate(oldRate, _gpoolRewardPercent);
    }

    function updateFirstStakingFee(uint256 _fee, address payable _feeTo) public onlyRole(GUARDIAN_ROLE) {
        feeTo = _feeTo;
        firstStakingFee = _fee;
        emit UpdateFirstStakingFee(_fee, _feeTo);
    }

    // gpoolInUSDC
    // convert gpool to usdc value
    function gpoolInUSDC(uint256 gpoolAmount) public view returns (uint256) {
        // twap is in second
        return oracle.assetToAsset(address(gpoolToken), gpoolAmount, address(usdc), twapPeriod);
    }

    function tokenInGpool(address token, uint256 amount) public view returns (uint256) {
        // twap is in second
        return oracle.assetToAsset(address(token), amount, address(gpoolToken), twapPeriod);
    }

    // getTier: user's gpass
    function getTier(address user) public view returns (Tier) {
        StakeInfo memory staker = stakeInfo[user];
        if (staker.startStake == 0) {
            return Tier.NORANK;
        }

        if (block.timestamp <= staker.startStake + SILVER_PIVOT) {
            return Tier.BRONZE;
        }

        if (block.timestamp <= staker.startStake + GOLD_PIVOT) {
            return Tier.SILVER;
        }

        return Tier.GOLD;
    }

    function setTwapPeriod(uint32 _twapPeriod) external onlyRole(GUARDIAN_ROLE) {
        twapPeriod = _twapPeriod;
    }

    function setTiers(SetTierParam[] calldata params) external onlyRole(GUARDIAN_ROLE) {
        uint256 length = params.length;
        for (uint256 i = 0; i < length; ++i) {
            StakeInfo storage staker = stakeInfo[params[i].account];
            uint256 startStake = 0;
            if (params[i].tier == Tier.GOLD) {
                startStake = block.timestamp - GOLD_PIVOT - 1;
            } else if (params[i].tier == Tier.SILVER) {
                startStake = block.timestamp - SILVER_PIVOT - 1;
            } else if (params[i].tier == Tier.BRONZE) {
                startStake = block.timestamp - 1;
            }
            staker.startStake = startStake;
            emit SetTier(params[i].account, params[i].tier, startStake);
        }
    }

    // admin can withdraw reward token
    function withdrawReward(IERC20 token, uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        require(token != gpoolToken, "only reward token");
        token.safeTransfer(msg.sender, amount);
    }

    function _lockUserReward(
        address _user,
        uint256 _poolId,
        uint256 _lockedAmount
    ) internal {
        if (_lockedAmount > 0) {
            PoolInfo storage pool = poolInfo[_poolId];
            LockedReward memory userLockedReward = lockingAmounts[_poolId][_user];

            uint256 updatedLockingAmount = userLockedReward.amount + _lockedAmount;
            lockingAmounts[_poolId][_user] = LockedReward(address(pool.rewardToken), updatedLockingAmount);
        }
    }

    // for nft
    function getUniswapPoolInfo(uint256 tokenId) internal view returns (NFTInfo memory info) {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = positionManager.positions(tokenId);
        info.pool = uniswapFactory.getPool(token0, token1, fee);
        info.tickLower = tickLower;
        info.tickUpper = tickUpper;
        info.liquidity = liquidity;
        info.token0 = token0;
        info.token1 = token1;
    }

    function getAmountFromTokenId(uint256 tokenId) public view returns (NFTInfo memory) {
        NFTInfo memory nftInfo = getUniswapPoolInfo(tokenId);
        require(_isValidToken(nftInfo.token0, nftInfo.token1), "NFT: Wrong NFT type");
        int24 tickLower = nftInfo.tickLower;
        int24 tickUpper = nftInfo.tickUpper;
        uint128 liquidityDelta = nftInfo.liquidity;
        IUniswapPoolV3 uniswapPool = IUniswapPoolV3(nftInfo.pool);
        IUniswapPoolV3.Slot0 memory slot = uniswapPool.slot0();
        uint128 liquidity = uniswapPool.liquidity();

        if (slot.tick < tickLower) {
            // current tick is below the passed range; liquidity can only become in range by crossing from left to
            // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
            nftInfo.amount0 = SqrtPriceMath.getAmount0DeltaV2(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidityDelta,
                true
            );
        } else if (slot.tick < tickUpper) {
            // current tick is inside the passed range
            uint128 liquidityBefore = liquidity; // SLOAD for gas optimization

            nftInfo.amount0 = SqrtPriceMath.getAmount0DeltaV2(
                slot.sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidityDelta,
                true
            );
            nftInfo.amount1 = SqrtPriceMath.getAmount1DeltaV2(
                TickMath.getSqrtRatioAtTick(tickLower),
                slot.sqrtPriceX96,
                liquidityDelta,
                true
            );

            liquidity = LiquidityMath.addDelta(liquidityBefore, liquidityDelta);
        } else {
            // current tick is above the passed range; liquidity can only become in range by crossing from right to
            // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
            nftInfo.amount1 = SqrtPriceMath.getAmount1DeltaV2(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidityDelta,
                true
            );
        }

        return nftInfo;
    }

    function _isValidToken(address token0, address token1) private view returns (bool) {
        if ((token0 == weth && token1 == address(gpoolToken)) || (token1 == weth && token0 == address(gpoolToken))) {
            return true;
        }
        return false;
    }
}
