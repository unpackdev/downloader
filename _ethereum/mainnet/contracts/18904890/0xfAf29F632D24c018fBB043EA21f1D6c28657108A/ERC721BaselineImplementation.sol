// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./ERC721Upgradeable.sol";
import "./IERC165.sol";
import "./IERC721Baseline.sol";
import "./IERC721Receiver.sol";
import "./Utils.sol";

/**
 * @title ERC721BaselineImplementation
 * @custom:version v0.1.0
 * @notice A baseline ERC721 contract implementation that exposes internal methods to a proxy instance.
 */
contract ERC721BaselineImplementation is ERC721Upgradeable, IERC721Baseline {

  /**
   * @dev ERC721Baseline uses ERC-7201 (Namespaced Storage Layout)
   * to prevent collisions with the proxies storage.
   * See https://eips.ethereum.org/EIPS/eip-7201.
   *
   * Proxies are encouraged, but not required, to use a similar pattern for storage.
   *
   * @custom:storage-location erc7201:erc721baseline.implementation.storage
   */
  struct ERC721BaselineStorage {
    string VERSION;

    /**
     * Metadata
     */
    uint256 totalSupply;

    mapping(uint256 => string) __tokenURI;
    string __sharedURI;
    string __baseURI;

    /**
     * Royalties
     */
    address payable _royaltiesReceiver;
    uint16 _royaltiesBps;

    /**
     * @dev Tracks whether the proxy's `_beforeTokenTransfer` hook is enabled or not.
     * When enabled, this contract will call the hook when ERC721 calls `_update`.
     */
    bool _beforeTokenTransferHookEnabled;

    /**
     * Access Control
     */

    /**
     * @dev Tracks the contract admins.
     */
    mapping(address => bool) _admins;
    /**
     * @dev Tracks the contract owner.
     */
    address _owner;
  }

  /**
   * @dev The ERC7-201 storage slot. See https://eips.ethereum.org/EIPS/eip-7201.
   * The namespace is:
   * erc721baseline.implementation.storage
   * keccak256(abi.encode(uint256(keccak256("erc721baseline.implementation.storage")) - 1)) & ~bytes32(uint256(0xff))
   */
  bytes32 private constant ERC721BaselineStorageLocation = 0xd70e9a647412bf72add39fd1ab5a6a89bfb0d778061be5e3d13cfa60d9d90b00;

  /**
   * @dev Convenience method to access the storage at ERC721BaselineStorageLocation location.
   *
   * Usage:
   *
   *  ERC721BaselineStorage storage $ = _getStorage();
   *
   *  if ($._royaltiesReceiver != address(0)) {
   *    $._royaltiesReceiver = address(0);
   *  }
   *
   * @return $ a reference to the storage at ERC721BaselineStorageLocation location for reading and writing
   */
  function _getStorage() private pure returns (ERC721BaselineStorage storage $) {
    assembly {
      $.slot := ERC721BaselineStorageLocation
    }
  }

  constructor() {
    _getStorage().VERSION = "0.1.0";
    _disableInitializers();
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function VERSION() external view returns (string memory) {
    return _getStorage().VERSION;
  }

  /**
   * @notice Enables a proxy to call selected methods that are implemented in this contract.
   * @dev Throws if called by any account other than the proxy contract itself.
   */
  modifier onlyProxy {
    if (_msgSender() != address(this)) {
      revert NotProxy();
    }
    _;
  }


  /************************************************
   * Supported Interfaces
   ************************************************/

  /**
   * @inheritdoc IERC165
   */
  function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721Upgradeable) returns (bool) {
    return (
      interfaceId == /* NFT Royalty Standard */ bytes4(0x2a55205a) ||
      interfaceId == /* Metadata Update Extension */ bytes4(0x49064906) ||
      interfaceId == type(IERC721Baseline).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }


  /************************************************
   * Initializer
   ************************************************/

  /**
   * @inheritdoc IERC721Baseline
   */
  function initialize(string memory name, string memory symbol) external initializer {
    __ERC721_init(name, symbol);
    _setAdmin(_msgSender(), true);
    _transferOwnership(_msgSender());
  }


  /************************************************
   * Metadata
   ************************************************/

  /**
   * @inheritdoc IERC721Baseline
   */
  function totalSupply() external view returns (uint256) {
    return _getStorage().totalSupply;
  }

  /**
   * Metadata > Token URI
   */

  /**
   * @inheritdoc IERC721Baseline
   */
  function __tokenURI(uint256 tokenId) external view returns (string memory) {
    return _getStorage().__tokenURI[tokenId];
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __setTokenURI(uint256 tokenId, string calldata tokenURI) external onlyProxy {
    _getStorage().__tokenURI[tokenId] = tokenURI;
    emit MetadataUpdate(tokenId);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __sharedURI() external view returns (string memory) {
    return _getStorage().__sharedURI;
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __setSharedURI(string calldata sharedURI) external onlyProxy {
    _getStorage().__sharedURI = sharedURI;
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __baseURI() external view returns (string memory) {
    return _getStorage().__baseURI;
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __setBaseURI(string calldata baseURI) external onlyProxy {
    _getStorage().__baseURI = baseURI;
  }

  /**
   * @notice Returns the URI associated with a token ID.
   *
   * @dev The tokenURI implementation allows to define uris in the following order:
   *
   * 1. Token-specific URI by ID.
   * 2. Shared URI.
   * 3. Shared base URI + token ID.
   * 4. Empty string if none of the above was found.
   *
   * @param tokenId token ID
   * @return string the token URI
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireOwned(tokenId);

    ERC721BaselineStorage storage $ = _getStorage();

    string memory uri = $.__tokenURI[tokenId];

    if (bytes(uri).length > 0) {
      return uri;
    }

    if (bytes($.__sharedURI).length > 0) {
      return $.__sharedURI;
    }

    if (bytes($.__baseURI).length > 0) {
      return string.concat($.__baseURI, Utils.toString(tokenId));
    }

    return "";
  }

  /************************************************
   * Royalties
   ************************************************/

  /**
   * @inheritdoc IERC721Baseline
   */
  function royaltiesReceiver() external view returns (address) {
    return _getStorage()._royaltiesReceiver;
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function royaltiesBps() external view returns (uint256) {
    return _getStorage()._royaltiesBps;
  }

  /**
   * @dev See {IERC2981-royaltyInfo}.
   */
  function royaltyInfo(
    uint256,
    uint256 salePrice
  ) external view returns (address, uint256) {
    ERC721BaselineStorage storage $ = _getStorage();

    if ($._royaltiesBps > 0 && $._royaltiesReceiver != address(0)) {
      return ($._royaltiesReceiver, salePrice * $._royaltiesBps / 10000);
    }

    return (address(0), 0);
  }

  function _configureRoyalties(address payable receiver, uint16 bps) internal {
    ERC721BaselineStorage storage $ = _getStorage();

    if (receiver != $._royaltiesReceiver) {
      $._royaltiesReceiver = receiver;
    }

    if (bps != $._royaltiesBps) {
      $._royaltiesBps = bps;
    }
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function configureRoyalties(address payable receiver, uint16 bps) external {
    this.requireAdmin(_msgSender());
    _configureRoyalties(receiver, bps);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __configureRoyalties(address payable receiver, uint16 bps) external onlyProxy {
    _configureRoyalties(receiver, bps);
  }

  /************************************************
   * Internal ERC721 methods exposed to the proxy
   ************************************************/

  /**
   * @inheritdoc IERC721Baseline
   */
  function __ownerOf(uint256 tokenId) external view returns (address) {
    return _ownerOf(tokenId);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __update(address to, uint256 tokenId, address auth) external onlyProxy returns (address) {
    return super._update(to, tokenId, auth);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __mint(address to, uint256 tokenId) external onlyProxy {
    _getStorage().totalSupply += 1;
    _mint(to, tokenId);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __mint(address to, uint256 tokenId, string calldata tokenURI) external onlyProxy {
    ERC721BaselineStorage storage $ = _getStorage();

    $.totalSupply += 1;
    $.__tokenURI[tokenId] = tokenURI;
    _mint(to, tokenId);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __burn(uint256 tokenId) external onlyProxy {
    ERC721BaselineStorage storage $ = _getStorage();

    $.totalSupply -= 1;
    if (bytes($.__tokenURI[tokenId]).length > 0) {
      delete $.__tokenURI[tokenId];
    }
    _burn(tokenId);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __transfer(address from, address to, uint256 tokenId) external onlyProxy {
    _transfer(from, to, tokenId);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __setBeforeTokenTransferHookEnabled(bool enabled) external onlyProxy {
    _getStorage()._beforeTokenTransferHookEnabled = enabled;
  }

  /**
   * @dev See {ERC721-_update}.
   * @dev Allows to define a `_beforeTokenTransfer` hook method in the proxy contract that is called when `_beforeTokenTransferHookEnabled` is `true`.
   *
   * The proxy's `_beforeTokenTransfer` method is called with the following params:
   *
   * - address the transaction's _msgSender()
   * - address from
   * - address to
   * - uint256 tokenId
   */
  function _update(
    address to,
    uint256 tokenId,
    address auth
  ) internal override returns (address) {
    if (_getStorage()._beforeTokenTransferHookEnabled == true) {
      (bool success, bytes memory reason) = address(this).delegatecall(
        abi.encodeWithSignature(
          "_beforeTokenTransfer(address,address,address,uint256)",
          _msgSender(),
          _ownerOf(tokenId),
          to,
          tokenId
        )
      );

      if (success == false) {
        if (reason.length == 0) revert("_beforeTokenTransfer");
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }

    return super._update(to, tokenId, auth);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __checkOnERC721Received(
    address sender,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) external {
    _checkOnERC721Received(sender, from, to, tokenId, data);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __isAuthorized(address owner, address spender, uint256 tokenId) external view returns (bool) {
    return _isAuthorized(owner, spender, tokenId);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __approve(address to, uint256 tokenId, address auth, bool emitEvent) external onlyProxy {
    _approve(to, tokenId, auth, emitEvent);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __setApprovalForAll(address owner, address operator, bool approved) external onlyProxy {
    _setApprovalForAll(owner, operator, approved);
  }


  /************************************************
   * Access control
   ************************************************/

  /**
   * Implements a multi-admin system and a minimal Ownable-compatible API.
   */

  /**
   * Access control > multi-admin system
   */

  /**
   * @dev Internal method: checks if an address is the contract owner or an admin.
   *
   * @param addr address to check
   * @return bool whether the address is an admin or not
   */
  function _isAdmin(address addr) internal view returns (bool) {
    ERC721BaselineStorage storage $ = _getStorage();
    return $._owner == addr || $._admins[addr] == true;
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function isAdmin(address addr) external view returns (bool) {
    return _isAdmin(addr);
  }

  /**
   * @dev Internal method: allows to add or remove an admin.
   *
   * @param addr address to add or remove
   * @param add boolean indicating whether the address should be granted or revoked rights
   */
  function _setAdmin(address addr, bool add) internal {
    if (add) {
      _getStorage()._admins[addr] = true;
    } else {
      delete _getStorage()._admins[addr];
    }
    emit AdminSet(addr, add);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function setAdmin(address addr, bool add) external {
    this.requireAdmin(_msgSender());
    _setAdmin(addr, add);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __setAdmin(address addr, bool add) external onlyProxy {
    _setAdmin(addr, add);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function requireAdmin(address addr) external view {
    if (_isAdmin(addr) == false) {
      revert Unauthorized();
    }
  }

  /**
   * Access control > Ownable-compatible API.
   */

  /**
   * @inheritdoc IERC721Baseline
   */
  function owner() external view returns (address) {
    return _getStorage()._owner;
  }

  /**
   * @dev Internal method: transfers ownership of the contract to a new account.
   *
   * @param newOwner new owner address
   */
  function _transferOwnership(address newOwner) internal {
    ERC721BaselineStorage storage $ = _getStorage();
    address oldOwner = $._owner;
    $._owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function transferOwnership(address newOwner) external {
    this.requireAdmin(_msgSender());
    _transferOwnership(newOwner);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function __transferOwnership(address newOwner) external onlyProxy {
    _transferOwnership(newOwner);
  }


  /************************************************
   * Utils
   ************************************************/

  /**
   * @inheritdoc IERC721Baseline
   */
  function recover(bytes32 hash, bytes memory signature) external view returns (address) {
    return Utils.recover(Utils.toEthSignedMessageHash(hash), signature);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function recoverCalldata(bytes32 hash, bytes calldata signature) external view returns (address) {
    return Utils.recoverCalldata(Utils.toEthSignedMessageHash(hash), signature);
  }

  /**
   * @inheritdoc IERC721Baseline
   */
  function toString(uint256 value) external pure returns (string memory) {
    return Utils.toString(value);
  }

}
