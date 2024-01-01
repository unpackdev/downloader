// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20Upgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./ERC20FlashMintUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./EnumerableSet.sol";

error NotPausedAccount(address account);
error PausedAccount(address account);
error InvalidNonce(uint256 nonce);
error ExpiredDeadline(uint256 nonce);
error InvalidSigner(address signer);
error InsuficientBalance(uint256 balance, uint256 amount);

/// @custom:security-contact security@stamp.markets
contract STM is
  Initializable,
  ERC20Upgradeable,
  ERC20PausableUpgradeable,
  AccessControlUpgradeable,
  ERC20PermitUpgradeable,
  ERC20FlashMintUpgradeable,
  UUPSUpgradeable
{
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  // Events
  event AccountPaused(address indexed account);
  event AccountUnpaused(address indexed account);
  event Command(address indexed sender, uint256 value, string command);

  // Roles constatns
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
  bytes32 public constant TRANSFER_ROLE = keccak256('TRANSFER_ROLE');
  bytes32 public constant WITHDRAWER_ROLE = keccak256('WITHDRAWER_ROLE');
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

  // Delegated minting type hash
  bytes32 private constant _MINT_TYPEHASH = keccak256('Mint(uint256 amount,uint256 nonce,uint256 deadline)');
  EnumerableSet.UintSet private _nonces;

  // Paused accounts
  EnumerableSet.AddressSet private _pausedAccounts;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string memory name,
    string memory symbol,
    address defaultAdmin,
    address minter
  ) public initializer {
    __ERC20_init(name, symbol);
    __ERC20Permit_init(name);
    __ERC20Pausable_init();
    __AccessControl_init();
    __ERC20FlashMint_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    _grantRole(PAUSER_ROLE, defaultAdmin);
    _grantRole(BURNER_ROLE, defaultAdmin);
    _grantRole(TRANSFER_ROLE, defaultAdmin);
    _grantRole(WITHDRAWER_ROLE, defaultAdmin);
    _grantRole(UPGRADER_ROLE, defaultAdmin);
    _grantRole(MINTER_ROLE, minter);
  }

  /*
   *
   * Global contract pause
   *
   */

  /**
   * @dev Pauses the contract.
   *
   */
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Unpauses the contract.
   *
   */
  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /*
   *
   * Pause Accounts
   *
   */

  /**
   * @dev Modifier to make a function callable only when the account is paused.
   *
   * Used in the unpauseAccount function.
   */
  modifier onlyPaused(address account) {
    if (!_pausedAccounts.contains(account)) {
      revert NotPausedAccount(account);
    }

    _;
  }

  /**
   * @dev Modifier to make a function callable only when the account is not paused.
   *
   * Used in the pauseAccount function.
   *
   */
  modifier onlyNotPaused(address account) {
    if (_pausedAccounts.contains(account)) {
      revert PausedAccount(account);
    }

    _;
  }

  /**
   * @dev Modifier to make a function callable only when the account is not paused or sender has TRANSFER_ROLE.
   *
   * Used in any function that eventually calls the _update function in which onlyNotPausedOrTransferRole is enforced.
   *
   */
  modifier onlyNotPausedOrTransferRole(address account) {
    if (_pausedAccounts.contains(account) && !hasRole(TRANSFER_ROLE, msg.sender)) {
      revert PausedAccount(account);
    }

    _;
  }

  /**
   * @dev Pauses an account
   *
   * Will lock transfers for this account so it won't bea able to receive or send
   *
   * Requirements
   *  - account can't be already paused
   *
   * @param account The account to be paused
   */

  function pauseAccount(address account) public onlyRole(PAUSER_ROLE) onlyNotPaused(account) {
    _pausedAccounts.add(account);
    emit AccountPaused(account);
  }

  /**
   * @dev Unpauses an account
   *
   * Reverts the pauseAccount function
   *
   * Requirements
   *  - account must be an paused
   *
   * @param account The account to be unpaused
   */
  function unpauseAccount(address account) public onlyRole(PAUSER_ROLE) onlyPaused(account) {
    _pausedAccounts.remove(account);
    emit AccountUnpaused(account);
  }

  /**
   * @dev Predicate which returns true if the account is paused
   *
   * @param account The account to be checked
   * @return True if the account is paused
   */
  function isAccountPaused(address account) public view returns (bool) {
    return _pausedAccounts.contains(account);
  }

  /**
   * @dev Returns the number of paused accounts
   *
   * @return How many accounts are paused
   */
  function pausedAccountsLength() public view returns (uint256) {
    return _pausedAccounts.length();
  }

  /**
   * @dev Getter of the paused accounts
   *
   * @return The paused accounts
   */
  function pausedAccounts() public view returns (address[] memory) {
    return _pausedAccounts.values();
  }

  /*
   *
   * Minting
   *
   */

  /**
   * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
   * Relies on the `_update` mechanism
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   */
  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  /**
   * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
   * Relies on the `_update` mechanism
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * - nonce must not have been previously used
   * - deadline must be lower than the current block.timestamp
   * - v,r,s must corresponds to a signature done by a MINTER_ROLE account
   *
   */
  function mint(uint256 amount, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
    // nonce must be unique and should not have been used before
    if (_nonces.contains(nonce)) {
      revert InvalidNonce(nonce);
    }

    // If deadline is zero it's not taken into account
    if (deadline > 0 && block.timestamp > deadline) {
      revert ExpiredDeadline(deadline);
    }

    bytes32 structHash = keccak256(abi.encode(_MINT_TYPEHASH, amount, nonce, deadline));

    bytes32 hash = _hashTypedDataV4(structHash);

    address signer = ECDSA.recover(hash, v, r, s);

    // Only MINTER_ROLE signed mints are allowed
    if (!hasRole(MINTER_ROLE, signer)) {
      revert InvalidSigner(signer);
    }

    // Burn the nonce so this signed message can't be used anymore
    _nonces.add(nonce);

    _mint(msg.sender, amount);
  }

  /*
   *
   * Burn
   *
   */

  /**
   * @dev Destroys a `value` amount of tokens from the caller.
   *
   * See {ERC20-_burn}.
   *
   * * Requirements:
   *
   * - The caller must have the BURNER_ROLE.
   */
  function burn(uint256 value) public onlyRole(BURNER_ROLE) {
    _burn(_msgSender(), value);
  }

  /**
   * @dev Destroys a `value` amount of tokens from `account`, deducting from
   * the caller's allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - The caller must have the BURNER_ROLE.
   */
  function burnFrom(address account, uint256 value) public onlyRole(BURNER_ROLE) {
    _spendAllowance(account, _msgSender(), value);
    _burn(account, value);
  }

  /*
   *
   * Forced transfer
   *
   */

  function forcedTransfer(address from, address to, uint256 value) public onlyRole(TRANSFER_ROLE) {
    _transfer(from, to, value);
  }

  /*
   *
   * Commands and withdraw
   *
   */

  /**
   * @dev Emmits a command event
   */
  function command(string memory command_) external payable {
    emit Command(msg.sender, msg.value, command_);
  }

  /**
   * @dev Withdraws contract ether to the recipient
   */
  function withdraw(address payable recipient, uint256 amount) external onlyRole(WITHDRAWER_ROLE) {
    if (address(this).balance < amount) {
      revert InsuficientBalance(address(this).balance, amount);
    }

    recipient.transfer(amount);
  }

  /*
   *
   * Upgrade
   *
   */

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  /*
   *
   * Update
   *
   */

  function _update(
    address from,
    address to,
    uint256 value
  )
    internal
    override(ERC20Upgradeable, ERC20PausableUpgradeable)
    onlyNotPausedOrTransferRole(from)
    onlyNotPausedOrTransferRole(to)
  {
    super._update(from, to, value);
  }
}
