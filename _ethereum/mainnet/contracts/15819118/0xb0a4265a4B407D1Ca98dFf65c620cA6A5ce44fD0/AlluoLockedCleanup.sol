// // SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SafeERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

import "./IExchange.sol";
import "./IBalancer.sol";

contract AlluoLockedCleanup is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    IBalancerStructs
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Locking's reward amount produced per distribution time.
    uint256 public rewardPerDistribution;
    // Locking's reward distribution time.
    uint256 public constant distributionTime = 86400; 
    // Amount of currently locked tokens from all users (in lp).
    uint256 public totalLocked;

    // Auxiliary parameter (tpl) for locking's math
    uint256 private tokensPerLock;
    // Аuxiliary parameter for locking's math
    uint256 private rewardProduced;
    // Аuxiliary parameter for locking's math
    uint256 private allProduced;
    // Аuxiliary parameter for locking's math
    uint256 private producedTime;

    //period of locking after lock function call
    uint256 public depositLockDuration;
    //period of locking after unlock function call
    uint256 public withdrawLockDuration;

    // Amount of locked tokens waiting for withdraw (in Alluo).
    uint256 public waitingForWithdrawal;
    // Amount of currently claimed rewards by the users.
    uint256  public totalDistributed;
    // flag for allowing upgrade
    bool public upgradeStatus;

    //erc20-like interface
    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimals;
    }

    TokenInfo private token;

    // Locker contains info related to each locker.
    struct Locker {
        uint256 amount; // Tokens currently locked to the contract and vote power (in lp)
        uint256 rewardAllowed; // Rewards allowed to be paid out
        uint256 rewardDebt; // Param is needed for correct calculation locker's share
        uint256 distributed; // Amount of distributed tokens
        uint256 unlockAmount; // Amount of tokens which is available to withdraw (in alluo)
        uint256 depositUnlockTime; // The time when tokens are available to unlock
        uint256 withdrawUnlockTime; // The time when tokens are available to withdraw
    }

    // Lockers info by token holders.
    mapping(address => Locker) public _lockers;

    // ERC20 token locked on the contract and earned by locker as reward.
    IERC20Upgradeable public constant alluoToken =
        IERC20Upgradeable(0x1E5193ccC53f25638Aa22a940af899B692e10B09);

    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);
    IBalancer public constant balancer =
        IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IERC20Upgradeable public constant alluoBalancerLp =
        IERC20Upgradeable(0x85Be1e46283f5f438D1f864c2d925506571d544f);
    IERC20Upgradeable public constant weth = 
        IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes32 public constant poolId =
        0x85be1e46283f5f438d1f864c2d925506571d544f0002000000000000000001aa;

    /**
     * @dev Emitted in `updateWithdrawLockDuration` when the lock time after unlock() was changed
     */
    event WithdrawLockDurationUpdated(uint256 time, uint256 timestamp);

    /**
     * @dev Emitted in `updateDepositLockDuration` when the lock time after lock() was changed
     */
    event DepositLockDurationUpdated(uint256 time, uint256 timestamp);

    /**
     * @dev Emitted in `setReward` when the new rewardPerDistribution was set
     */
    event RewardAmountUpdated(uint256 amount, uint256 produced);

    /**
     * @dev Emitted in `lock` when the user locked the tokens
     */
    event TokensLocked(
        address indexed sender,
        address tokenAddress, 
        uint256 tokenAmount, 
        uint256 lpAmount, 
        uint256 time
    );

    /**
     * @dev Emitted in `unlock` when the user unbinded his locked tokens
     */
    event TokensUnlocked(
        address indexed sender,
        uint256 alluoAmount,
        uint256 lpAmount,
        uint256 time
    );
    
    /**
     * @dev Emitted in `withdraw` when the user withdrew his locked tokens from the contract
     */
    event TokensWithdrawed(
        address indexed sender,
        uint256 alluoAmount,
        uint256 time
    );

    /**
     * @dev Emitted in `claim` when the user claimed his reward tokens
     */
    event TokensClaimed(
        address indexed sender,
        uint256 alluoAmount, 
        uint256 time
    );

    // allows to see balances on etherscan  
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Contract constructor without parameters
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
 
    /**
     * @dev Contract initializer 
     */
    function initialize(
        address _multiSigWallet,
        uint256 _rewardPerDistribution
    ) public initializer{
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Locking: not contract");

        _setupRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, _multiSigWallet);

        token = TokenInfo({
            name: "Vote Locked Alluo Token",
            symbol: "vlAlluo",
            decimals: 18
        });

        rewardPerDistribution = _rewardPerDistribution; 
        producedTime = block.timestamp;

        depositLockDuration = 86400 * 7; 
        withdrawLockDuration = 86400 * 5;

        alluoToken.approve(address(exchange), type(uint256).max);
        alluoBalancerLp.approve(address(balancer), type(uint256).max);
        weth.approve(address(exchange), type(uint256).max);
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
     * @dev Locks specified amount Alluo tokens in the contract
     * @param _amount An amount of Alluo tokens to lock
     */
    function lock(uint256 _amount) public {

        Locker storage locker = _lockers[msg.sender];

        alluoToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        uint256 lpAmount = exchange.exchange(
            address(alluoToken),
            address(alluoBalancerLp),
            _amount,
            0
        );

        if (totalLocked > 0) {
            update();
        }

        locker.rewardDebt =
            locker.rewardDebt +
            ((lpAmount * tokensPerLock) / 1e20);
        totalLocked = totalLocked + lpAmount;
        locker.amount = locker.amount + lpAmount;
        locker.depositUnlockTime = block.timestamp + depositLockDuration;

        emit TokensLocked(msg.sender, address(alluoToken), _amount, lpAmount, block.timestamp );
        emit Transfer(address(0), msg.sender, lpAmount);
    }

    /**
     * @dev Locks specified amount WETH in the contract
     * @param _amount An amount of WETH tokens to lock
     */
    function lockWETH(uint256 _amount) public {

        Locker storage locker = _lockers[msg.sender];

        weth.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        uint256 lpAmount = exchange.exchange(
            address(weth),
            address(alluoBalancerLp),
            _amount,
            0
        );

        if (totalLocked > 0) {
            update();
        }

        locker.rewardDebt =
            locker.rewardDebt +
            ((lpAmount * tokensPerLock) / 1e20);
        totalLocked = totalLocked + lpAmount;
        locker.amount = locker.amount + lpAmount;
        locker.depositUnlockTime = block.timestamp + depositLockDuration;

        emit TokensLocked(msg.sender, address(weth), _amount, lpAmount, block.timestamp);
        emit Transfer(address(0), msg.sender, lpAmount);
    }

    /**
     * @dev Migrates all balances from old contract
     * @param _users list of lockers from old contract
     * @param _amounts list of amounts each equal to the share of locker on old contract
     *          (locked amount + unlocked + claim)
     */
    function migrationLock(address[] memory _users, uint256[] memory _amounts) external onlyRole(DEFAULT_ADMIN_ROLE){

        for(uint i = 0; i < _users.length; i++){
            Locker storage locker = _lockers[_users[i]];

            if (totalLocked > 0) {
                update();
            }

            locker.rewardDebt =
                locker.rewardDebt +
                ((_amounts[i] * tokensPerLock) / 1e20);
            totalLocked = totalLocked + _amounts[i];
            locker.amount = _amounts[i];
            locker.depositUnlockTime = block.timestamp + depositLockDuration;

            emit TokensLocked(_users[i], address(0), 0, _amounts[i], block.timestamp);
            emit Transfer(address(0), _users[i], _amounts[i]);
        }
    }

    /**
     * @dev Unbinds specified amount of tokens
     * @param _amount An amount to unbid
     */
    function unlock(uint256 _amount) public {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.depositUnlockTime <= block.timestamp,
            "Locking: tokens not available"
        );

        require(
            locker.amount >= _amount,
            "Locking: not enough lp tokens" 
        );

        update();


        uint256 alluoAmount = _exitAlluoPoolExactLp(_amount);

        locker.rewardAllowed =
            locker.rewardAllowed +
            ((_amount * tokensPerLock) / 1e20);
        locker.amount -= _amount;
        totalLocked -= _amount;

        waitingForWithdrawal += alluoAmount;

        locker.unlockAmount += alluoAmount;
        locker.withdrawUnlockTime = block.timestamp + withdrawLockDuration;

        emit TokensUnlocked(msg.sender, alluoAmount, _amount, block.timestamp);
        emit Transfer(msg.sender, address(0), _amount);
    }

    /**
     * @dev Unbinds all amount
     */
    function unlockAll() public {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.depositUnlockTime <= block.timestamp,
            "Locking: tokens not available"
        );

        uint256 amount = locker.amount;

        require(amount > 0, "Locking: not enough lp tokens");

        update();

        uint256 alluoAmount = _exitAlluoPoolExactLp(amount);

        locker.rewardAllowed =
            locker.rewardAllowed +
            ((amount * tokensPerLock) / 1e20);
        locker.amount = 0;
        totalLocked -= amount;

        waitingForWithdrawal += alluoAmount;

        locker.unlockAmount += alluoAmount;
        locker.withdrawUnlockTime = block.timestamp + withdrawLockDuration;

        emit TokensUnlocked(msg.sender, alluoAmount, amount, block.timestamp);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Unlocks unbinded tokens and transfers them to locker's address
     */
    function withdraw() public whenNotPaused {
        Locker storage locker = _lockers[msg.sender];

        require(
            locker.unlockAmount > 0,
            "Locking: not enough tokens"
        );

        require(
            block.timestamp >= locker.withdrawUnlockTime,
            "Locking: tokens not available"
        );

        uint256 amount = locker.unlockAmount;
        locker.unlockAmount = 0;
        waitingForWithdrawal -= amount;

        alluoToken.safeTransfer(msg.sender, amount);
        emit TokensWithdrawed(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Сlaims available rewards
     */
    function claim() public {
        if (totalLocked > 0) {
            update();
        }

        uint256 reward = calcReward(msg.sender, tokensPerLock);
        require(reward > 0, "Locking: Nothing to claim");

        Locker storage locker = _lockers[msg.sender];

        locker.distributed = locker.distributed + reward;
        totalDistributed += reward;

        alluoToken.safeTransfer(msg.sender, reward);
        emit TokensClaimed(msg.sender, reward, block.timestamp);
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
        return 0;
    }

    /**
     * @dev Returns unlocked balance of the specified locker
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
     * @dev converts amount of Alluo to Lp based on current ratio
     * @param _amount amount of Alluo tokens
     * @return amount amount of Lp tokens
     */
    function convertAlluoToLp(uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256 alluoOnBalancer = alluoToken.balanceOf(address(balancer));
        uint256 totalBalancerAlluoLp = ERC20Upgradeable(address(alluoBalancerLp)).totalSupply();
        uint256 alluoPerLp = alluoOnBalancer * 100 * 100000000 / totalBalancerAlluoLp / 80;
        return 
        _amount * 100000000 / alluoPerLp;
    }

    /**
     * @dev converts amount of Lp to Alluo tokens based on current ratio
     * @param _amount amount of Lp tokens
     * @return amount amount of Alluo tokens
     */
    function convertLpToAlluo(uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256 alluoOnBalancer = alluoToken.balanceOf(address(balancer));
        uint256 totalBalancerAlluoLp = ERC20Upgradeable(address(alluoBalancerLp)).totalSupply();
        uint256 alluoPerLp = alluoOnBalancer * 100 * 100000000 / totalBalancerAlluoLp / 80;
        return 
        _amount * alluoPerLp / 100000000;
    }

    /**
     * @dev Returns total amount of locked tokens (in lp)
     * @return amount of locked 
     */
    function totalSupply() external view returns (uint256 amount) {
        return 0;
    }

    /**
     * @dev Returns information about the specified locker
     * @param _address Locker's address
     * @return locked_ Locked amount of tokens (in lp)
     * @return unlockAmount_ Unlocked amount of tokens (in Alluo)
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
        alluoToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    /**
     * @dev Sets amount of reward during `distributionTime`
     * @param _amount Sets total reward amount per `distributionTime`
     */
    function setReward(uint256 _amount) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        allProduced = produced();
        producedTime = block.timestamp;
        rewardPerDistribution = _amount;
        emit RewardAmountUpdated(_amount, allProduced);
    }

    /**
     * @dev Allows to update the time when the rewards are available to unlock
     * @param _depositLockDuration Date in unix timestamp format
     */
    function updateDepositLockDuration(uint256 _depositLockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        depositLockDuration = _depositLockDuration;
        emit DepositLockDurationUpdated(_depositLockDuration, block.timestamp);
    }
    
    /**
     * @dev Allows to update the time when the rewards are available to withdraw
     * @param _withdrawLockDuration Date in unix timestamp format
     */
    function updateWithdrawLockDuration(uint256 _withdrawLockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        withdrawLockDuration = _withdrawLockDuration;
        emit WithdrawLockDurationUpdated(_withdrawLockDuration, block.timestamp);
    }

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {

        IERC20Upgradeable(withdrawToken).safeTransfer(to, amount);
    }

    function _exitAlluoPoolExactLp(uint256 lpAmount) private returns (uint256) {
        address[] memory assets = new address[](2);
        assets[0] = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;
        assets[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        uint256[] memory amounts = new uint256[](2);

        bytes memory data = abi.encode(
            uint256(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT),
            lpAmount,
            0
        );

        ExitPoolRequest memory request = ExitPoolRequest(
            assets,
            amounts,
            data,
            false
        );
        uint256 alluoBalanceBefore = alluoToken.balanceOf(address(this));
        balancer.exitPool(
            poolId,
            address(this),
            payable(address(this)),
            request
        );

        return alluoToken.balanceOf(address(this)) - alluoBalanceBefore;
    }

    function clean(address[] calldata users) external onlyRole(UPGRADER_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            emit Transfer(users[i], address(0), _lockers[users[i]].amount);
        }
    }

    /**
     * @dev allows and prohibits to upgrade contract
     * @param _status flag for allowing upgrade from gnosis
     */
    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    { 
        require(upgradeStatus, "Locking: upgrade not allowed");
        upgradeStatus = false;
    } 
}