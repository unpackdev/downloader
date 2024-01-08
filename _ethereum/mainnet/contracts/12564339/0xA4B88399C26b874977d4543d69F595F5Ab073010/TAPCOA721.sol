pragma solidity ^0.8.0;

import "./CoreERC721.sol";

// @bvalosek ERC-721 Token
contract TAPCOA721 is CoreERC721 {
  constructor(string memory name, string memory symbol, uint16 feeBps) CoreERC721(CollectionOptions({
    name: name,
    symbol: symbol,
    feeBps: feeBps,
    collectionMetadataCID: 'todo'
  })) { }
}
