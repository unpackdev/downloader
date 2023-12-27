// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ECDSA.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721ReadOnly.sol";

contract CoolBoundToken is ERC721ReadOnly, Ownable, Pausable {
  using ECDSA for bytes32;

  address public _systemAddress;
  string public _baseTokenUri;
  string public _contractUri;

  mapping(address => bool) public _minted;

  error AlreadyMinted();
  error InvalidSignature();
  error OnlyEOA();

  event BaseURIUpdated(string baseURI);
  event ContractUriUpdated(string contractUri);
  event SystemAddressSet(address systemAddress);

  constructor(
    string memory name,
    string memory symbol,
    string memory baseUri,
    string memory contractUri,
    address systemAddress
  ) ERC721ReadOnly(name, symbol) {
    _baseTokenUri = baseUri;
    _contractUri = contractUri;
    _systemAddress = systemAddress;

    _pause();
  }

  function mintSoulbound(bytes calldata signature) external whenNotPaused {
    if (msg.sender != tx.origin) revert OnlyEOA();
    if (_minted[msg.sender]) revert AlreadyMinted();
    if (!_isValidSignature(keccak256(abi.encodePacked(msg.sender, address(this))), signature))
      revert InvalidSignature();

    _minted[msg.sender] = true;

    _safeMint(msg.sender, uint256(uint160(msg.sender)));
  }

  /// @notice Returns the contract URI for storefront level metadata
  /// @dev Ref. https://docs.opensea.io/docs/contract-level-metadata
  /// @return The contract URI
  function contractURI() external view virtual returns (string memory) {
    return _contractUri;
  }

  /// @notice Pauses the contract - stopping minting via the public mint function
  /// @dev Only the owner can call this function
  ///      Emit handled by {OpenZeppelin Pausable}
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpauses the contract - allowing minting via the public mint function
  /// @dev Only the owner can call this function
  ///      Emit handled by {OpenZeppelin Pausable}
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice Sets the base URI for the tokens
  /// @dev Only the owner can call this function
  /// @param baseUri The base URI to set
  function setBaseUri(string memory baseUri) external onlyOwner {
    _baseTokenUri = baseUri;

    emit BaseURIUpdated(baseUri);
  }

  /// @notice Set contract URI
  /// @param contractUri contract URI for storefront level metadata
  function setContactURI(string memory contractUri) external onlyOwner {
    _contractUri = contractUri;

    emit ContractUriUpdated(contractUri);
  }

  /// @notice Sets the system address for signature verification
  /// @dev Only the owner can call this function
  /// @param systemAddress The address of the system
  function setSystemAddress(address systemAddress) external onlyOwner {
    _systemAddress = systemAddress;

    emit SystemAddressSet(systemAddress);
  }

  /// @notice Returns the base URI for the tokens
  /// @dev Required override for ERC721 to use the base URI
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenUri;
  }

  /// @notice Verify hashed data
  /// @param hash - Hashed data bundle
  /// @param signature - Signature to check hash against
  /// @return bool - Is verified or not
  function _isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == _systemAddress;
  }
}
