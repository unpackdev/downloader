// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721Upgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./EnumerableSet.sol";
import "./ECDSA.sol";

error NotPausedAccount(address account);
error PausedAccount(address account);
error InvalidNonce(uint256 nonce);
error ExpiredDeadline(uint256 nonce);
error InvalidSigner(address signer);
error InsuficientBalance(uint256 balance, uint256 amount);

/// @custom:security-contact security@stamp.markets
contract Stamp is
  Initializable,
  ERC721Upgradeable,
  ERC721PausableUpgradeable,
  AccessControlUpgradeable,
  EIP712Upgradeable,
  UUPSUpgradeable
{
  using Strings for uint256;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  // Events
  event URISet(string uri);
  event AccountPaused(address indexed account);
  event AccountUnpaused(address indexed account);
  event TokenPaused(uint256 indexed tokenId);
  event TokenUnpaused(uint256 indexed tokenId);
  event Command(address indexed sender, uint256 value, string command);

  // Roles constants
  bytes32 public constant URI_SETTER_ROLE = keccak256('URI_SETTER_ROLE');
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
  bytes32 public constant TRANSFER_ROLE = keccak256('TRANSFER_ROLE');
  bytes32 public constant WITHDRAWER_ROLE = keccak256('WITHDRAWER_ROLE');
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

  // Delegated minting type hash
  bytes32 private constant _SAFE_MINT_TYPEHASH = keccak256('SafeMint(uint256 tokenId,uint256 nonce,uint256 deadline)');
  EnumerableSet.UintSet private _nonces;

  // Stamps URI
  string private _uri;

  // Paused accounts
  EnumerableSet.AddressSet private _pausedAccounts;

  // Paused tokens
  EnumerableSet.UintSet private _pausedTokens;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string memory name,
    string memory symbol,
    string memory uri,
    address defaultAdmin,
    address minter
  ) public initializer {
    __ERC721_init(name, symbol);
    __EIP712_init(name, '1');
    __ERC721Pausable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    // Sets the uri
    _uri = uri;
    emit URISet(uri);

    _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    _grantRole(URI_SETTER_ROLE, defaultAdmin);
    _grantRole(PAUSER_ROLE, defaultAdmin);
    _grantRole(BURNER_ROLE, defaultAdmin);
    _grantRole(TRANSFER_ROLE, defaultAdmin);
    _grantRole(WITHDRAWER_ROLE, defaultAdmin);
    _grantRole(UPGRADER_ROLE, defaultAdmin);
    _grantRole(MINTER_ROLE, minter);
  }

  /*
   *
   * Stamps URI
   *
   */

  /**
   * @dev Sets the base Uniform Resource Identifier (URI) for all tokens.
   */
  function setURI(string memory uri) public onlyRole(URI_SETTER_ROLE) {
    _uri = uri;

    emit URISet(uri);
  }

  /**
   * @dev Returns the base Uniform Resource Identifier (URI) for all tokens.
   */
  function getURI() public view returns (string memory) {
    return _uri;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireOwned(tokenId);

    return bytes(_uri).length > 0 ? string.concat(_uri, tokenId.toString(), '.json') : '';
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
   *
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
   * Used in any function that eventually calls the _update function in which onlyNotPaused is enforced.
   *
   */
  modifier onlyNotPaused(address account) {
    if (_pausedAccounts.contains(account)) {
      revert PausedAccount(account);
    }

    _;
  }

  /**
   * @dev Pauses an account
   *
   * Will lock the transfers for this account so it won't bea able to receive or send any token
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
   *  - account must be a paused account
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
   * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
   *
   * Requirements:
   *
   * - msg.sender must have MINTER_ROLE
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(to, tokenId);
  }

  /**
   * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
   *
   * Requirements:
   *
   * - nonce must not have been previously used
   * - deadline must be lower than the current block.timestamp
   * - v,r,s must corresponds to a signature done by a MINTER_ROLE account
   * - tokenId must not exist.
   * - the token will be assigned to msg.sender
   * - if msg.sender refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeMint(uint256 tokenId, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
    // nonce must be unique and should not have been used before
    if (_nonces.contains(nonce)) {
      revert InvalidNonce(nonce);
    }

    // If deadline is zero it's not taken into account
    if (deadline > 0 && block.timestamp > deadline) {
      revert ExpiredDeadline(deadline);
    }

    bytes32 structHash = keccak256(abi.encode(_SAFE_MINT_TYPEHASH, tokenId, nonce, deadline));

    bytes32 hash = _hashTypedDataV4(structHash);

    address signer = ECDSA.recover(hash, v, r, s);

    // Only MINTER_ROLE signed mints are allowed
    if (!hasRole(MINTER_ROLE, signer)) {
      revert InvalidSigner(signer);
    }

    // Burn the nonce so this signed message can't be used anymore
    _nonces.add(nonce);

    _safeMint(msg.sender, tokenId);
  }

  /*
   *
   * Burning
   *
   */

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must have the BURNER_ROLE.
   */
  function burn(uint256 tokenId) public onlyRole(BURNER_ROLE) {
    // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
    // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
    address previousOwner = _update(address(0), tokenId, _msgSender());

    if (previousOwner == address(0)) {
      revert ERC721NonexistentToken(tokenId);
    }
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

  /**
   * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
   * particular (ignoring whether it is owned by `owner`).
   *
   * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
   * assumption.
   *
   */
  function _isAuthorized(address owner, address spender, uint256 tokenId) internal view override returns (bool) {
    return
      spender != address(0) &&
      (owner == spender ||
        isApprovedForAll(owner, spender) ||
        _getApproved(tokenId) == spender ||
        hasRole(TRANSFER_ROLE, msg.sender));
  }

  function _update(
    address to,
    uint256 tokenId,
    address auth
  )
    internal
    override(ERC721Upgradeable, ERC721PausableUpgradeable)
    onlyNotPaused(to)
    onlyNotPaused(auth)
    returns (address)
  {
    return super._update(to, tokenId, auth);
  }

  function _increaseBalance(address account, uint128 value) internal override(ERC721Upgradeable) {
    super._increaseBalance(account, value);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparatorV4();
  }
}
