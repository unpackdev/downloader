// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IDEX {
   function calculatePrice(uint256 _price, uint256 base, uint256 currencyType, uint256 tokenId, address seller, address nft_a) external view returns(uint256);
   function mintWithCollection(address collection, address to, string memory tokesnURI, uint256 royalty ) external returns(uint256);
   function createCollection(string calldata name_, string calldata symbol_) external;
   function transferCollectionOwnership(address collection, address newOwner) external;
}