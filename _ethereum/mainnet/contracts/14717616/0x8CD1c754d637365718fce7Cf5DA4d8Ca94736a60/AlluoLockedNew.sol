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

contract AlluoLockedNew is
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

    function decimals() public view returns (uint8) {
        return token.decimals;
    }

    function name() public view returns (string memory) {
        return token.name;
    }

    function symbol() public view returns (string memory) {
        return token.symbol;
    }

    /**
     * @dev Calculates the necessary parameters for locking
     * @return Totally produced rewards
     */
    function produced() private view returns (uint256) {
        return
            allProduced +
            (rewardPerDistribution * (block.timestamp - producedTime)) /
            distributionTime;
    }

    /**
     * @dev Updates the produced rewards parameter for locking
     */
    function update() public whenNotPaused {
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalLocked > 0) {
                tokensPerLock =
                    tokensPerLock +
                    (producedNew * 1e20) /
                    totalLocked;
            }
            rewardProduced = rewardProduced + producedNew;
        }
    }

    /**
     * @dev Locks specified amount to the contract
     * @param _amount An amount to lock
     */
    function lock(uint256 _amount) public {
        require(
            block.timestamp > startTime,
            "Locking: locking time has not come yet"
        );

        Locker storage locker = _lockers[msg.sender];

        IERC20Upgradeable(lockingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _enterAlluoPool(_amount, 0);

        if (totalLocked > 0) {
            update();
        }
        locker.rewardDebt =
            locker.rewardDebt +
            ((_amount * tokensPerLock) / 1e20);
        totalLocked = totalLocked + _amount;
        locker.amount = locker.amount + _amount;
        locker.depositUnlockTime = block.timestamp + depositLockDuration;

        emit TokensLocked(_amount, block.timestamp, msg.sender);
    }

    /**
     * @dev Unbinds specified amount of tokens
     * @param _amount An amount to unbid
     */
    function unlock(uint256 _amount) public nonReentrant {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.depositUnlockTime <= block.timestamp,
            "Locking: Locked tokens are not available yet"
        );

        require(
            locker.amount >= _amount,
            "Locking: Not enough tokens to unlock"
        );

        update();

        locker.rewardAllowed =
            locker.rewardAllowed +
            ((_amount * tokensPerLock) / 1e20);

        locker.amount -= _amount;
        totalLocked -= _amount;
        additionalLockInfo.waitingForWithdrawal += _amount;

        locker.unlockAmount += _amount;
        locker.depositUnlockTime = 0;
        locker.withdrawUnlockTime = block.timestamp + withdrawLockDuration;

        emit TokensUnlocked(_amount, block.timestamp, msg.sender);
    }

    /**
     * @dev Unbinds all amount of locked tokens
     */
    function unlockAll() public nonReentrant {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.depositUnlockTime <= block.timestamp,
            "Locking: Locked tokens are not available yet"
        );

        require(locker.amount > 0, "Locking: Not enough tokens to unlock");
        uint256 amount = locker.amount;

        update();

        locker.rewardAllowed =
            locker.rewardAllowed +
            ((amount * tokensPerLock) / 1e20);
        locker.amount = 0;
        totalLocked -= amount;
        additionalLockInfo.waitingForWithdrawal += amount;

        locker.unlockAmount += amount;
        locker.depositUnlockTime = 0;
        locker.withdrawUnlockTime = block.timestamp + withdrawLockDuration;

        emit TokensUnlocked(amount, block.timestamp, msg.sender);
    }

    /**
     * @dev Unlocks unbinded tokens and transfers them to locker's address
     */
    function withdraw() public whenNotPaused nonReentrant {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.unlockAmount > 0,
            "Locking: Not enough tokens to withdraw"
        );

        require(
            block.timestamp >= locker.withdrawUnlockTime,
            "Locking: Unlocked tokens are not available yet"
        );

        uint256 amount = locker.unlockAmount;
        locker.unlockAmount = 0;
        locker.withdrawUnlockTime = 0;
        additionalLockInfo.waitingForWithdrawal -= amount;

        _exitAlluoPool(amount);
        IERC20Upgradeable(lockingToken).safeTransfer(msg.sender, amount);
        emit TokensWithdrawed(amount, block.timestamp, msg.sender);
    }

    /**
     * @dev Сlaims available rewards
     * @return Boolean result
     */
    function claim() public nonReentrant returns (bool) {
        if (totalLocked > 0) {
            update();
        }

        uint256 reward = calcReward(msg.sender, tokensPerLock);
        require(reward > 0, "Locking: Nothing to claim");

        Locker storage locker = _lockers[msg.sender];

        locker.distributed = locker.distributed + reward;
        additionalLockInfo.totalDistributed += reward;

        _exitAlluoPool(reward);
        IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, reward);
        emit TokensClaimed(reward, block.timestamp, msg.sender);
        return true;
    }

    /**
     * @dev Claims all available rewards and unlocks the tokens
     */
    function claimAndUnlock() public {
        unlockAll();

        uint256 reward = getClaim(msg.sender);
        if (reward > 0) {
            claim();
        }
    }

    /**
     * @dev Сalculates available reward
     * @param _locker Address of the locker
     * @param _tpl Tokens per lock parameter
     */
    function calcReward(address _locker, uint256 _tpl)
        private
        view
        returns (uint256 reward)
    {
        Locker storage locker = _lockers[_locker];

        reward =
            ((locker.amount * _tpl) / 1e20) +
            locker.rewardAllowed -
            locker.distributed -
            locker.rewardDebt;

        return reward;
    }

    /**
     * @dev Returns locker's available rewards
     * @param _locker Address of the locker
     * @return reward Available reward to claim
     */
    function getClaim(address _locker) public view returns (uint256 reward) {
        uint256 _tpl = tokensPerLock;
        if (totalLocked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                _tpl = _tpl + ((producedNew * 1e20) / totalLocked);
            }
        }
        reward = calcReward(_locker, _tpl);

        return reward;
    }

    /**
     * @dev Returns balance of the specified locker
     * @param _address Locker's address
     * @return amount of vote/locked tokens
     */
    function balanceOf(address _address)
        external
        view
        returns (uint256 amount)
    {
        return _lockers[_address].amount;
    }

    /**
     * @dev Returns balance of the specified locker
     * @param _address Locker's address
     * @return amount of unlocked tokens
     */
    function unlockedBalanceOf(address _address)
        external
        view
        returns (uint256 amount)
    {
        return _lockers[_address].unlockAmount;
    }

    /**
     * @dev Returns total amount of tokens
     * @return amount of locked and unlocked tokens
     */
    function totalSupply() external view returns (uint256 amount) {
        return totalLocked + additionalLockInfo.waitingForWithdrawal;
    }

    /**
     * @dev Returns information about the specified locker
     * @param _address Locker's address
     * @return locked_ Locked amount of tokens
     * @return unlockAmount_ Unlocked amount of tokens
     * @return claim_  Reward amount available to be claimed
     * @return depositUnlockTime_ Timestamp when tokens will be available to unlock
     * @return withdrawUnlockTime_ Timestamp when tokens will be available to withdraw
     */
    function getInfoByAddress(address _address)
        external
        view
        returns (
            uint256 locked_,
            uint256 unlockAmount_,
            uint256 claim_,
            uint256 depositUnlockTime_,
            uint256 withdrawUnlockTime_
        )
    {
        Locker memory locker = _lockers[_address];
        locked_ = locker.amount;
        unlockAmount_ = locker.unlockAmount;
        depositUnlockTime_ = locker.depositUnlockTime;
        withdrawUnlockTime_ = locker.withdrawUnlockTime;
        claim_ = getClaim(_address);

        return (
            locked_,
            unlockAmount_,
            claim_,
            depositUnlockTime_,
            withdrawUnlockTime_
        );
    }

    /* ========== ADMIN CONFIGURATION ========== */

    ///@dev Pauses the locking
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    ///@dev Unpauses the locking
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Adds reward tokens to the contract
     * @param _amount Specifies the amount of tokens to be transferred to the contract
     */
    function addReward(uint256 _amount) external {
        IERC20Upgradeable(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _enterAlluoPool(_amount, 0);
    }

    /**
     * @dev Sets amount of reward during `distributionTime`
     * @param _amount Sets total reward amount per `distributionTime`
     */
    function setReward(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allProduced = produced();
        producedTime = block.timestamp;
        rewardPerDistribution = _amount;
        emit RewardAmountUpdated(_amount, allProduced);
    }

    /**
     * @dev Allows to update the time when the reward are available to withdraw
     * @param _withdrawLockDuration Date in unix timestamp format
     */
    function updateWithdrawLockDuration(uint256 _withdrawLockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        withdrawLockDuration = _withdrawLockDuration;
    }

    /**
     * @dev Allows to update the time when the reward are available to unlock
     * @param _depositLockDuration Date in unix timestamp format
     */
    function updateDepositLockDuration(uint256 _depositLockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        depositLockDuration = _depositLockDuration;
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

    /**
     * @dev allows and prohibits to migrate money from contract
     * for user
     * @param _status flag for allowing upgrade from gnosis
     */
    function changeMigrationStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        additionalLockInfo.migrationStatus = _status;
    }

    /**
     * @dev Withdrawing all tokens from the contract by user
     * if migration allowed
     */
    function migrate() external {
        require(additionalLockInfo.migrationStatus, "migration not allowed");
        Locker storage locker = _lockers[msg.sender];
        locker.depositUnlockTime = 0;
        if (locker.amount > 0) {
            unlockAll();
        }
        if (getClaim(msg.sender) > 0) {
            claim();
        }
        locker.withdrawUnlockTime = 0;
        if (locker.unlockAmount != 0) {
            withdraw();
        }
    }

    function initializeBalancerVersion() external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable weth = IERC20Upgradeable(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );
        lockingToken.approve(address(exchange), type(uint256).max);
        alluoBalancerLp.approve(address(balancer), type(uint256).max);
        weth.approve(address(exchange), type(uint256).max);

        uint256 alluoBalance = lockingToken.balanceOf(address(this));
        uint256 wethBalance = weth.balanceOf(address(this));
        _enterAlluoPool(alluoBalance, wethBalance);
    }

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            withdrawToken != address(alluoBalancerLp),
            "cant withdraw alluolp token"
        );
        IERC20Upgradeable(withdrawToken).safeTransfer(to, amount);
    }

    function _enterAlluoPool(uint256 alluoAmount, uint256 wethAmount) private {
        exchange.exchange(
            address(lockingToken),
            address(alluoBalancerLp),
            alluoAmount,
            0
        );
        if (wethAmount > 0) {
            IERC20Upgradeable weth = IERC20Upgradeable(
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            );
            exchange.exchange(
                address(weth),
                address(alluoBalancerLp),
                wethAmount,
                0
            );
        }
    }

    function _exitAlluoPool(uint256 alluoAmountToGet) private {
        address[] memory assets = new address[](2);
        assets[0] = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;
        assets[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = alluoAmountToGet;
        amounts[1] = 0;

        bytes memory data = abi.encode(
            uint256(ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT),
            amounts,
            type(uint256).max
        );

        ExitPoolRequest memory request = ExitPoolRequest(
            assets,
            amounts,
            data,
            false
        );
        balancer.exitPool(
            poolId,
            address(this),
            payable(address(this)),
            request
        );
    }
}
