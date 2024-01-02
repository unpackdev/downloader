// SPDX-FileCopyrightText: 2023 Stake Together Labs <legal@staketogether.org>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.22;

/// @title StakeTogether Interface
/// @notice This interface defines the essential structures and functions for the StakeTogether protocol.
/// @custom:security-contact security@staketogether.org
interface IStakeTogether {
  /// @notice Thrown if the deposit limit is reached.
  error DepositLimitReached();

  /// @notice Thrown if the transfer is too early to be executed.
  error EarlyTransfer();

  /// @notice Thrown if the feature is disabled.
  error FeatureDisabled();

  /// @notice Thrown if the operation is a FlashLoan.
  error FlashLoan();

  /// @notice Thrown if there is insufficient beacon balance.
  error InsufficientBeaconBalance();

  /// @notice Thrown if there are insufficient funds in the account.
  error InsufficientAccountBalance();

  /// @notice Thrown if the allowance is insufficient.
  error InsufficientAllowance();

  /// @notice Thrown if there is insufficient pool balance.
  error InsufficientPoolBalance();

  /// @notice Thrown if there are insufficient shares.
  error InsufficientShares();

  /// @notice Thrown if the allocations length is invalid.
  error InvalidLength();

  /// @notice Thrown if the total percentage is invalid.
  error InvalidSum();

  /// @notice Thrown if the value is invalid.
  error InvalidValue();

  /// @notice Thrown if the pool size is less than the validator size.
  error InvalidSize();

  /// @notice Thrown if the total percentage is not equal to 1 ether.
  error InvalidTotalPercentage();

  /// @notice Thrown if the total supply is invalid.
  error InvalidTotalSupply();

  /// @notice Thrown if the number of delegations exceeds the maximum limit.
  error MaxDelegations();

  /// @notice Thrown if the withdrawal amount is less than the minimum required.
  error LessThanMinimumWithdraw();

  /// @notice Thrown if the caller is not the airdrop.
  error OnlyAirdrop();

  /// @notice Thrown if the caller is not the router.
  error OnlyRouter();

  /// @notice Thrown if the caller is not a validator oracle.
  error OnlyValidatorOracle();

  /// @notice Thrown if the caller does not have the appropriate role.
  error NotAuthorized();

  /// @notice Thrown if the account is not in anti-fraud list.
  error NotInAntiFraudList();

  /// @notice Thrown if the caller is not the current oracle.
  error NotIsCurrentValidatorOracle();

  /// @notice Thrown if there is not enough pool balance.
  error NotEnoughPoolBalance();

  /// @notice Thrown if there is not enough balance on pool.
  error NotEnoughBalanceOnPool();

  /// @notice Thrown if the pool is not found.
  error PoolNotFound();

  /// @notice Thrown if the pool already exists.
  error PoolExists();

  /// @notice Thrown if the listed in anti-fraud.
  error ListedInAntiFraud();

  /// @notice Thrown if the router balance is greater than the withdrawal balance.
  error RouterAlreadyHaveBalance();

  /// @notice Thrown if the router balance is lower than the withdrawal balance.
  error ShouldAnticipateWithdraw();

  /// @notice Thrown if the delegations length should be zero.
  error ShouldBeZeroLength();

  /// @notice Thrown if the validator oracle already exists.
  error ValidatorOracleExists();

  /// @notice Thrown if the validator oracle is not found.
  error ValidatorOracleNotFound();

  /// @notice Thrown if the withdrawal amount is zero.
  error ZeroAmount();

  /// @notice Thrown if the address is the zero address.
  error ZeroAddress();

  /// @notice Thrown if there is zero supply.
  error ZeroSupply();

  /// @notice Thrown if the deposit amount is less than the minimum required.
  error LessThanMinimumDeposit();

  /// @notice Thrown if the withdrawal pool limit is reached.
  error WithdrawalsPoolLimitReached();

  /// @notice Thrown if the withdrawal validator limit is reached.
  error WithdrawalsValidatorLimitWasReached();

  /// @notice Thrown if the withdrawal balance is zero.
  error WithdrawZeroBalance();

  /// @notice Thrown if the amount is not greater than the pool balance.
  error WithdrawFromPool();

  /// @notice Thrown if the validator already exists.
  error ValidatorExists();

