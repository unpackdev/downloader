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

import "./IStakeTogether.sol";
import "./IStakeTogetherWrapper.sol";

/// @title StakeTogether Wrapper Pool Contract
/// @notice The StakeTogether contract is the primary entry point for interaction with the StakeTogether protocol.
/// It provides functionalities for staking, withdrawals, fee management, and interactions with pools and validators.
/// @custom:security-contact security@staketogether.org
contract StakeTogetherWrapper is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  ERC20PermitUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  IStakeTogetherWrapper
{
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE'); /// Role for managing upgrades.
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); /// Role for administration.

  uint256 public version; /// Contract version.
  IStakeTogether public stakeTogether; /// Instance of the StakeTogether contract.
  mapping(address => uint256) private lastOperationBlock; // Mapping of addresses to their last operation block.

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() external initializer {
    __ERC20_init('Wrapped Stake Together Protocol', 'wstpETH');
    __ERC20Burnable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __AccessControl_init();
    __ERC20Permit_init('Wrapped Stake Together Protocol');
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    version = 1;
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

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

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

  /// @notice Transfers any extra amount of ETH in the contract to the StakeTogether fee address.
  /// @dev Only callable by the admin role. Requires that extra amount exists in the contract balance.
  function transferExtraAmount() external whenNotPaused nonReentrant onlyRole(ADMIN_ROLE) {
    uint256 extraAmount = address(this).balance;
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
  ) public override(ERC20Upgradeable, IStakeTogetherWrapper) returns (bool) {
    if (stakeTogether.isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
    if (stakeTogether.isListedInAntiFraud(_to)) revert ListedInAntiFraud();
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
  ) public override(ERC20Upgradeable, IStakeTogetherWrapper) returns (bool) {
    if (stakeTogether.isListedInAntiFraud(_from)) revert ListedInAntiFraud();
    if (stakeTogether.isListedInAntiFraud(_to)) revert ListedInAntiFraud();
    if (stakeTogether.isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
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

  /*************
   ** WRAPPER **
   *************/

  /// @notice Wraps the given amount of stpETH into wstpETH.
  /// @dev Reverts if the sender is on the anti-fraud list, or if the _stpETH amount is zero.
  /// @param _stpETH The amount of stpETH to wrap.
  /// @return The amount of wstpETH minted.
  function wrap(uint256 _stpETH) external nonFlashLoan returns (uint256) {
    if (_stpETH == 0) revert ZeroStpETHAmount();
    if (stakeTogether.isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
    uint256 wstpETHAmount = stakeTogether.sharesByWei(_stpETH);
    if (wstpETHAmount == 0) revert ZeroWstpETHAmount();
    _mint(msg.sender, wstpETHAmount);
    lastOperationBlock[msg.sender] = block.number;
    emit Wrapped(msg.sender, _stpETH, wstpETHAmount);
    bool success = stakeTogether.transferFrom(msg.sender, address(this), _stpETH);
    if (!success) revert TransferStpEthFailed();
    return wstpETHAmount;
  }

  /// @notice Unwraps the given amount of wstpETH into stpETH.
  /// @dev Reverts if the sender is on the anti-fraud list, or if the _wstpETH amount is zero.
  /// @param _wstpETH The amount of wstpETH to unwrap.
  /// @return The amount of stpETH received.
  function unwrap(uint256 _wstpETH) external nonFlashLoan returns (uint256) {
    if (_wstpETH == 0) revert ZeroWstpETHAmount();
    if (stakeTogether.isListedInAntiFraud(msg.sender)) revert ListedInAntiFraud();
    uint256 stpETHAmount = stakeTogether.weiByShares(_wstpETH);
    if (stpETHAmount == 0) revert ZeroStpETHAmount();
    _burn(msg.sender, _wstpETH);
    lastOperationBlock[msg.sender] = block.number;
    emit Unwrapped(msg.sender, _wstpETH, stpETHAmount);
    bool success = stakeTogether.transfer(msg.sender, stpETHAmount);
    if (!success) revert TransferStpEthFailed();
    return stpETHAmount;
  }

  /// @notice Calculates the current exchange rate of stpETH per wstpETH.
  /// @dev Returns zero if the total supply of wstpETH is zero.
  /// @param _wstpETH The amount of wstpETH to calculate.
  /// @return The current rate of stpETH per wstpETH.
  function stpEthPerWstpETH(uint256 _wstpETH) external view returns (uint256) {
    if (_wstpETH == 0) return 0;
    if (totalSupply() == 0) return 0;
    return stakeTogether.weiByShares(_wstpETH);
  }

  /// @notice Calculates the current exchange rate of wstpETH per stpETH.
  /// @dev Returns zero if the balance of stpETH is zero.
  /// @param _stpETH The amount of wstpETH to calculate.
  /// @return The current rate of wstpETH per stpETH.
  function wstpETHPerStpETH(uint256 _stpETH) external view returns (uint256) {
    if (_stpETH == 0) return 0;
    return stakeTogether.sharesByWei(_stpETH);
  }
}
