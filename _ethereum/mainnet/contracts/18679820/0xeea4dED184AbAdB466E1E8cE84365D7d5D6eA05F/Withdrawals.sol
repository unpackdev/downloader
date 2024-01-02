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
import "./Address.sol";

import "./IRouter.sol";
import "./IStakeTogether.sol";
import "./IWithdrawals.sol";

/// @title Withdrawals Contract for StakeTogether
/// @notice The Withdrawals contract handles all withdrawal-related activities within the StakeTogether protocol.
/// It allows users to withdraw their staked tokens and interact with the associated stake contracts.
/// @custom:security-contact security@staketogether.org
contract Withdrawals is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  ERC20PermitUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  IWithdrawals
{
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE'); /// Role for managing upgrades.
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); /// Role for administration.

  uint256 public version; /// Contract version.
  IStakeTogether public stakeTogether; /// Instance of the StakeTogether contract.
  IRouter public router; /// Instance of the Router contract.
  mapping(address => uint256) private lastOperationBlock; // Mapping of addresses to their last operation block.

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialization function for Withdrawals contract.
  function initialize() external initializer {
    __ERC20_init('Stake Together Withdrawals', 'stwETH');
    __ERC20Burnable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __AccessControl_init();
    __ERC20Permit_init('Stake Together Withdrawals');
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    version = 1;
  }

  /// @notice Pauses withdrawals.
  /// @dev Only callable by the admin role.
  function pause() external onlyRole(ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpauses withdrawals.
  /// @dev Only callable by the admin role.
  function unpause() external onlyRole(ADMIN_ROLE) {
    _unpause();
  }

  /// @notice Internal function to authorize an upgrade.
  /// @param _newImplementation Address of the new contract implementation.
  /// @dev Only callable by the upgrader role.
  function _authorizeUpgrade(address _newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  /// @notice Receive function to accept incoming ETH transfers.
  receive() external payable {
    emit ReceiveEther(msg.value);
  }

  modifier nonFlashLoan() {
    if (block.number <= lastOperationBlock[msg.sender]) {
      revert FlashLoan();
    }
    _;
  }

  /// @notice Allows the router to send ETH to the contract.
  /// @dev This function can only be called by the router.
  function receiveWithdrawEther() external payable {
    if (msg.sender != address(router)) revert OnlyRouter();
    emit ReceiveWithdrawEther(msg.value);
  }

  /// @notice Transfers any extra amount of ETH in the contract to the StakeTogether fee address.
  /// @dev Only callable by the admin role. Requires that extra amount exists in the contract balance.
  function transferExtraAmount() external whenNotPaused nonReentrant onlyRole(ADMIN_ROLE) {
    uint256 extraAmount = address(this).balance - totalSupply();
    if (extraAmount <= 0) revert NoExtraAmountAvailable();
    address stakeTogetherFee = stakeTogether.getFeeAddress(IStakeTogether.FeeRole.StakeTogether);
    Address.sendValue(payable(stakeTogetherFee), extraAmount);
  }

  /// @notice Sets the StakeTogether contract address.
  /// @param _stakeTogether The address of the new StakeTogether contract.
  /// @dev Only callable by the admin role.
  function setStakeTogether(address _stakeTogether) external onlyRole(ADMIN_ROLE) {
    if (address(stakeTogether) != address(0)) revert StakeTogetherAlreadySet();
    if (_stakeTogether == address(0)) revert ZeroAddress();
    stakeTogether = IStakeTogether(payable(_stakeTogether));
    emit SetStakeTogether(_stakeTogether);
  }

  /// @notice Sets the Router contract address.
  /// @param _router The address of the router.
  /// @dev Only callable by the admin role.
  function setRouter(address _router) external onlyRole(ADMIN_ROLE) {
    if (address(router) != address(0)) revert RouterAlreadySet();
    if (_router == address(0)) revert ZeroAddress();
    router = IRouter(payable(_router));
    emit SetRouter(_router);
  }

  /****************
   ** ANTI-FRAUD **
   ****************/

  /// @notice Transfers an amount of wei to the specified address.
  /// @param _to The address to transfer to.
  /// @param _amount The amount to be transferred.
  /// @return True if the transfer was successful.
  function transfer(
    address _to,
    uint256 _amount
  ) public override(ERC20Upgradeable, IWithdrawals) returns (bool) {
    if (stakeTogether.isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
    if (stakeTogether.isListedInAntiFraud(_to)) revert ListedInAntiFraud();
    if (block.number < stakeTogether.getWithdrawBeaconBlock(msg.sender)) revert EarlyBeaconTransfer();
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
  ) public override(ERC20Upgradeable, IWithdrawals) returns (bool) {
    if (stakeTogether.isListedInAntiFraud(_from)) revert ListedInAntiFraud();
    if (stakeTogether.isListedInAntiFraud(_to)) revert ListedInAntiFraud();
    if (stakeTogether.isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
    if (block.number < stakeTogether.getWithdrawBeaconBlock(_from)) revert EarlyBeaconTransfer();
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
    lastOperationBlock[msg.sender] = block.number;
    super._update(_from, _to, _amount);
  }

  /**************
   ** WITHDRAW **
   **************/

  /// @notice Mints tokens to a specific address.
  /// @param _to Address to receive the minted tokens.
  /// @param _amount Amount of tokens to mint.
  /// @dev Only callable by the StakeTogether contract.
  function mint(address _to, uint256 _amount) external {
    if (msg.sender != address(stakeTogether)) revert OnlyStakeTogether();
    _mint(_to, _amount);
  }

  /// @notice Withdraws the specified amount of ETH, burning tokens in exchange.
  /// @param _amount Amount of ETH to withdraw.
  /// @dev The caller must have a balance greater or equal to the amount, and the contract must have sufficient ETH balance.
  function withdraw(uint256 _amount) external nonFlashLoan whenNotPaused {
    if (stakeTogether.isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
    if (address(this).balance < _amount) revert InsufficientEthBalance();
    if (balanceOf(msg.sender) < _amount) revert InsufficientStwBalance();
    if (_amount <= 0) revert ZeroAmount();
    if (block.number < stakeTogether.getWithdrawBeaconBlock(msg.sender)) revert EarlyBeaconTransfer();
    emit Withdraw(msg.sender, _amount);
    _burn(msg.sender, _amount);
    Address.sendValue(payable(msg.sender), _amount);
    lastOperationBlock[msg.sender] = block.number;
  }

  /// @notice Checks if the contract is ready to withdraw the specified amount.
  /// @param _amount Amount of ETH to check.
  /// @return A boolean indicating if the contract has sufficient balance to withdraw the specified amount.
  function isWithdrawReady(uint256 _amount) external view returns (bool) {
    if (stakeTogether.isListedInAntiFraud(msg.sender)) return false;
    return address(this).balance >= _amount;
  }
}