  /// @notice Configuration for the StakeTogether protocol.
  struct Config {
    uint256 blocksPerDay; /// Number of blocks per day.
    uint256 depositLimit; /// Maximum amount of deposit.
    uint256 maxDelegations; /// Maximum number of delegations.
    uint256 minDepositAmount; /// Minimum amount to deposit.
    uint256 minWithdrawAmount; /// Minimum amount to withdraw.
    uint256 poolSize; /// Size of the pool.
    uint256 validatorSize; /// Size of the validator.
    uint256 withdrawalPoolLimit; /// Maximum amount of pool withdrawal.
    uint256 withdrawalValidatorLimit; /// Maximum amount of validator withdrawal.
    uint256 withdrawDelay; /// Delay Blocks for withdrawal.
    uint256 withdrawBeaconDelay; /// Delay Blocks for beacon withdrawal.
    Feature feature; /// Additional features configuration.
  }

  /// @notice Represents a delegation, including the pool address and shares.
  struct Delegation {
    address pool; /// Address of the delegated pool.
    uint256 percentage; /// Number of percentage in the delegation.
  }

  /// @notice Toggleable features for the protocol.
  struct Feature {
    bool AddPool; /// Enable/disable pool addition.
    bool Deposit; /// Enable/disable deposits.
    bool WithdrawPool; /// Enable/disable pool withdrawals.
    bool WithdrawBeacon; /// Enable/disable validator withdrawals.
  }

  /// @notice Represents the fee structure.
  struct Fee {
    uint256 value; /// Value of the fee.
    mapping(FeeRole => uint256) allocations; /// Allocation of fees among different roles.
  }

  /// @notice Types of deposits available.
  enum DepositType {
    Donation, /// Donation type deposit.
    Pool /// Pool type deposit.
  }

  /// @notice Types of withdrawals available.
  enum WithdrawType {
    Pool, /// Pool type withdrawal.
    Validator /// Validator type withdrawal.
  }

  /// @notice Types of fees within the protocol.
  enum FeeType {
    Entry, /// Fee for entering a stake.
    Rewards, /// Fee for staking rewards.
    Pool, /// Fee for pool staking.
    Validator /// Fee for validator staking.
  }

  /// @notice Different roles that are used in fee allocation
  enum FeeRole {
    Airdrop,
    Operator,
    StakeTogether,
    Sender
  }

  /// @notice Emitted when a pool is added
  /// @param pool The address of the pool
  /// @param listed Indicates if the pool is listed
  /// @param social Indicates if the pool is social
  /// @param index Indicates if the pool is an index
  /// @param amount The amount associated with the pool
  event AddPool(address indexed pool, bool listed, bool social, bool index, uint256 amount);

  /// @notice Emitted when a validator oracle is added
  /// @param account The address of the account
  event AddValidatorOracle(address indexed account);

  /// @notice Emitted when withdraw is prioritized
  /// @param oracle The address of the oracle
  /// @param amount The amount for the validator
  event AnticipateWithdrawBeacon(address indexed oracle, uint256 amount);

  /// @notice Emitted when shares are burned
  /// @param account The address of the account
  /// @param sharesAmount The amount of shares burned
  event BurnShares(address indexed account, uint256 sharesAmount);

  /// @notice Emitted when a validator is created
  /// @param oracle The address of the oracle
  /// @param amount The amount for the validator
  /// @param publicKey The public key of the validator
  /// @param withdrawalCredentials The withdrawal credentials
  /// @param signature The signature
  /// @param depositDataRoot The deposit data root
  event AddValidator(
    address indexed oracle,
    uint256 amount,
    bytes publicKey,
    bytes withdrawalCredentials,
    bytes signature,
    bytes32 depositDataRoot
  );

  /// @notice Emitted when a base deposit is made
  /// @param to The address to deposit to
  /// @param amount The deposit amount
  /// @param depositType The type of deposit (Donation, Pool)
  /// @param pool The address of the pool
  /// @param referral The address of the referral
  event DepositBase(
    address indexed to,
    uint256 amount,
    DepositType depositType,
    address indexed pool,
    bytes indexed referral
  );

  /// @notice Emitted when the deposit limit is reached
  /// @param sender The address of the sender
  /// @param amount The amount deposited
  event DepositLimitWasReached(address indexed sender, uint256 amount);

  /// @notice Emitted when rewards are minted
  /// @param to The address to mint to
  /// @param sharesAmount The amount of shares minted
  /// @param feeType The type of fee (e.g., StakeEntry, ProcessStakeRewards)
  /// @param feeRole The role associated with the fee
  event MintFeeShares(
    address indexed to,
    uint256 sharesAmount,
    FeeType indexed feeType,
    FeeRole indexed feeRole
  );

