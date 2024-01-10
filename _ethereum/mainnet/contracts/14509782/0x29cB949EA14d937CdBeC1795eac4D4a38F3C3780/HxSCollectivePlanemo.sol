// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract HxSCollectivePlanemo is ERC721, Ownable {
  // Collection size
  uint256 public collectionSize = 21;

  // Metadata URI
  string public collectionURI;

  constructor(string memory uri) ERC721('H x S Collective - Planemo', 'HxSCollectivePlanemo') {
    // 1. Setup the collection
    collectionURI = uri;

    // 2. Mint the collection to the creator
    for (uint256 tokenId = 1; tokenId <= collectionSize; ) {
      _mint(owner(), tokenId);

      // 2.1 We don't need to check the value bounds, taken care of above
      unchecked {
        tokenId++;
      }
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return collectionURI;
  }

  function totalSupply() external view returns (uint256) {
    return collectionSize;
  }

  /**
    @notice Changes the collection URI of the contract in case the original URI for some reason is tampered
    @dev Only allows the action to be done by the creator of the contract
    @param uri URI where the metadata for the collection is stored
  */
  function setCollectionURI(string memory uri) external onlyOwner {
    collectionURI = uri;
  }

  /**
    @notice Withdraw all balance from the contract to the owner
   */
  function withdraw() external onlyOwner {
    (bool sent, ) = payable(owner()).call{ value: address(this).balance }('');

    require(sent, 'HxSCollectivePlanemo: Failed to withdraw the balance of the contract');
  }

  /**
    @notice Allow contact to receive payments
   */
  receive() external payable {}
}
