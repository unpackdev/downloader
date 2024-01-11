// // SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./console.sol";

import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

import "./IExchange.sol";
import "./IBalancer.sol";

contract AlluoLockedV2Final is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IBalancerStructs
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // ERC20 token locking to the contract.
    IERC20Upgradeable public lockingToken;
    // ERC20 token earned by locker as reward.
    IERC20Upgradeable public rewardToken;

    // Locking's reward amount produced per distribution time.
    uint256 public rewardPerDistribution;
    // Locking's start time.
    uint256 public startTime;
    // Locking's reward distribution time.
    uint256 public distributionTime;
    // Amount of currently locked tokens from all users.
    uint256 public totalLocked;

    // Аuxiliary parameter (tpl) for locking's math
    uint256 public tokensPerLock;
    // Аuxiliary parameter for locking's math
    uint256 public rewardProduced;
    // Аuxiliary parameter for locking's math
    uint256 public allProduced;
    // Аuxiliary parameter for locking's math
    uint256 public producedTime;

    //period of locking after lock function call
    uint256 public depositLockDuration;
    //period of locking after unlock function call
    uint256 public withdrawLockDuration;

    struct AdditionalLockInfo {
        // Amount of locked tokens waiting for withdraw.
        uint256 waitingForWithdrawal;
        // Amount of currently claimed rewards by the users.
        uint256 totalDistributed;
        // flag for allowing upgrade
        bool upgradeStatus;
        // flag for allowing migrate
        bool migrationStatus;
    }

    AdditionalLockInfo private additionalLockInfo;

    //erc20-like interface
    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimals;
    }

    TokenInfo private token;

    // Locker contains info related to each locker.
    struct Locker {
        uint256 amount; // Tokens currently locked to the contract and vote power
        uint256 rewardAllowed; // Rewards allowed to be paid out
        uint256 rewardDebt; // Param is needed for correct calculation locker's share
        uint256 distributed; // Amount of distributed tokens
        uint256 unlockAmount; // Amount of tokens which is available to withdraw
        uint256 depositUnlockTime; // The time when tokens are available to unlock
        uint256 withdrawUnlockTime; // The time when tokens are available to withdraw
    }

    // Lockers info by token holders.
    mapping(address => Locker) public _lockers;

    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);
    IBalancer public constant balancer =
        IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IERC20Upgradeable public constant alluoBalancerLp =
        IERC20Upgradeable(0x85Be1e46283f5f438D1f864c2d925506571d544f);
    bytes32 public constant poolId =
        0x85be1e46283f5f438d1f864c2d925506571d544f0002000000000000000001aa;

    /**
     * @dev Emitted in `initialize` when the locking was initialized
     */
    event LockingInitialized(address lockingToken, address rewardToken);

    /**
     * @dev Emitted in `updateUnlockClaimTime` when the unlock time to claim was updated
     */
    event UnlockClaimTimeUpdated(uint256 time, uint256 timestamp);

    /**
     * @dev Emitted in `setReward` when the new rewardPerDistribution was set
     */
    event RewardAmountUpdated(uint256 amount, uint256 produced);

    /**
     * @dev Emitted in `lock` when the user locked the tokens
     */
    event TokensLocked(uint256 amount, uint256 time, address indexed sender);

    /**
     * @dev Emitted in `claim` when the user claimed his reward tokens
     */
    event TokensClaimed(uint256 amount, uint256 time, address indexed sender);

    /**
     * @dev Emitted in `unlock` when the user unbinded his locked tokens
     */
    event TokensUnlocked(uint256 amount, uint256 time, address indexed sender);
    /**
     * @dev Emitted in `withdraw` when the user withdrew his locked tokens from the contract
     */
    event TokensWithdrawed(
        uint256 amount,
        uint256 time,
        address indexed sender
    );

    /**
     * @dev Contract constructor without parameters
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(additionalLockInfo.upgradeStatus, "Upgrade not allowed");
    }

    /**
     * @dev Contract constructor
     */
    function initialize(
        address _multiSigWallet,
        uint256 _rewardPerDistribution,
        uint256 _startTime,
        uint256 _distributionTime,
        address _lockingToken,
        address _rewardToken
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        require(_multiSigWallet.isContract(), "Locking: not contract");

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _setupRole(UPGRADER_ROLE, _multiSigWallet);

        token = TokenInfo({
            name: "Vote Locked Alluo Token",
            symbol: "vlAlluo",
            decimals: 18
        });

        rewardPerDistribution = _rewardPerDistribution;
        startTime = _startTime;
        distributionTime = _distributionTime;
        producedTime = _startTime;

        depositLockDuration = 86400 * 7;
        withdrawLockDuration = 86400 * 5;

        lockingToken = IERC20Upgradeable(_lockingToken);
        rewardToken = IERC20Upgradeable(_rewardToken);
        emit LockingInitialized(_lockingToken, _rewardToken);
    }

    /* ========== ADMIN CONFIGURATION ========== */

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(withdrawToken).safeTransfer(to, amount);
    }

    /**
     * @dev allows and prohibits to upgrade contract
     * @param _status flag for allowing upgrade from gnosis
     */
    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        additionalLockInfo.upgradeStatus = _status;
    }

}