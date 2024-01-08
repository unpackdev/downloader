// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

interface TheDudesFactoryCollection {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract TheDudesFactoryV2 is ERC721Enumerable, Ownable {

  struct Collection {
    uint256 id;
    string name;
    address owner;
    uint256 tokenBeginIndex;
    uint256 tokenEndIndex;
    uint256 maxItems;
    uint256 itemCount;
    bool isLocked;
    bool isDeleted;
  }

  uint256 public collectionCount;
  uint256 internal reservedSupply;
  mapping(uint256 => Collection) public collections;

  constructor () ERC721("the dudes factory", "DUDF") {}

  function addCollection(string calldata name, uint256 maxItems) public onlyOwner {
    require(maxItems > 0);
    collections[collectionCount].id = collectionCount;
    collections[collectionCount].name = name;
    collections[collectionCount].tokenBeginIndex = reservedSupply;
    collections[collectionCount].tokenEndIndex = reservedSupply + (maxItems - 1);
    collections[collectionCount].maxItems = maxItems;
    collectionCount++;
    reservedSupply += maxItems;
  }

  function deleteCollection(uint256 id) public onlyOwner {
    require(!collections[id].isLocked, "Collection is locked." );
    collections[id].isDeleted = true;
  }

  function updateCollectionName(uint256 id, string calldata name) public onlyOwner {
    require(!collections[id].isLocked, "Collection is locked." );
    collections[id].name = name;
  }

  function updateCollectionOwner(uint256 id, address owner) public onlyOwner {
    require(!collections[id].isLocked, "Collection is locked." );
    require(owner != address(0));
    collections[id].owner = owner;
  }

  function lockCollection(uint256 id) public onlyOwner {
    require(!collections[id].isLocked, "Collection is already locked.");
    collections[id].isLocked = true;
  }

  function mint(uint256 collectionId, address account, uint256 tokenId) public {
    require(!collections[collectionId].isLocked, "Collection is locked." );
    require(msg.sender == collections[collectionId].owner, "Collection owner is invalid.");
    require(collections[collectionId].itemCount < collections[collectionId].maxItems, "Collection already reached to max items count.");

    uint256 mappedTokenId = mappedTokenIdFromCollection(collectionId, tokenId);

    collections[collectionId].itemCount++;
    _safeMint(account, mappedTokenId);
  }

  // Burns the token but doesn't touch the reserved tokenIds of Collection.
  function burn(uint256 collectionId, uint256 tokenId) public {
    require(!collections[collectionId].isLocked, "Collection is locked." );
    require(collections[collectionId].isDeleted, "Collection is not deleted." );
    require(collectionOwnerOrFactoryOwner(collectionId), "Collection owner is invalid.");

    uint256 mappedTokenId = mappedTokenIdFromCollection(collectionId, tokenId);
    _burn(mappedTokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    (bool found, uint256 collectionId, uint256 mappedTokenId) = mappedTokenIdForCollection(tokenId);
    require(found, "Token Id not found in any collection");

    address collectionOwner = collections[collectionId].owner;
    return TheDudesFactoryCollection(collectionOwner).tokenURI(mappedTokenId);
  }

  function mappedTokenIdForCollection(uint256 tokenId) public view returns (bool, uint256, uint256) {
    for (uint256 i=0; i<collectionCount; i++) {
      uint256 beginIndex = collections[i].tokenBeginIndex;
      uint256 endIndex = collections[i].tokenEndIndex;
      if (tokenId >= beginIndex && tokenId <= endIndex) {
        uint256 mappedTokenId = tokenId - beginIndex;
        return (true, i, mappedTokenId);
      }
    }
    return (false, 0, 0);
  }

  function mappedTokenIdFromCollection(uint256 collectionId, uint256 tokenId) public view returns (uint256) {
    return collections[collectionId].tokenBeginIndex + tokenId;
  }

  function tokensOfOwner(address owner_) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(owner_);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(owner_, index);
      }
      return result;
    }
  }

  function tokensOfOwnerInCollection(uint256 collectionId_, address owner_) public view returns (uint256[] memory) {
    uint256[] memory tokensOfOwner_ = tokensOfOwner(owner_);
    uint256[] memory result;
    uint256 index;
    uint256 resultIndex;
    for (index = 0; index < tokensOfOwner_.length; index++) {
      uint256 tokenId = tokensOfOwner_[index];
      (bool found, uint256 collectionId, ) = mappedTokenIdForCollection(tokenId);
      if (found && collectionId == collectionId_) {
        result[resultIndex] = tokenId;
        resultIndex++;
      }
    }
    return result;
  }

  function collectionOwnerOrFactoryOwner(uint256 collectionId) internal view returns (bool) {
    if (msg.sender == owner() || msg.sender == collections[collectionId].owner) {
      return true;
    }
    return false;
  }
}