  /// @notice Emitted when shares are minted
  /// @param to The address to mint to
  /// @param sharesAmount The amount of shares minted
  event MintShares(address indexed to, uint256 sharesAmount);

  /// @notice Emitted when the next validator oracle is set
  /// @param index The index of the oracle
  /// @param account The address of the account
  event NextValidatorOracle(uint256 index, address indexed account);

  /// @dev This event emits when rewards are processed for staking, indicating the amount and the number of shares.
  /// @param amount The total amount of rewards that have been processed for staking.
  /// @param sharesAmount The total number of shares associated with the processed staking rewards.
  event ProcessStakeRewards(uint256 indexed amount, uint256 indexed sharesAmount);

  /// @dev This event emits when a validator's stake has been processed.
  /// @param account The address of the account whose stake as a validator has been processed.
  /// @param amount The amount the account staked that has been processed.
  event ProcessStakeValidator(address indexed account, uint256 amount);

  /// @notice Emitted when Ether is received
  /// @param amount The amount of Ether received
  event ReceiveEther(uint256 indexed amount);

  /// @notice Emitted when a pool is removed
  /// @param pool The address of the pool
  event RemovePool(address indexed pool);

  /// @notice Emitted when a validator oracle is removed
  /// @param account The address of the account
  event RemoveValidatorOracle(address indexed account);

  /// @notice Emitted when the beacon balance is set
  /// @param amount The amount set for the beacon balance
  event SetBeaconBalance(uint256 indexed amount);

  /// @notice Emitted when a user's anti-fraud status is changed
  /// @param sender The address that is executing
  /// @param account The address of the account
  /// @param isListed The new anti-fraud status of the account (true if listed, false otherwise)
  event SetAntiFraudStatus(address indexed sender, address indexed account, bool isListed);

  /// @notice Emitted when the configuration is set
  /// @param config The configuration struct
  event SetConfig(Config indexed config);

  /// @notice Emitted when a fee is set
  /// @param feeType The type of fee being set
  /// @param value The value of the fee
  /// @param allocations The allocations for the fee
  event SetFee(FeeType indexed feeType, uint256 value, uint256[] allocations);

  /// @notice Emitted when a fee address is set
  /// @param role The role associated with the fee
  /// @param account The address of the account
  event SetFeeAddress(FeeRole indexed role, address indexed account);

  /// @notice Emitted when the router is set
  /// @param router The address of the router
  event SetRouter(address indexed router);

  /// @notice Emitted when the StakeTogether address is set
  /// @param stakeTogether The address of StakeTogether
  event SetStakeTogether(address indexed stakeTogether);

  /// @notice Emitted when the validator size is set
  /// @param newValidatorSize The new size for the validator
  event SetValidatorSize(uint256 indexed newValidatorSize);

  /// @notice Emitted when the withdraw balance is set
  /// @param amount The amount set for the withdraw balance
  event SetWithdrawBalance(uint256 indexed amount);

  /// @notice Emitted when the withdrawal credentials are set
  /// @param withdrawalCredentials The withdrawal credentials bytes
  event SetWithdrawalsCredentials(bytes indexed withdrawalCredentials);

  /// @notice Emitted when shares are transferred
  /// @param from The address transferring from
  /// @param to The address transferring to
  /// @param sharesAmount The amount of shares transferred
  event TransferShares(address indexed from, address indexed to, uint256 sharesAmount);

  /// @notice Emitted when delegations are updated
  /// @param account The address of the account
  /// @param delegations The delegation array
  event UpdateDelegations(address indexed account, Delegation[] delegations);

  /// @notice Emitted when a base withdrawal is made
  /// @param account The address withdrawing
  /// @param amount The withdrawal amount
  /// @param withdrawType The type of withdrawal
  /// @param pool The address of the pool
  event WithdrawBase(
    address indexed account,
    uint256 amount,
    WithdrawType withdrawType,
    address indexed pool
  );

