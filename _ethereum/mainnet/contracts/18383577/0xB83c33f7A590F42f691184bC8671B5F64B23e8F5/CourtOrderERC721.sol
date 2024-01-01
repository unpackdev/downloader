// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC721Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/// @custom:security-contact dev@originsecured.com
contract OriginCourtOrderERC721 is
  Initializable,
  ERC721Upgradeable,
  ERC721URIStorageUpgradeable,
  ERC721PausableUpgradeable,
  OwnableUpgradeable,
  ERC721BurnableUpgradeable,
  UUPSUpgradeable
{
  uint256 private _nextTokenId;

  // /// @custom:oz-upgrades-unsafe-allow constructor
  // constructor() {
  //   _disableInitializers();
  // }

  function initialize(string memory __name, string memory __symbol) public initializer {
    __ERC721_init(__name, __symbol);
    __ERC721URIStorage_init();
    __ERC721Pausable_init();
    __Ownable_init();
    __ERC721Burnable_init();
    __UUPSUpgradeable_init();

    _nextTokenId = 1;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function safeMint(address to, string memory uri) public onlyOwner whenNotPaused {
    uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  // The following functions are overrides required by Solidity.

  // function _update(
  //   address to,
  //   uint256 tokenId,
  //   address auth
  // ) internal override(ERC721Upgradeable, ERC721PausableUpgradeable) returns (address) {
  //   return super._update(to, tokenId, auth);
  // }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721Upgradeable, ERC721PausableUpgradeable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
    revert("Not transferable");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
    revert("Not transferable");
  }

  function approve(
    address to,
    uint256 tokenId
  ) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
    revert("Not transferable");
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
    revert("Not transferable");
  }

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner whenNotPaused {
    _setTokenURI(tokenId, _tokenURI);
  }

  function _burn(
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
    super._burn(tokenId);
  }

  function burn(uint256 tokenId) public override onlyOwner whenNotPaused {
    _burn(tokenId);
  }
}
