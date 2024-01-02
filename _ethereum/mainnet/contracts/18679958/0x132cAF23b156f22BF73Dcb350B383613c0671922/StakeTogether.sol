// SPDX-FileCopyrightText: 2023 Stake Together Labs <legal@staketogether.org>
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./Math.sol";
import "./Address.sol";

import "./IDepositContract.sol";
import "./IAirdrop.sol";
import "./IRouter.sol";
import "./IStakeTogether.sol";
import "./IWithdrawals.sol";

/// @title StakeTogether Pool Contract
/// @notice The StakeTogether contract is the primary entry point for interaction with the StakeTogether protocol.
/// It provides functionalities for staking, withdrawals, fee management, and interactions with pools and validators.
/// @custom:security-contact security@staketogether.org
contract StakeTogether is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  ERC20PermitUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  IStakeTogether
{
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE'); /// Role for managing upgrades.
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); /// Role for administration.
  bytes32 public constant POOL_MANAGER_ROLE = keccak256('POOL_MANAGER_ROLE'); /// Role for managing pools.
  bytes32 public constant VALIDATOR_ORACLE_ROLE = keccak256('VALIDATOR_ORACLE_ROLE'); /// Role for managing validator oracles.
  bytes32 public constant VALIDATOR_ORACLE_MANAGER_ROLE = keccak256('VALIDATOR_ORACLE_MANAGER_ROLE'); /// Role for managing validator oracle managers.
  bytes32 public constant VALIDATOR_ORACLE_SENTINEL_ROLE = keccak256('VALIDATOR_ORACLE_SENTINEL_ROLE'); /// Role for sentinel functionality in validator oracle management.
  bytes32 public constant ANTI_FRAUD_MANAGER_ROLE = keccak256('ANTI_FRAUD_MANAGER_ROLE'); // Role for  anti-fraud managers.
  bytes32 public constant ANTI_FRAUD_SENTINEL_ROLE = keccak256('ANTI_FRAUD_SENTINEL_ROLE'); // Role for sentinel functionality in anti-fraud management.

  uint256 public version; /// Contract version.

  IAirdrop public airdrop; /// Airdrop contract instance.
  IDepositContract public deposit; /// Deposit contract interface.
  IRouter public router; /// Address of the contract router.
  IWithdrawals public withdrawals; /// Withdrawals contract instance.

  bytes public withdrawalCredentials; /// Credentials for withdrawals.
  uint256 public beaconBalance; /// Beacon balance (includes transient Beacon balance on router).
  uint256 public withdrawBalance; /// Pending withdraw balance to be withdrawn from router.

  Config public config; /// Configuration settings for the protocol.

  mapping(address => uint256) public shares; /// Mapping of addresses to their shares.
  uint256 public totalShares; /// Total number of shares.
  mapping(address => mapping(address => uint256)) private allowances; /// Allowances mapping.

  mapping(address => uint256) private lastOperationBlock; // Mapping of addresses to their last operation block.
  mapping(address => uint256) private nextWithdrawBlock; // Mapping the next block for withdraw
  mapping(address => uint256) private nextWithdrawBeaconBlock; // Mapping the next block for withdraw from beacon
  uint256 public lastResetBlock; /// Block number of the last reset.
  uint256 public totalDeposited; /// Total amount deposited.
  uint256 public totalWithdrawnPool; /// Total amount withdrawn pool.
  uint256 public totalWithdrawnValidator; /// Total amount withdrawn validator.

  mapping(address => bool) public pools; /// Mapping of pool addresses.

  address[] private validatorsOracle; /// List of validator oracles.
  mapping(address => uint256) private validatorsOracleIndices; /// Mapping of validator oracle indices.
  uint256 public currentOracleIndex; /// Current index of the oracle.

  mapping(bytes => bool) public validators; /// Mapping of validators.

  mapping(FeeRole => address payable) private feesRole; /// Mapping of fee roles to addresses.
  mapping(FeeType => Fee) private fees; /// Mapping of fee types to fee details.

  mapping(address => bool) private antiFraudList; /// Mapping of anti-fraud addresses.

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Stake Together Pool Initialization
  /// @param _airdrop The address of the airdrop contract.
  /// @param _deposit The address of the deposit contract.
  /// @param _router The address of the router.
  /// @param _withdrawals The address of the withdrawals contract.

  /// @param _withdrawalCredentials The bytes for withdrawal credentials.
  function initialize(
    address _airdrop,
    address _deposit,
    address _router,
    address _withdrawals,
    bytes memory _withdrawalCredentials
  ) public initializer {
    __ERC20_init('Stake Together Protocol', 'stpETH');
    __ERC20Burnable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __AccessControl_init();
    __ERC20Permit_init('Stake Together Protocol');
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    version = 1;

    airdrop = IAirdrop(payable(_airdrop));
    deposit = IDepositContract(_deposit);
    router = IRouter(payable(_router));
    withdrawals = IWithdrawals(payable(_withdrawals));
    withdrawalCredentials = _withdrawalCredentials;

    _mintShares(address(this), 1 ether);
  }

  /// @notice Pauses the contract, preventing certain actions.
  /// @dev Only callable by the admin role.
  function pause() external onlyRole(ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpauses the contract, allowing actions to resume.
  /// @dev Only callable by the admin role.
  function unpause() external onlyRole(ADMIN_ROLE) {
    _unpause();
  }

  /// @notice Internal function to authorize an upgrade.
  /// @dev Only callable by the upgrader role.
  /// @param _newImplementation Address of the new contract implementation.
  function _authorizeUpgrade(address _newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  /// @notice Receive function to accept incoming ETH transfers.
  /// @dev Non-reentrant to prevent re-entrancy attacks.
  receive() external payable {
    emit ReceiveEther(msg.value);
  }

  modifier nonFlashLoan() {
    if (block.number <= lastOperationBlock[msg.sender]) {
      revert FlashLoan();
    }
    _;
  }

  /************
   ** CONFIG **
   ************/

  /// @notice Sets the configuration for the Stake Together Protocol.
  /// @dev Only callable by the admin role.
  /// @param _config Configuration settings to be applied.
  function setConfig(Config memory _config) external onlyRole(ADMIN_ROLE) {
    if (_config.poolSize < config.validatorSize) revert InvalidSize();
    config = _config;
    emit SetConfig(_config);
  }

  /************
   ** SHARES **
   ************/

  /// @notice Returns the total supply of the pool (contract balance + beacon balance).
  /// @return Total supply value.
  function totalSupply() public view override(ERC20Upgradeable, IStakeTogether) returns (uint256) {
    uint256 _totalSupply = address(this).balance + beaconBalance - withdrawBalance;
    if (_totalSupply < 1 ether) revert InvalidTotalSupply();
    return _totalSupply;
  }

  ///  @notice Calculates the shares amount by wei.
  /// @param _account The address of the account.
  /// @return Balance value of the given account.
  function balanceOf(
    address _account
  ) public view override(ERC20Upgradeable, IStakeTogether) returns (uint256) {
    return weiByShares(shares[_account]);
  }

  /// @notice Calculates the wei amount by shares.
  /// @param _sharesAmount Amount of shares.
  /// @return Equivalent amount in wei.
  function weiByShares(uint256 _sharesAmount) public view returns (uint256) {
    return Math.mulDiv(_sharesAmount, totalSupply(), totalShares, Math.Rounding.Ceil);
  }

  /// @notice Calculates the shares amount by wei.
  /// @param _amount Amount in wei.
  /// @return Equivalent amount in shares.
  function sharesByWei(uint256 _amount) public view returns (uint256) {
    return Math.mulDiv(_amount, totalShares, totalSupply());
  }

  /// @notice Transfers an amount of wei to the specified address.
  /// @param _to The address to transfer to.
  /// @param _amount The amount to be transferred.
  /// @return True if the transfer was successful.
  function transfer(
    address _to,
    uint256 _amount
  ) public override(ERC20Upgradeable, IStakeTogether) returns (bool) {
    if (isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
    if (isListedInAntiFraud(_to)) revert ListedInAntiFraud();
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  /// @notice Transfers tokens from one address to another using an allowance mechanism.
  /// @param _from Address to transfer from.
  /// @param _to Address to transfer to.
  /// @param _amount Amount of tokens to transfer.
  /// @return A boolean value indicating whether the operation succeeded.
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) public override(ERC20Upgradeable, IStakeTogether) returns (bool) {
    if (isListedInAntiFraud(_from)) revert ListedInAntiFraud();
    if (isListedInAntiFraud(_to)) revert ListedInAntiFraud();
    if (isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
    _spendAllowance(_from, msg.sender, _amount);
    _transfer(_from, _to, _amount);
    return true;
  }

  /// @notice Transfers an amount of wei from one address to another.
  /// @param _from The address to transfer from.
  /// @param _to The address to transfer to.
  /// @param _amount The amount to be transferred.
  function _update(
    address _from,
    address _to,
    uint256 _amount
  ) internal override nonReentrant nonFlashLoan whenNotPaused {
    if (block.number < nextWithdrawBlock[msg.sender]) revert EarlyTransfer();
    lastOperationBlock[msg.sender] = block.number;
    uint256 _sharesToTransfer = sharesByWei(_amount);
    _transferShares(_from, _to, _sharesToTransfer);
    emit Transfer(_from, _to, _amount);
  }

  /// @notice Transfers a number of shares to the specified address.
  /// @param _to The address to transfer to.
  /// @param _sharesAmount The number of shares to be transferred.
  /// @return Equivalent amount in wei.
  function transferShares(
    address _to,
    uint256 _sharesAmount
  ) public nonReentrant whenNotPaused returns (uint256) {
    _transferShares(msg.sender, _to, _sharesAmount);
    return weiByShares(_sharesAmount);
  }

  /// @notice Internal function to handle the transfer of shares.
  /// @param _from The address to transfer from.
  /// @param _to The address to transfer to.
  /// @param _sharesAmount The number of shares to be transferred.
  function _transferShares(address _from, address _to, uint256 _sharesAmount) private whenNotPaused {
    if (isListedInAntiFraud(_from)) revert ListedInAntiFraud();
    if (isListedInAntiFraud(_to)) revert ListedInAntiFraud();
    if (_from == address(0)) revert ZeroAddress();
    if (_to == address(0)) revert ZeroAddress();
    if (_sharesAmount > shares[_from]) revert InsufficientShares();
    shares[_from] -= _sharesAmount;
    shares[_to] += _sharesAmount;
    emit TransferShares(_from, _to, _sharesAmount);
  }

  /// @notice Returns the remaining number of tokens that an spender is allowed to spend on behalf of a token owner.
  /// @param _account Address of the token owner.
  /// @param _spender Address of the spender.
  /// @return A uint256 value representing the remaining number of tokens available for the spender.
  function allowance(
    address _account,
    address _spender
  ) public view override(ERC20Upgradeable, IStakeTogether) returns (uint256) {
    return allowances[_account][_spender];
  }

  /// @notice Sets the amount `_amount` as allowance of `_spender` over the caller's tokens.
  /// @param _spender Address of the spender.
  /// @param _amount Amount of allowance to be set.
  /// @return A boolean value indicating whether the operation succeeded.
  function approve(
    address _spender,
    uint256 _amount
  ) public override(ERC20Upgradeable, IStakeTogether) returns (bool) {
    _approve(msg.sender, _spender, _amount, true);
    return true;
  }

  /// @notice Internal function to set the approval amount for a given spender and owner.
  /// @param _account Address of the token owner.
  /// @param _spender Address of the spender.
  /// @param _amount Amount of allowance to be set.
  function _approve(
    address _account,
    address _spender,
    uint256 _amount,
    bool emitEvent
  ) internal override {
    if (_account == address(0)) revert ZeroAddress();
    if (_spender == address(0)) revert ZeroAddress();
    allowances[_account][_spender] = _amount;
    if (emitEvent) {
      emit Approval(_account, _spender, _amount);
    }
  }

  /// @notice Internal function to deduct the allowance for a given spender, if any.
  /// @param _account Address of the token owner.
  /// @param _spender Address of the spender.
  /// @param _amount Amount to be deducted from the allowance.
  function _spendAllowance(address _account, address _spender, uint256 _amount) internal override {
    uint256 currentAllowance = allowances[_account][_spender];
    if (currentAllowance != ~uint256(0)) {
      if (currentAllowance < _amount) revert InsufficientAllowance();
      _approve(_account, _spender, currentAllowance - _amount, true);
    }
  }

  /// @notice Internal function to mint shares to a given address.
  /// @param _to Address to mint shares to.
  /// @param _sharesAmount Amount of shares to mint.
  function _mintShares(address _to, uint256 _sharesAmount) private whenNotPaused {
    if (_to == address(0)) revert ZeroAddress();
    shares[_to] += _sharesAmount;
    totalShares += _sharesAmount;
    emit MintShares(_to, _sharesAmount);
  }

  /// @notice Internal function to burn shares from a given address.
  /// @param _account Address to burn shares from.
  /// @param _sharesAmount Amount of shares to burn.
  function _burnShares(address _account, uint256 _sharesAmount) private whenNotPaused {
    if (_account == address(0)) revert ZeroAddress();
    if (_sharesAmount > shares[_account]) revert InsufficientShares();
    shares[_account] -= _sharesAmount;
    totalShares -= _sharesAmount;
    emit BurnShares(_account, _sharesAmount);
  }

  /***********
   ** STAKE **
   ***********/

  /// @notice Deposits the base amount to the specified address.
  /// @param _to The address to deposit to.
  /// @param _depositType The type of deposit (Pool or Donation).
  /// @param _referral The referral address.
  function _depositBase(
    address _to,
    DepositType _depositType,
    address _pool,
    bytes calldata _referral
  ) private {
    if (!config.feature.Deposit) revert FeatureDisabled();
    if (!(totalSupply() > 0)) revert ZeroSupply();
    if (antiFraudList[_to]) revert ListedInAntiFraud();
    if (msg.value < config.minDepositAmount) revert LessThanMinimumDeposit();
    if (!pools[_pool]) revert PoolNotFound();

    _resetLimits();
    totalDeposited += msg.value;
    lastOperationBlock[msg.sender] = block.number;
    nextWithdrawBlock[msg.sender] = block.number + config.withdrawDelay;

    if (totalDeposited > config.depositLimit) {
      emit DepositLimitWasReached(_to, msg.value);
      revert DepositLimitReached();
    }

    emit DepositBase(_to, msg.value, _depositType, _pool, _referral);
    _processFeeEntry(_to, msg.value);
  }

  /// @notice Deposits into the pool with specific delegations.
  /// @param _pool The address of the pool to deposit to.
  /// @param _referral The referral address.
  function depositPool(
    address _pool,
    bytes calldata _referral
  ) external payable nonReentrant nonFlashLoan whenNotPaused {
    _depositBase(msg.sender, DepositType.Pool, _pool, _referral);
  }

  /// @notice Deposits a donation to the specified address.
  /// @param _to The address to deposit to.
  /// @param _referral The referral address.
  function depositDonation(
    address _to,
    address _pool,
    bytes calldata _referral
  ) external payable nonReentrant nonFlashLoan whenNotPaused {
    _depositBase(_to, DepositType.Donation, _pool, _referral);
  }

  /// @notice Withdraws the base amount with the specified withdrawal type.
  /// @param _amount The amount to withdraw.
  /// @param _withdrawType The type of withdrawal (Pool or Validator).
  function _withdrawBase(uint256 _amount, WithdrawType _withdrawType, address _pool) private {
    if (antiFraudList[msg.sender]) revert ListedInAntiFraud();
    if (_amount == 0) revert ZeroAmount();
    if (_amount > balanceOf(msg.sender)) revert InsufficientAccountBalance();
    if (_amount < config.minWithdrawAmount) revert LessThanMinimumWithdraw();
    if (block.number < nextWithdrawBlock[msg.sender]) revert EarlyTransfer();

    _resetLimits();
    lastOperationBlock[msg.sender] = block.number;

    if (_withdrawType == WithdrawType.Pool) {
      totalWithdrawnPool += _amount;
      if (totalWithdrawnPool > config.withdrawalPoolLimit) {
        emit WithdrawalsLimitWasReached(msg.sender, _amount, _withdrawType);
        revert WithdrawalsPoolLimitReached();
      }
    } else {
      totalWithdrawnValidator += _amount;
      if (totalWithdrawnValidator > config.withdrawalValidatorLimit) {
        emit WithdrawalsLimitWasReached(msg.sender, _amount, _withdrawType);
        revert WithdrawalsValidatorLimitWasReached();
      }
    }

    emit WithdrawBase(msg.sender, _amount, _withdrawType, _pool);
    uint256 sharesToBurn = Math.mulDiv(_amount, shares[msg.sender], balanceOf(msg.sender));
    _burnShares(msg.sender, sharesToBurn);
  }

  /// @notice Withdraws from the pool with specific delegations and transfers the funds to the sender.
  /// @param _amount The amount to withdraw.
  /// @param _pool The address of the pool to withdraw from.
  function withdrawPool(uint256 _amount, address _pool) external nonReentrant nonFlashLoan whenNotPaused {
    if (!config.feature.WithdrawPool) revert FeatureDisabled();
    if (_amount > address(this).balance) revert InsufficientPoolBalance();
    _withdrawBase(_amount, WithdrawType.Pool, _pool);
    Address.sendValue(payable(msg.sender), _amount);
  }

  /// @notice Withdrawals from the beacon chain.
  /// @param _amount The amount to withdraw.
  /// @param _pool The address of the pool to withdraw from.
  function withdrawBeacon(
    uint256 _amount,
    address _pool
  ) external nonReentrant nonFlashLoan whenNotPaused {
    if (!config.feature.WithdrawBeacon) revert FeatureDisabled();
    if (_amount <= address(this).balance) revert WithdrawFromPool();
    if (_amount + withdrawBalance > beaconBalance) revert InsufficientBeaconBalance();
    nextWithdrawBeaconBlock[msg.sender] = block.number + config.withdrawBeaconDelay;
    _withdrawBase(_amount, WithdrawType.Validator, _pool);
    _setWithdrawBalance(withdrawBalance + _amount);

    withdrawals.mint(msg.sender, _amount);
  }

  /// @notice Resets the daily limits for deposits and withdrawals.
  function _resetLimits() private {
    if (block.number > lastResetBlock + config.blocksPerDay) {
      totalDeposited = 0;
      totalWithdrawnPool = 0;
      totalWithdrawnValidator = 0;
      lastResetBlock = block.number;
    }
  }

  /// @notice Get the next withdraw block for account
  /// @param _account the address of the account.
  function getWithdrawBlock(address _account) external view returns (uint256) {
    return nextWithdrawBlock[_account];
  }

  /// @notice Get the next withdraw beacon block for account
  /// @param _account the address of the account.
  function getWithdrawBeaconBlock(address _account) external view returns (uint256) {
    return nextWithdrawBeaconBlock[_account];
  }

  /****************
   ** ANTI-FRAUD **
   ****************/

  /// @notice Adds an address to the anti-fraud list.
  /// @dev Only a user with the ANTI_FRAUD_SENTINEL_ROLE or ANTI_FRAUD_MANAGER_ROLE can add addresses.
  /// @param _account The address to be added to the anti-fraud list.
  function addToAntiFraud(address _account) external {
    if (!hasRole(ANTI_FRAUD_SENTINEL_ROLE, msg.sender) && !hasRole(ANTI_FRAUD_MANAGER_ROLE, msg.sender))
      revert NotAuthorized();
    if (_account == address(0)) revert ZeroAddress();
    antiFraudList[_account] = true;
    emit SetAntiFraudStatus(msg.sender, _account, true);
  }

  /// @notice Removes an address from the anti-fraud list.
  /// @dev Only a user with the ANTI_FRAUD_MANAGER_ROLE can remove addresses.
  /// @param _account The address to be removed from the anti-fraud list.
  function removeFromAntiFraud(address _account) external {
    if (!hasRole(ANTI_FRAUD_MANAGER_ROLE, msg.sender)) revert NotAuthorized();
    if (_account == address(0)) revert ZeroAddress();
    if (!antiFraudList[_account]) revert NotInAntiFraudList();
    antiFraudList[_account] = false;
    emit SetAntiFraudStatus(msg.sender, _account, false);
  }

  /// @notice Check if an address is listed in the anti-fraud list.
  /// @param _account The address to be checked.
  /// @return true if the address is in the anti-fraud list, false otherwise.
  function isListedInAntiFraud(address _account) public view returns (bool) {
    return antiFraudList[_account];
  }

  /***********
   ** POOLS **
   ***********/

  /// @notice Adds a permissionless pool with a specified address and listing status if feature enabled.
  /// @param _pool The address of the pool to add.
  /// @param _listed The listing status of the pool.
  /// @param _social The kind of pool.
  /// @param _index Checked if the pool is a index
  function addPool(
    address _pool,
    bool _listed,
    bool _social,
    bool _index
  ) external payable nonReentrant whenNotPaused nonFlashLoan {
    if (_pool == address(0)) revert ZeroAddress();
    if (pools[_pool]) revert PoolExists();
    if (!hasRole(POOL_MANAGER_ROLE, msg.sender) || msg.value > 0) {
      if (!config.feature.AddPool) revert FeatureDisabled();
      if (msg.value != fees[FeeType.Pool].value) revert InvalidValue();
      _processFeePool();
    }
    pools[_pool] = true;
    lastOperationBlock[msg.sender] = block.number;
    emit AddPool(_pool, _listed, _social, _index, msg.value);
  }

  /// @notice Removes a pool by its address.
  /// @param _pool The address of the pool to remove.
  function removePool(address _pool) external nonFlashLoan whenNotPaused onlyRole(POOL_MANAGER_ROLE) {
    if (!pools[_pool]) revert PoolNotFound();
    pools[_pool] = false;
    lastOperationBlock[msg.sender] = block.number;
    emit RemovePool(_pool);
  }

  /// @notice Updates delegations for the sender's address.
  /// @param _delegations The array of delegations to update.
  function updateDelegations(Delegation[] memory _delegations) external {
    uint256 totalPercentage = 0;
    if (shares[msg.sender] > 0) {
      if (_delegations.length > config.maxDelegations) revert MaxDelegations();
      for (uint256 i = 0; i < _delegations.length; i++) {
        if (!pools[_delegations[i].pool]) revert PoolNotFound();
        totalPercentage += _delegations[i].percentage;
      }
      if (totalPercentage != 1 ether) revert InvalidTotalPercentage();
    } else {
      if (_delegations.length != 0) revert ShouldBeZeroLength();
    }
    emit UpdateDelegations(msg.sender, _delegations);
  }

  /***********************
   ** VALIDATORS ORACLE **
   ***********************/

  /// @notice Adds a new validator oracle by its address.
  /// @param _account The address of the validator oracle to add.
  function addValidatorOracle(address _account) external onlyRole(VALIDATOR_ORACLE_MANAGER_ROLE) {
    if (validatorsOracleIndices[_account] != 0) revert ValidatorOracleExists();

    validatorsOracle.push(_account);
    validatorsOracleIndices[_account] = validatorsOracle.length;

    _grantRole(VALIDATOR_ORACLE_ROLE, _account);
    emit AddValidatorOracle(_account);
  }

  /// @notice Removes a validator oracle by its address.
  /// @param _account The address of the validator oracle to remove.
  function removeValidatorOracle(address _account) external onlyRole(VALIDATOR_ORACLE_MANAGER_ROLE) {
    if (validatorsOracleIndices[_account] == 0) revert ValidatorOracleNotFound();

    uint256 index = validatorsOracleIndices[_account] - 1;

    if (index < validatorsOracle.length - 1) {
      address lastAddress = validatorsOracle[validatorsOracle.length - 1];
      validatorsOracle[index] = lastAddress;
      validatorsOracleIndices[lastAddress] = index + 1;
    }

    validatorsOracle.pop();
    delete validatorsOracleIndices[_account];

    bool isCurrentOracle = (index == currentOracleIndex);

    if (isCurrentOracle) {
      currentOracleIndex = (currentOracleIndex + 1) % validatorsOracle.length;
    }

    _revokeRole(VALIDATOR_ORACLE_ROLE, _account);
    emit RemoveValidatorOracle(_account);
  }

  /// @notice Checks if an address is a validator oracle.
  /// @param _account The address to check.
  /// @return True if the address is a validator oracle, false otherwise.
  function isValidatorOracle(address _account) public view returns (bool) {
    return hasRole(VALIDATOR_ORACLE_ROLE, _account) && validatorsOracleIndices[_account] > 0;
  }

  /// @notice Forces the selection of the next validator oracle.
  function forceNextValidatorOracle() external {
    if (
      !hasRole(VALIDATOR_ORACLE_SENTINEL_ROLE, msg.sender) &&
      !hasRole(VALIDATOR_ORACLE_MANAGER_ROLE, msg.sender)
    ) revert NotAuthorized();
    _nextValidatorOracle();
  }

  /// @notice Internal function to update the current validator oracle.
  function _nextValidatorOracle() private {
    currentOracleIndex = (currentOracleIndex + 1) % validatorsOracle.length;
    emit NextValidatorOracle(currentOracleIndex, validatorsOracle[currentOracleIndex]);
  }

  /****************
   ** VALIDATORS **
   ****************/

  /// @notice Sets the beacon balance to the specified amount.
  /// @param _amount The amount to set as the beacon balance.
  /// @dev Only the router address can call this function.
  function setBeaconBalance(uint256 _amount) external payable nonReentrant {
    if (msg.sender != address(router)) revert OnlyRouter();
    _setBeaconBalance(_amount);
  }

  /// @notice Internal function to set the beacon balance.
  /// @param _amount The amount to set as the beacon balance.
  function _setBeaconBalance(uint256 _amount) private {
    beaconBalance = _amount;
    emit SetBeaconBalance(_amount);
  }

  /// @notice Sets the pending withdraw balance to the specified amount.
  /// @param _amount The amount to set as the pending withdraw balance.
  /// @dev Only the router address can call this function.
  function setWithdrawBalance(uint256 _amount) external payable nonReentrant {
    if (msg.sender != address(router)) revert OnlyRouter();
    _setWithdrawBalance(_amount);
  }

  /// @notice Internal function to set the pending withdraw balance.
  /// @param _amount The amount to set as the pending withdraw balance.
  function _setWithdrawBalance(uint256 _amount) private {
    withdrawBalance = _amount;
    emit SetWithdrawBalance(_amount);
  }

  /// @notice Initiates a transfer to anticipate a validator's withdrawal.
  /// @dev Only a valid validator oracle can initiate this anticipation request.
  /// This function also checks the balance constraints before processing.
  function anticipateWithdrawBeacon() external nonReentrant whenNotPaused {
    if (!isValidatorOracle(msg.sender)) revert OnlyValidatorOracle();
    if (msg.sender != validatorsOracle[currentOracleIndex]) revert NotIsCurrentValidatorOracle();
    if (withdrawBalance == 0) revert WithdrawZeroBalance();

    uint256 routerBalance = address(router).balance;
    if (routerBalance > withdrawBalance) revert RouterAlreadyHaveBalance();

    uint256 diffAmount = withdrawBalance - routerBalance;
    if (address(this).balance < diffAmount) revert NotEnoughPoolBalance();

    _setBeaconBalance(beaconBalance + diffAmount);
    emit AnticipateWithdrawBeacon(msg.sender, diffAmount);

    router.receiveWithdrawEther{ value: diffAmount }();
  }

  /// @notice Creates a new validator with the given parameters.
  /// @param _publicKey The public key of the validator.
  /// @param _signature The signature of the validator.
  /// @param _depositDataRoot The deposit data root for the validator.
  /// @dev Only a valid validator oracle can call this function.
  function addValidator(
    bytes calldata _publicKey,
    bytes calldata _signature,
    bytes32 _depositDataRoot
  ) external nonReentrant whenNotPaused {
    if (!isValidatorOracle(msg.sender)) revert OnlyValidatorOracle();
    if (msg.sender != validatorsOracle[currentOracleIndex]) revert NotIsCurrentValidatorOracle();
    if (address(this).balance < config.poolSize) revert NotEnoughBalanceOnPool();
    if (validators[_publicKey]) revert ValidatorExists();
    if (address(router).balance < withdrawBalance) revert ShouldAnticipateWithdraw();

    validators[_publicKey] = true;
    _nextValidatorOracle();
    _setBeaconBalance(beaconBalance + config.validatorSize);
    emit AddValidator(
      msg.sender,
      config.validatorSize,
      _publicKey,
      withdrawalCredentials,
      _signature,
      _depositDataRoot
    );
    deposit.deposit{ value: config.validatorSize }(
      _publicKey,
      withdrawalCredentials,
      _signature,
      _depositDataRoot
    );
    _processFeeValidator();
  }

  /*************
   ** Airdrop **
   *************/

  /// @notice Function to claim rewards by transferring shares, accessible only by the airdrop fee address.
  /// @param _account Address to transfer the claimed rewards to.
  /// @param _sharesAmount Amount of shares to claim as rewards.
  function claimAirdrop(address _account, uint256 _sharesAmount) external whenNotPaused {
    if (msg.sender != address(airdrop)) revert OnlyAirdrop();
    _transferShares(address(airdrop), _account, _sharesAmount);
  }

  /*****************
   **    FEES     **
   *****************/

  /// @notice Returns an array of fee roles.
  /// @return roles An array of FeeRole.
  function getFeesRoles() public pure returns (FeeRole[4] memory) {
    return [FeeRole.Airdrop, FeeRole.Operator, FeeRole.StakeTogether, FeeRole.Sender];
  }

  /// @notice Sets the fee address for a given role.
  /// @param _role The role for which the address will be set.
  /// @param _address The address to set.
  /// @dev Only an admin can call this function.
  function setFeeAddress(FeeRole _role, address payable _address) external onlyRole(ADMIN_ROLE) {
    if (_address == address(0)) revert ZeroAddress();
    feesRole[_role] = _address;
    if (_role == FeeRole.Airdrop) {
      feesRole[_role] = payable(airdrop);
    } else {
      feesRole[_role] = _address;
    }
    emit SetFeeAddress(_role, _address);
  }

  /// @notice Gets the fee address for a given role.
  /// @param _role The role for which the address will be retrieved.
  /// @return The address associated with the given role.
  function getFeeAddress(FeeRole _role) public view returns (address) {
    return feesRole[_role];
  }

  /// @notice Sets the fee for a given fee type.
  /// @param _feeType The type of fee to set.
  /// @param _value The value of the fee.
  /// @param _allocations The allocations for the fee.
  /// @dev Only an admin can call this function.
  function setFee(
    FeeType _feeType,
    uint256 _value,
    uint256[] calldata _allocations
  ) external onlyRole(ADMIN_ROLE) {
    if (_allocations.length != 4) revert InvalidLength();
    uint256 sum = 0;
    for (uint256 i = 0; i < _allocations.length; i++) {
      fees[_feeType].allocations[FeeRole(i)] = _allocations[i];
      sum += _allocations[i];
    }

    if (sum != 1 ether) revert InvalidSum();

    fees[_feeType].value = _value;

    emit SetFee(_feeType, _value, _allocations);
  }

  /// @notice Get the fee for a given fee type.
  /// @param _feeType The type of fee to get.
  function getFee(FeeType _feeType) external view returns (uint256) {
    return fees[_feeType].value;
  }

  /// @notice Distributes fees according to their type, amount, and the destination.
  /// @param _feeType The type of fee being distributed.
  /// @param _sharesAmount The total shares amount for the fee.
  /// @param _to The address to distribute the fees.
  /// @dev This function computes how the fees are allocated to different roles.
  function _distributeFees(FeeType _feeType, uint256 _sharesAmount, address _to) private {
    uint256[4] memory allocatedShares;
    FeeRole[4] memory roles = getFeesRoles();

    uint256 feeValue = fees[_feeType].value;
    uint256 feeShares = Math.mulDiv(_sharesAmount, feeValue, 1 ether);
    uint256 totalAllocatedShares = 0;

    for (uint256 i = 0; i < roles.length - 1; i++) {
      if (getFeeAddress(roles[i]) == address(0)) revert ZeroAddress();
      uint256 allocation = fees[_feeType].allocations[roles[i]];
      allocatedShares[i] = Math.mulDiv(feeShares, allocation, 1 ether);
      totalAllocatedShares += allocatedShares[i];
    }

    allocatedShares[3] = _sharesAmount - totalAllocatedShares;

    uint256 length = (_feeType == FeeType.Entry) ? roles.length : roles.length - 1;

    for (uint256 i = 0; i < length; i++) {
      if (allocatedShares[i] > 0) {
        if (_feeType == FeeType.Entry && roles[i] == FeeRole.Sender) {
          _mintShares(_to, allocatedShares[i]);
        } else {
          _mintShares(getFeeAddress(roles[i]), allocatedShares[i]);
          emit MintFeeShares(getFeeAddress(roles[i]), allocatedShares[i], _feeType, roles[i]);
        }
      }
    }
  }

  /// @notice Processes a stake entry and distributes the associated fees.
  /// @param _to The address to receive the stake entry.
  /// @param _amount The amount staked.
  /// @dev Calls the distributeFees function internally.
  function _processFeeEntry(address _to, uint256 _amount) private {
    uint256 sharesAmount = Math.mulDiv(_amount, totalShares, totalSupply() - _amount);
    _distributeFees(FeeType.Entry, sharesAmount, _to);
  }

  /// @notice Process staking rewards and distributes the rewards based on shares.
  /// @param _sharesAmount The amount of shares related to the staking rewards.
  /// @dev The caller should be the router contract. This function will also emit the ProcessStakeRewards event.
  function processFeeRewards(uint256 _sharesAmount) external payable nonReentrant whenNotPaused {
    if (msg.sender != address(router)) revert OnlyRouter();
    _distributeFees(FeeType.Rewards, _sharesAmount, address(0));
    emit ProcessStakeRewards(msg.value, _sharesAmount);
  }

  /// @notice Processes the staking pool fee and distributes it accordingly.
  /// @dev Calculates the shares amount and then distributes the staking pool fee.
  function _processFeePool() private {
    uint256 amount = fees[FeeType.Pool].value;
    uint256 sharesAmount = Math.mulDiv(amount, totalShares, totalSupply() - amount);
    _distributeFees(FeeType.Pool, sharesAmount, address(0));
  }

  /// @notice Transfers the staking validator fee to the operator role.
  /// @dev Transfers the associated amount to the Operator's address.
  function _processFeeValidator() private {
    emit ProcessStakeValidator(getFeeAddress(FeeRole.Operator), fees[FeeType.Validator].value);
    Address.sendValue(payable(getFeeAddress(FeeRole.Operator)), fees[FeeType.Validator].value);
  }
}