  /// @notice Emitted when the withdrawal limit is reached
  /// @param sender The address of the sender
  /// @param amount The amount withdrawn
  event WithdrawalsLimitWasReached(address indexed sender, uint256 amount, WithdrawType withdrawType);

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
  ) external;

  /// @notice Pauses the contract, preventing certain actions.
  /// @dev Only callable by the admin role.
  function pause() external;

  /// @notice Unpauses the contract, allowing actions to resume.
  /// @dev Only callable by the admin role.
  function unpause() external;

  /// @notice Receive function to accept incoming ETH transfers.
  receive() external payable;

  /// @notice Sets the configuration for the Stake Together Protocol.
  /// @dev Only callable by the admin role.
  /// @param _config Configuration settings to be applied.
  function setConfig(Config memory _config) external;

  /// @notice Returns the total supply of the pool (contract balance + beacon balance).
  /// @return Total supply value.
  function totalSupply() external view returns (uint256);

  /// @notice Calculates the shares amount by wei.
  /// @param _account The address of the account.
  /// @return Balance value of the given account.
  function balanceOf(address _account) external view returns (uint256);

  /// @notice Retrieves the current balance of the beacon.
  /// @dev This function returns the current stored value within the beacon.
  /// @return The balance held within the beacon in uint256 format.
  function beaconBalance() external view returns (uint256);

  /// @notice Retrieves the available balance for withdrawal.
  /// @dev This function returns the balance that is currently available for withdrawal.
  /// @return The available balance for withdrawal in uint256 format.
  function withdrawBalance() external view returns (uint256);

  /// @notice Calculates the wei amount by shares.
  /// @param _sharesAmount Amount of shares.
  /// @return Equivalent amount in wei.
  function weiByShares(uint256 _sharesAmount) external view returns (uint256);

  /// @notice Calculates the shares amount by wei.
  /// @param _amount Amount in wei.
  /// @return Equivalent amount in shares.
  function sharesByWei(uint256 _amount) external view returns (uint256);

  /// @notice Transfers an amount of wei to the specified address.
  /// @param _to The address to transfer to.
  /// @param _amount The amount to be transferred.
  /// @return True if the transfer was successful.
  function transfer(address _to, uint256 _amount) external returns (bool);

  /// @notice Transfers tokens from one address to another using an allowance mechanism.
  /// @param _from Address to transfer from.
  /// @param _to Address to transfer to.
  /// @param _amount Amount of tokens to transfer.
  /// @return A boolean value indicating whether the operation succeeded.
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

  /// @notice Transfers a number of shares to the specified address.
  /// @param _to The address to transfer to.
  /// @param _sharesAmount The number of shares to be transferred.
  /// @return Equivalent amount in wei.
  function transferShares(address _to, uint256 _sharesAmount) external returns (uint256);

  /// @notice Returns the remaining number of tokens that an spender is allowed to spend on behalf of a token owner.
  /// @param _account Address of the token owner.
  /// @param _spender Address of the spender.
  /// @return A uint256 value representing the remaining number of tokens available for the spender.
  function allowance(address _account, address _spender) external view returns (uint256);

  /// @notice Sets the amount `_amount` as allowance of `_spender` over the caller's tokens.
  /// @param _spender Address of the spender.
  /// @param _amount Amount of allowance to be set.
  /// @return A boolean value indicating whether the operation succeeded.
  function approve(address _spender, uint256 _amount) external returns (bool);

  /// @notice Deposits into the pool with specific delegations.
  /// @param _pool the address of the pool.
  /// @param _referral The referral address.
  function depositPool(address _pool, bytes calldata _referral) external payable;

  /// @notice Deposits a donation to the specified address.
  /// @param _to The address to deposit to.
  /// @param _pool the address of the pool.
  /// @param _referral The referral address.
  function depositDonation(address _to, address _pool, bytes calldata _referral) external payable;

  /// @notice Withdraws from the pool with specific delegations and transfers the funds to the sender.
  /// @param _amount The amount to withdraw.
  /// @param _pool the address of the pool.
  function withdrawPool(uint256 _amount, address _pool) external;

  /// @notice Withdraws from the validators with specific delegations and mints tokens to the sender.
  /// @param _amount The amount to withdraw.
  /// @param _pool the address of the pool.
  function withdrawBeacon(uint256 _amount, address _pool) external;

  /// @notice Get the next withdraw block for account
  /// @param _account the address of the account.
  function getWithdrawBlock(address _account) external view returns (uint256);

  /// @notice Get the next withdraw beacon block for account
  /// @param _account the address of the account.
  function getWithdrawBeaconBlock(address _account) external view returns (uint256);

  /// @notice Adds an address to the anti-fraud list.
  /// @dev Callable only by accounts with the ANTI_FRAUD_SENTINEL_ROLE or ANTI_FRAUD_MANAGER_ROLE.
  /// Reverts if the provided address is the zero address or if the sender is not authorized.
  /// @param _account The address to be added to the anti-fraud list.
  function addToAntiFraud(address _account) external;

  /// @notice Removes an address from the anti-fraud list.
  /// @dev Callable only by accounts with the ANTI_FRAUD_MANAGER_ROLE.
  /// Reverts if the provided address is the zero address, not in the anti-fraud list, or if the sender is not authorized.
  /// @param _account The address to be removed from the anti-fraud list.
  function removeFromAntiFraud(address _account) external;

  /// @notice Check if an address is listed in the anti-fraud list.
  /// @param _account The address to be checked.
  /// @return true if the address is in the anti-fraud list, false otherwise.
  function isListedInAntiFraud(address _account) external view returns (bool);

  /// @notice Adds a permissionless pool with a specified address and listing status if feature enabled.
  /// @param _pool Address of the new pool.
  /// @param _listed True if the pool is listed.
  /// @param _social True if the pool is social.
  /// @param _index True if the pool is an index.
  function addPool(address _pool, bool _listed, bool _social, bool _index) external payable;

  /// @notice Removes a pool by its address.
  /// @param _pool The address of the pool to remove.
  function removePool(address _pool) external;

  /// @notice Updates delegations for the sender's address.
  /// @param _delegations The array of delegations to update.
  function updateDelegations(Delegation[] memory _delegations) external;

  /// @notice Adds a new validator oracle by its address.
  /// @param _account The address of the validator oracle to add.
  function addValidatorOracle(address _account) external;

  /// @notice Removes a validator oracle by its address.
  /// @param _account The address of the validator oracle to remove.
  function removeValidatorOracle(address _account) external;

  /// @notice Checks if an address is a validator oracle.
  /// @param _account The address to check.
  /// @return True if the address is a validator oracle, false otherwise.
  function isValidatorOracle(address _account) external view returns (bool);

  /// @notice Forces the selection of the next validator oracle.
  function forceNextValidatorOracle() external;

  /// @notice Sets the beacon balance to the specified amount.
  /// @param _amount The amount to set as the beacon balance.
  /// @dev Only the router address can call this function.
  function setBeaconBalance(uint256 _amount) external payable;

  /// @notice Sets the pending withdraw balance to the specified amount.
  /// @param _amount The amount to set as the pending withdraw balance.
  /// @dev Only the router address can call this function.
  function setWithdrawBalance(uint256 _amount) external payable;

  /// @notice Initiates a transfer to anticipate a validator's withdrawal.
  /// @dev Only a valid validator oracle can initiate this anticipation request.
  /// This function also checks the balance constraints before processing.
  function anticipateWithdrawBeacon() external;

  /// @notice Creates a new validator with the given parameters.
  /// @param _publicKey The public key of the validator.
  /// @param _signature The signature of the validator.
  /// @param _depositDataRoot The deposit data root for the validator.
  /// @dev Only a valid validator oracle can call this function.
  function addValidator(
    bytes calldata _publicKey,
    bytes calldata _signature,
    bytes32 _depositDataRoot
  ) external;

  /// @notice Function to claim rewards by transferring shares, accessible only by the airdrop fee address.
  /// @param _account Address to transfer the claimed rewards to.
  /// @param _sharesAmount Amount of shares to claim as rewards.
  function claimAirdrop(address _account, uint256 _sharesAmount) external;

  /// @notice Returns an array of fee roles.
  /// @return roles An array of FeeRole.
  function getFeesRoles() external pure returns (FeeRole[4] memory);

  /// @notice Sets the fee address for a given role.
  /// @param _role The role for which the address will be set.
  /// @param _address The address to set.
  /// @dev Only an admin can call this function.
  function setFeeAddress(FeeRole _role, address payable _address) external;

  /// @notice Gets the fee address for a given role.
  /// @param _role The role for which the address will be retrieved.
  /// @return The address associated with the given role.
  function getFeeAddress(FeeRole _role) external view returns (address);

  /// @notice Sets the fee for a given fee type.
  /// @param _feeType The type of fee to set.
  /// @param _value The value of the fee.
  /// @param _allocations The allocations for the fee.
  /// @dev Only an admin can call this function.
  function setFee(FeeType _feeType, uint256 _value, uint256[] calldata _allocations) external;

  /// @notice Process staking rewards and distributes the rewards based on shares.
  /// @param _sharesAmount The amount of shares related to the staking rewards.
  /// @dev Requires the caller to be the router contract.
  function processFeeRewards(uint256 _sharesAmount) external payable;
}
