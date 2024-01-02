// SPDX-FileCopyrightText: 2023 Stake Together Labs <legal@staketogether.org>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.22;

/// @title Interface for Validators Withdrawals
/// @notice A contract that represent the validator withdrawal functionality
/// @custom:security-contact security@staketogether.org
interface IWithdrawals {
  /// @notice This error is thrown when use try withdraw before the beacon delay.
  error EarlyBeaconTransfer();

  /// @notice Thrown if the operation is a FlashLoan.
  error FlashLoan();

  /// @notice This error is thrown when the sender has insufficient STW balance to perform a transaction.
  error InsufficientStwBalance();

  /// @notice This error is thrown when the contract has insufficient ETH balance to perform a transaction.
  error InsufficientEthBalance();

  /// @notice Thrown if the listed in anti-fraud.
  error ListedInAntiFraud();

  /// @notice This error is thrown when there is no extra amount of ETH available to transfer.
  error NoExtraAmountAvailable();

  /// @notice This error is thrown when an action is attempted by an address other than the router.
  error OnlyRouter();

  /// @notice This error is thrown when an action is attempted by an address other than the stakeTogether contract.
  error OnlyStakeTogether();

  /// @notice This error is thrown when trying to set the router contract that has already been set.
  error RouterAlreadySet();

  /// @notice This error is thrown when trying to set the stakeTogether address that has already been set.
  error StakeTogetherAlreadySet();

  /// @notice Thrown if the shares amount being claimed is zero.
  error ZeroAmount();

  /// @notice Thrown if the address trying to make a claim is the zero address.
  error ZeroAddress();

  /// @notice Emitted when Ether is received
  /// @param amount The amount of Ether received
  event ReceiveEther(uint256 indexed amount);

  /// @notice Emitted when Ether is received from Router
  /// @param amount The amount of Ether received
  event ReceiveWithdrawEther(uint256 indexed amount);

  /// @notice Emitted when the Router address is set
  /// @param router The address of the StakeTogether contract
  event SetRouter(address indexed router);

  /// @notice Emitted when the StakeTogether address is set
  /// @param stakeTogether The address of the StakeTogether contract
  event SetStakeTogether(address indexed stakeTogether);

  /// @notice Emitted when a user withdraws funds
  /// @param user The address of the user who is withdrawing
  /// @param amount The amount being withdrawn
  event Withdraw(address indexed user, uint256 amount);

  /// @notice Initialization function for Withdrawals contract.
  function initialize() external;

  /// @notice Pauses withdrawals.
  /// @dev Only callable by the admin role.
  function pause() external;

  /// @notice Unpauses withdrawals.
  /// @dev Only callable by the admin role.
  function unpause() external;

  /// @notice Receive function to accept incoming ETH transfers.
  receive() external payable;

  /// @notice Allows the router to send ETH to the contract.
  /// @dev This function can only be called by the router.
  function receiveWithdrawEther() external payable;

  /// @notice Transfers any extra amount of ETH in the contract to the StakeTogether fee address.
  /// @dev Only callable by the admin role and requires that extra amount exists in the contract balance.
  function transferExtraAmount() external;

  /// @notice Sets the StakeTogether contract address.
  /// @param _stakeTogether The address of the new StakeTogether contract.
  /// @dev Only callable by the admin role.
  function setStakeTogether(address _stakeTogether) external;

  /// @notice Sets the Router contract address.
  /// @param _router The address of the router.
  /// @dev Only callable by the admin role.
  function setRouter(address _router) external;

  /// @notice Mints tokens to a specific address.
  /// @param _to Address to receive the minted tokens.
  /// @param _amount Amount of tokens to mint.
  /// @dev Only callable by the StakeTogether contract.
  function mint(address _to, uint256 _amount) external;

  /// @notice Withdraws the specified amount of ETH, burning tokens in exchange.
  /// @param _amount Amount of ETH to withdraw.
  /// @dev The caller must have a balance greater or equal to the amount, and the contract must have sufficient ETH balance.
  function withdraw(uint256 _amount) external;

  /// @notice Checks if the contract is ready to withdraw the specified amount.
  /// @param _amount Amount of ETH to check.
  /// @return A boolean indicating if the contract has sufficient balance to withdraw the specified amount.
  function isWithdrawReady(uint256 _amount) external view returns (bool);

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
}
