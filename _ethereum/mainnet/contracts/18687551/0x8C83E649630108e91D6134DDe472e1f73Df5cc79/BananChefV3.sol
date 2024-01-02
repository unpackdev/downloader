//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣤⣤⣾⣿⣿⣿⣿⣷⣶⣶⣦⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡿⠿⠿⠿⠿⠿⠿⢿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⣴⣶⣶⣶⣶⣦⣤⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢿⣿⣿⡿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣶⣶⣤⣤⣤⣤⣶⣶⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⣿⡉⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣿⡇⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣥⣽⡇⢸⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁⠈⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀
  _  ____    _    _   _    _    _   _    ____ _   _ _____ _____ 
 | || __ )  / \  | \ | |  / \  | \ | |  / ___| | | | ____|  ___|
/ __)  _ \ / _ \ |  \| | / _ \ |  \| | | |   | |_| |  _| | |_   
\__ \ |_) / ___ \| |\  |/ ___ \| |\  | | |___|  _  | |___|  _|  
(   /____/_/   \_\_| \_/_/   \_\_| \_|  \____|_| |_|_____|_|    
 |_|                                                             
                                                                       
Dapp: https://www.jungle-protocol.com/
Telegram: https://t.me/Jungle_Protocol
Twitter: https://twitter.com/Jungle_Protocol                                                                      
 */

import "./Address.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./IRandomizer.sol";
import "./IConfig.sol";
import "./IBanansToken.sol";
import "./IFullProtec.sol";
import "./IStolenPool.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";

contract BananChefV3 is Ownable, ReentrancyGuard {
    //=========================================================================
    // SETUP
    //=========================================================================
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public constant taxFreeRequestId =
        uint256(
            keccak256(abi.encodePacked("BANAN TAX EXEMPT (FOR COMPOUNDING)"))
        ); //kek
    uint256 public constant REWARD_SCALING_FACTOR = 1e12;
    uint256 public constant BANANS_DECIMALS = 1e18;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint224 rewardDebt; // Reward debt. See explanation below.
        uint32 lockEndedTimestamp;
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint128 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint32 lastRewardBlock; // Last block number that Rewards distribution occurs.
        uint96 accRewardPerShare; // Accumulated Rewards per share.
    }

    IConfig public config;

    uint16 public bananClaimTaxRate = 2500; // 25%
    uint16 public fullProtecProtocolLiqProportion = 3200; // "33"%
    uint24 public requestNonce;
    uint40 public startBlock;
    /**
     * @dev scales debase linearly,
     * s.t. 1e13 = 0.001% (~6.7%/day) debase per block,
     * 113 * 1e11 = 0.00113% (~7.5%/day) debase per block
     * 138 * 1e11 =  0.00138% (~9%/day) debase per block
     */
    uint48 public debaseMultiplier = 138 * 1e11;
    uint64 public lastBlock;
    uint16 public constant PERCENTAGE_DENOMINATOR = 10000;

    uint8 public constant blockOffset = 1; //just to keep math safer maybe, so that user cant deposit on "block 0"
    uint88 public bananRewardPerBlock = uint88(4 * BANANS_DECIMALS); //4 banans/block
    uint128 public totalAllocPoint = 0;

    bool public vaultDepositsAreOpen = false; //all vaults closed. (big/smol)
    bool public depositsPaused = false; //for pausing without resetting startblock

    /// @dev Info of each pool.
    PoolInfo[] public poolInfo;
    /// @dev Info of each user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev user's withdrawable rewards
    mapping(uint256 => mapping(address => uint256)) private userRewards;
    /// @dev Lock duration in seconds
    mapping(uint256 => uint256) public lockDurations;

    // Events
    event SetDepositsEnabled(bool enabled);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);
    event TaxPaid(address indexed user, uint256 indexed pid, uint256 amount);
    event SetRewardPerBlock(uint88 amount);
    event LogPoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken
    );
    event SetAllocationPoint(uint256 indexed pid, uint256 allocPoint);
    event PoolUpdated(
        uint256 indexed pid,
        uint256 lastRewardBlock,
        uint256 lpSupply,
        uint256 accRewardPerShare
    );
    event SetLockDuration(uint256 indexed pid, uint256 lockDuration);
    event Claim(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 tax
    );
    event RewardQueued(address _account, uint256 _pid, uint256 pending);
    event Compound(address indexed user, uint256 amountBanan, uint256 poolId);
    event TaxRatioUpdate(address indexed user, uint256 indexed newUserTaxRatio);

    error InvalidAllowance();
    error EOAsOnly();
    error MonkeysPerWalletLimitReached();
    error NoPendingRewards(address user);
    error ForwardFailed();
    error CallerIsNotConfig();
    error VaultsDepositsAreClosed();
    error CallerIsNotAccountOrThisContract();
    error PoolExists();
    error InvalidAmount();
    error StillLocked();

    constructor(address _configManager) ReentrancyGuard() {
        config = IConfig(_configManager);

        IERC20(config.banansAddress()).approve(
            config.bananStolenPoolAddress(),
            type(uint).max
        );

        //default lockDurations
        lockDurations[0] = 5 minutes;
        lockDurations[1] = 5 minutes;
    }

    modifier onlyConfig() {
        if (msg.sender != address(config)) {
            revert CallerIsNotConfig();
        }
        _;
    }

    //=========================================================================
    // ADMIN POOL ACTIONS
    //=========================================================================

    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(
        uint128 _allocPoint,
        address _lpToken,
        bool _withUpdatePools
    ) external onlyOwner {
        if (!lpTokenIsNotAlreadyAdded(_lpToken)) {
            revert PoolExists();
        }
        if (_withUpdatePools) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: IERC20(_lpToken),
                allocPoint: _allocPoint,
                lastRewardBlock: uint32(lastRewardBlock),
                accRewardPerShare: 0
            })
        );

        emit LogPoolAddition(
            poolInfo.length - 1,
            _allocPoint,
            IERC20(_lpToken)
        );
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function lpTokenIsNotAlreadyAdded(
        address _lpToken
    ) internal view returns (bool) {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (address(poolInfo[pid].lpToken) == _lpToken) {
                return false;
            }
        }
        return true;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply;

        if (address(pool.lpToken) == address(0)) {
            return;
        }
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (address(pool.lpToken) == config.banansAddress()) {
            lpSupply = IBanansToken(config.banansAddress()).balanceOfUnderlying(
                address(this)
            );
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }

        if (lpSupply == 0) {
            pool.lastRewardBlock = uint32(block.number);
            return;
        }

        uint256 banansReward = Math.mulDiv(
            block.number - pool.lastRewardBlock,
            bananRewardPerBlock * pool.allocPoint,
            totalAllocPoint
        );

        pool.accRewardPerShare += uint96(
            Math.mulDiv(banansReward, REWARD_SCALING_FACTOR, lpSupply)
        );
        pool.lastRewardBlock = uint32(block.number);

        emit PoolUpdated(
            _pid,
            pool.lastRewardBlock,
            lpSupply,
            pool.accRewardPerShare
        );
    }

    //=========================================================================
    // USER ACTIONS
    //=========================================================================

    /// @dev Deposit tokens to BanansChef for Banans allocation.
    /// @dev 1e18 in 1e24 out
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        if (!vaultDepositsAreOpen || depositsPaused) {
            revert VaultsDepositsAreClosed();
        }

        if (_amount == 0) {
            revert InvalidAmount();
        }

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (pool.lpToken.allowance(msg.sender, address(this)) < _amount) {
            revert InvalidAllowance();
        }

        user.lockEndedTimestamp = uint32(block.timestamp + lockDurations[_pid]);

        updatePool(_pid);
        _queueRewards(_pid, msg.sender);

        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);

        /// @dev 1e18-->1e24
        if (address(pool.lpToken) == config.banansAddress()) {
            _amount = IBanansToken(config.banansAddress()).fragmentToBanans(
                _amount
            );
        }
        /// @dev +n*1e24
        user.amount += _amount;
        user.rewardDebt = uint224(
            Math.mulDiv(
                user.amount,
                pool.accRewardPerShare,
                REWARD_SCALING_FACTOR
            )
        );

        emit Deposit(msg.sender, _pid, _amount);
        emit TaxRatioUpdate(msg.sender, getFullToChefRatio(msg.sender));
    }

    /// @dev Withdraw tokens from BananChef.
    /// @dev 1e24 in 1e18 out
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.lockEndedTimestamp > block.timestamp) {
            revert StillLocked();
        }

        if (_amount > user.amount) {
            revert InvalidAmount();
        }

        updatePool(_pid);
        _queueRewards(_pid, msg.sender);

        //expects 1e24 value
        user.amount -= _amount; //-n*1e24
        user.rewardDebt = uint224(
            (user.amount * pool.accRewardPerShare) / REWARD_SCALING_FACTOR
        );
        user.lockEndedTimestamp =
            uint32(block.timestamp) +
            uint32(lockDurations[_pid]);

        //1e24-->1e18
        if (address(pool.lpToken) == config.banansAddress()) {
            _amount = IBanansToken(config.banansAddress()).banansToFragment(
                _amount
            );
        }

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        emit TaxRatioUpdate(msg.sender, getFullToChefRatio(msg.sender));
    }

    function requestClaim(uint256 _pid) external payable nonReentrant {
        address sender = msg.sender;

        if (sender != tx.origin) {
            revert EOAsOnly();
        }

        updatePool(_pid);
        _queueRewards(_pid, sender);

        if (userRewards[_pid][sender] == 0) {
            revert NoPendingRewards(sender);
        }

        uint256 randomNumber = IRandomizer(config.randomizerAddress())
            .getRandomNumber(sender, block.timestamp, requestNonce);

        (uint256 rewards, uint256 tax) = _claim(
            _pid,
            sender,
            randomNumber,
            requestNonce,
            false
        );
        ++requestNonce;

        emit Claim(sender, _pid, rewards, tax);
    }

    /// @dev claims pending banan rewards in smol protec vault tax-free, then immediately deposits back into smol protec vault
    function compoundSmol() external {
        uint256 _randomNumber = 0;
        (uint256 rewards, ) = _claim(
            1,
            msg.sender,
            _randomNumber,
            taxFreeRequestId,
            true
        );
        deposit(1, rewards);
        emit Compound(msg.sender, rewards, 1);
    }

    //=========================================================================
    // INTERNAL WRITE FUNCTIONS
    //=========================================================================

    /// @dev Claim Banans from BananChef
    function _claim(
        uint256 _pid,
        address _account,
        uint256 _randomNumber,
        uint256 _requestId,
        bool callerIsCompounder
    ) internal returns (uint256, uint256) {
        uint256 tax = 0;

        //to avoid double queueing when calls are made through requestClaim
        if (_requestId == taxFreeRequestId) {
            updatePool(_pid);
            _queueRewards(_pid, _account);
        }

        uint256 pendingRewards = userRewards[_pid][_account];
        if (pendingRewards == 0) {
            revert NoPendingRewards(_account);
        }

        IBanansToken banans = IBanansToken(config.banansAddress());

        UserInfo storage user = userInfo[_pid][_account];
        user.lockEndedTimestamp =
            uint32(block.timestamp) +
            uint32(lockDurations[_pid]);

        userRewards[_pid][_account] = 0;
        userInfo[_pid][_account].rewardDebt = uint224(
            (userInfo[_pid][_account].amount *
                poolInfo[_pid].accRewardPerShare) / (REWARD_SCALING_FACTOR)
        );

        if (lastBlock != block.number) {
            uint256 debaseIndexDelta = Math.mulDiv(
                block.number - lastBlock,
                debaseMultiplier,
                1
            );
            banans.rebase(block.number, debaseIndexDelta, false);
            lastBlock = uint64(block.number);
            IUniswapV2Pair(config.banansPoolAddress()).sync();
        }

        //[!] if user has enough deposited into the Full Protec Pool, no withdrawal tax
        //if they don't, there will be a 33% tax on their claim
        //the taxed amount will be sent to the stolen pool
        if (
            userIsExemptFromClaimTax(_account) || _requestId == taxFreeRequestId
        ) {
            banans.mint(_account, pendingRewards);
            emit RewardPaid(_account, _pid, pendingRewards);
        } else {
            tax = Math.mulDiv(
                pendingRewards,
                bananClaimTaxRate,
                PERCENTAGE_DENOMINATOR
            );
            banans.mint(_account, pendingRewards - tax);

            IStolenPool(config.bananStolenPoolAddress()).virtualDeposit(tax);

            emit TaxPaid(config.bananStolenPoolAddress(), _pid, tax);
            emit RewardPaid(_account, _pid, pendingRewards - tax);
        }

        return (pendingRewards, tax);
    }

    function _queueRewards(uint256 _pid, address _account) private {
        UserInfo storage user = userInfo[_pid][_account];
        uint256 pendingRewards = Math.mulDiv(
            user.amount,
            poolInfo[_pid].accRewardPerShare,
            REWARD_SCALING_FACTOR
        ) - user.rewardDebt;
        if (pendingRewards > 0) {
            userRewards[_pid][_account] += pendingRewards;
        }
        emit RewardQueued(_account, _pid, pendingRewards);
    }

    //=========================================================================
    // GETTERS
    //=========================================================================

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending Banans on frontend.
    function pendingReward(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (address(pool.lpToken) == config.banansAddress()) {
            lpSupply = IBanansToken(config.banansAddress()).balanceOfUnderlying(
                address(this)
            );
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 banansReward = (block.number - pool.lastRewardBlock) *
                Math.mulDiv(
                    bananRewardPerBlock,
                    pool.allocPoint,
                    totalAllocPoint
                );
            accRewardPerShare +=
                (banansReward * REWARD_SCALING_FACTOR) /
                lpSupply;
        }
        return
            userRewards[_pid][_user] +
            ((user.amount * accRewardPerShare) / REWARD_SCALING_FACTOR) -
            user.rewardDebt;
    }

    ///@dev check both threshold banan amount in full protec, and % of total banans in all vaults in full protec to be above 33% (or n%)
    function userIsExemptFromClaimTax(
        address _user
    ) public view returns (bool) {
        IFullProtec fullProtec = IFullProtec(config.bananFullProtecAddress());

        bool thresholdCheck = fullProtec.getIsUserAboveThresholdToAvoidClaimTax(
            _user
        );

        uint256 banansInFullProtec = fullProtec.getUserStakedAmount(_user);
        uint256 banansInBigAndSmol = getBigAndSmolBananEquivalent(_user);

        if (banansInBigAndSmol == 0) return thresholdCheck;

        uint256 banansInFullProtecRatio = Math.mulDiv(
            banansInFullProtec,
            PERCENTAGE_DENOMINATOR,
            banansInBigAndSmol
        );
        bool ratioCheck = banansInFullProtecRatio >
            fullProtecProtocolLiqProportion;

        if (thresholdCheck && ratioCheck) {
            return true;
        }

        return false;
    }

    /// @dev for UI - output the ratio of full / smol+big(equivalent) which determines whether user is exempt
    function getFullToChefRatio(address _user) public view returns (uint256) {
        IFullProtec fullProtec = IFullProtec(config.bananFullProtecAddress());
        uint256 banansInFullProtec = fullProtec.getUserStakedAmount(_user);
        uint256 banansInBigAndSmol = getBigAndSmolBananEquivalent(_user);
        if (banansInBigAndSmol == 0) return banansInFullProtec;
        return
            Math.mulDiv(
                banansInFullProtec,
                PERCENTAGE_DENOMINATOR,
                banansInBigAndSmol
            );
    }

    function getBigAndSmolBananEquivalent(
        address _user
    ) public view returns (uint256) {
        uint256 bigProtecBananEquivalentAmount = getBananEquivalent(
            getTotalAmountStakedInPoolByUser(0, _user)
        );
        uint256 smolProtecAmount = getTotalAmountStakedInPoolByUser(1, _user);
        return bigProtecBananEquivalentAmount + smolProtecAmount;
    }

    /**
     * @dev returns the amount of banans corresponding to the given amount of LP tokens
     * @param _amount the amount of LP tokens to convert to banans
     */
    function getBananEquivalent(uint256 _amount) public view returns (uint256) {
        if (_amount == 0) return 0;

        IUniswapV2Pair banansEthPool = IUniswapV2Pair(
            config.banansPoolAddress()
        );
        uint256 totalLpTokenSupply = banansEthPool.totalSupply();
        (uint112 _reserve0, uint112 _reserve1, ) = banansEthPool.getReserves();
        address token0 = banansEthPool.token0();
        address token1 = banansEthPool.token1();

        uint256 tokenReserve = 0;
        if (token0 == config.banansAddress()) {
            tokenReserve = uint256(_reserve0);
        } else if (token1 == config.banansAddress()) {
            tokenReserve = uint256(_reserve1);
        }

        // Calculate the ERC20 token equivalent for the given _amount of LP tokens
        return Math.mulDiv(_amount, tokenReserve, totalLpTokenSupply);
    }

    /**
     * @dev gets converted (wallet-visible, 10^18 units) amounts for each pool
     * @param _user the user to get the amounts for
     * @param _pid the pool id to get the amounts for
     */
    function getTotalAmountStakedInPoolByUser(
        uint256 _pid,
        address _user
    ) public view returns (uint256) {
        if (_pid == 1) {
            return
                IBanansToken(config.banansAddress()).banansToFragment(
                    userInfo[_pid][_user].amount
                );
        } else {
            return userInfo[_pid][_user].amount;
        }
    }

    /// @dev get the address of the token corresponding to each pool, so banan-ETH LP (0), banan (1)
    function poolIdToToken(uint256 _pid) external view returns (address) {
        return address(poolInfo[_pid].lpToken);
    }

    /// @dev get 10^24 units of the total amount of banans staked in the given pool
    function getUserInfoAmount(
        address _user,
        uint256 _pid
    ) external view returns (uint256) {
        return userInfo[_pid][_user].amount;
    }

    //=========================================================================
    // SETTERS (CONFIG MANAGER CONTROLLED)
    //=========================================================================

    // Update the given pool's Banans allocation point. Can only be called by the config manager.
    function setAllocationPoint(
        uint256 _pid,
        uint128 _allocPoint,
        bool _withUpdatePools
    ) external onlyConfig {
        if (_withUpdatePools) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            uint128(poolInfo[_pid].allocPoint) +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit SetAllocationPoint(_pid, _allocPoint);
    }

    function setLockDuration(
        uint256 _pid,
        uint256 _lockDuration
    ) external onlyConfig {
        lockDurations[_pid] = _lockDuration;
        emit SetLockDuration(_pid, _lockDuration);
    }

    function updateRewardPerBlock(uint88 _rewardPerBlock) external onlyConfig {
        massUpdatePools();
        bananRewardPerBlock = _rewardPerBlock;
        emit SetRewardPerBlock(_rewardPerBlock);
    }

    function setDebaseMultiplier(uint48 _debaseMultiplier) external onlyConfig {
        debaseMultiplier = _debaseMultiplier;
    }

    function openBananChefDeposits() external onlyConfig {
        startBlock = uint40(block.number - blockOffset);
        lastBlock = startBlock;
        vaultDepositsAreOpen = true;
        emit SetDepositsEnabled(true);
    }

    function setDepositIsPaused(bool _isPaused) external onlyConfig {
        depositsPaused = _isPaused;
        emit SetDepositsEnabled(_isPaused);
    }

    function setClaimTaxRate(uint16 _maxTaxRate) external onlyConfig {
        bananClaimTaxRate = _maxTaxRate;
    }

    function setFullProtecLiquidityProportion(
        uint16 _fullProtecLiquidityProportion
    ) external onlyConfig {
        fullProtecProtocolLiqProportion = _fullProtecLiquidityProportion;
    }

    function setConfigManagerAddress(
        address _configManagerAddress
    ) external onlyOwner {
        config = IConfig(_configManagerAddress);
    }
}
