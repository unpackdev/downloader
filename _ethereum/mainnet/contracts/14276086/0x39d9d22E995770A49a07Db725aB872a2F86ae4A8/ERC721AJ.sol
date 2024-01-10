// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AOwnersExplicit.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply. (maxBalance)
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256). (maxSupply)
 */
contract ERC721AJ is Ownable, ReentrancyGuard, ERC721A, ERC721ABurnable, ERC721AOwnersExplicit {
  constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

  string private _baseURIExtended = '';

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function setBaseURI(string memory uri) public virtual onlyOwner {
    _baseURIExtended = uri;
  }

  function getTokenIdsByOwner(address owner) public view returns (uint256[] memory) {
    uint256 count = balanceOf(owner);
    uint256[] memory tokensIds = new uint256[](count);

    for (uint256 i; i < count; i++) {
      tokensIds[i] = tokenOfOwnerByIndex(owner, i);
    }

    return tokensIds;
  }

  function getMintedCountByOwner(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipDataByTokenId(uint256 tokenId) public view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }
}
