// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721AJ.sol";
import "./ERC721AJSaleable.sol";

contract ALMNFT is Ownable, ERC721AJ, ERC721AJSaleable {
  using Strings for uint256;

  bool public hasBeenOpened = false;

  constructor() ERC721AJ('A Lot of Money', 'ALM') {
    SaleConfig memory config = SaleConfig(496);
    setBaseURI('ipfs://QmeUU8jT6rihRSRAywnPQa1ZDJ6eDKZREQ8AdR5AuRKhRs/');
    setSaleConfig(config);
  }

  function unbox(string memory uri) public onlyOwner {
    require(!hasBeenOpened, 'ALM: has been opened');
    hasBeenOpened = true;
    setBaseURI(uri);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) {
      revert URIQueryForNonexistentToken();
    }

    string memory baseURI = _baseURI();

    if (hasBeenOpened) {
      return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }

    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, 'box.json')) : '';
  }
}
