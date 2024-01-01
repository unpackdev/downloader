// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC4906.sol";

contract StandardERC721 is ERC721, Pausable, AccessControl, ERC2981, IERC4906, Ownable {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
  string private _uri;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory uri_
  ) ERC721(name_, symbol_) {
    _uri = uri_;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _uri = newuri;
  }

  function _baseURI() internal view override returns (string memory) {
    return _uri;
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(to, tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC2981, AccessControl, IERC165) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }

  /**
   * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
   */
  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @dev External onlyOwner version of {ERC2981-_deleteDefaultRoyalty}.
   */
  function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _deleteDefaultRoyalty();
  }

  /**
   * @dev External onlyOwner version of {ERC2981-_setTokenRoyalty}.
   */
  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  /**
   * @dev External onlyOwner version of {ERC2981-_resetTokenRoyalty}.
   */
  function resetTokenRoyalty(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _resetTokenRoyalty(tokenId);
  }

  function emitMetadataUpdate(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // Emit an event with the update.
    emit MetadataUpdate(tokenId);
  }

  function emitBatchMetadataUpdate(
    uint256 fromTokenId,
    uint256 toTokenId
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // Emit an event with the update.
    emit BatchMetadataUpdate(fromTokenId, toTokenId);
  }
}
