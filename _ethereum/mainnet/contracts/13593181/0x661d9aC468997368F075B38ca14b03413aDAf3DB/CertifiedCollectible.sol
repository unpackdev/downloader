// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title Certified Collectible base contract
 * @author COBA
 */
contract CertifiedCollectible is ERC721Enumerable, Ownable {
  ERC721Enumerable originalCollectible;
  string private _certifiedCollectibleBaseURI;

  constructor (string memory name, string memory symbol, string memory baseURI_, address originalAddress) ERC721(name, symbol) {
    originalCollectible = ERC721Enumerable(originalAddress);
    _setBaseURI(baseURI_);
  }

  /**
   * Internal claim function. Verifies core claim requirements are met and mints token.
   * @param tokenId id to claim
   */
  function _claim(uint256 tokenId) internal {
    _applyCoreClaimRequirements(tokenId);
    _safeMint(msg.sender, tokenId);
  }

  /**
   * Applied on each token claim. These are the essential requirements.
   * @param tokenId id that's requirements are being verified
   */
  function _applyCoreClaimRequirements(uint256 tokenId) private view { 
    require(originalCollectible.ownerOf(tokenId) == msg.sender, "You are not eligible to claim that token");
  }

  /**
   * Lists all the already claimed collectibles token ids for an owner's address
   * @param owner address to be queried
   */
  function listClaimedCollectibles(address owner) external view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory result = new uint256[](tokenCount);
    uint256 index;
    for (index = 0; index < tokenCount; index++) {
      result[index] = tokenOfOwnerByIndex(owner, index);
    }
    return result;
  }

  /**
   * List all collectibles token ids that can be claimed for an owner's address
   * @param owner address to be queried
   */
  function listClaimableCollectibles(address owner) external view returns(uint256[] memory) {
    uint256 numPotentialClaims = originalCollectible.balanceOf(owner);
    uint256 numAlreadyClaimed = balanceOf(owner);
    uint256 numLeftToClaim = numPotentialClaims - numAlreadyClaimed;
    uint256[] memory result = new uint256[](numLeftToClaim);
    uint256 potentialClaimIndex;
    uint256 resultIndex = 0;
    uint256 currentPotentialClaimTokenId;

    for (potentialClaimIndex = 0; potentialClaimIndex < numPotentialClaims; potentialClaimIndex++) {
      currentPotentialClaimTokenId = originalCollectible.tokenOfOwnerByIndex(owner, potentialClaimIndex);
      if (!_exists(currentPotentialClaimTokenId)) {
        result[resultIndex] = currentPotentialClaimTokenId;
        resultIndex++;
      }
    }
    return result;
  }

  /**
   * Return baseURI to be used by the tokenURI method
   */
  function _baseURI() internal view override returns (string memory) {
    return _certifiedCollectibleBaseURI;
  }

  /**
   * Support setting the baseURI
   */
  function _setBaseURI(string memory baseURI_) internal {
    _certifiedCollectibleBaseURI = baseURI_;
  }
}
