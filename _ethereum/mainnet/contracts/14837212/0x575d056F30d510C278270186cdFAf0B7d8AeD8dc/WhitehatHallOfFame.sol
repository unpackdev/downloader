// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Burnable.sol";
import "./IERC165.sol";
import "./ERC1967UUPSENSUpgradeable.sol";

contract WhitehatHallOfFame is ERC1967UUPSENSUpgradeable, ERC721, IERC721Metadata, IERC721Burnable {
  constructor(string[] memory ensName) ERC1967UUPSENSUpgradeable(ensName) {
    _requireOwner();
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) onlyProxy returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Burnable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  string public constant override name = "WhitehatHallOfFame";
  string public constant override symbol = "WHoF";
  mapping(uint256 => string) public override tokenURI;

  uint256 internal _nonce;

  function _nextNonce() internal returns (uint256) {
    unchecked {
      return ++_nonce;
    }
  }

  function mint(address recipient, string calldata uri) external onlyOwner {
    uint256 tokenId = _nextNonce();
    tokenURI[tokenId] = uri;
    _mint(recipient, tokenId);
  }

  function safeMint(
    address recipient,
    string calldata uri,
    bytes calldata transferData
  ) external onlyOwner {
    uint256 tokenId = _nextNonce();
    tokenURI[tokenId] = uri;
    _safeMint(recipient, tokenId, transferData);
  }

  function burn(uint256 tokenId) external override onlyApproved(tokenId) {
    _burn(tokenId);
    delete tokenURI[tokenId];
  }
}
