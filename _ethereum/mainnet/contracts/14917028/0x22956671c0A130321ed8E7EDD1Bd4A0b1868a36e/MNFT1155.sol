// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

contract MNFT1155 is ERC1155, ERC1155Supply, Ownable, ReentrancyGuard {
   using Strings for uint256;
   string public name;
   string public symbol;
   uint256 private currentIndex = 0;
   address private marketplaceAddress;
   mapping(uint256 => string) private tokenURIs;

   event minted(
      address to,
      string uri,
      uint256 tokenID,
      uint256 amount
   );

   constructor(
      string memory name_,
      string memory symbol_
   ) ERC1155("") {
      name = name_;
      symbol = symbol_;
   }

   function setMarketplaceAddress(address marketplace_) external onlyOwner {
      marketplaceAddress = marketplace_;
   }

   function uri(uint256 _id) public view override returns (string memory) {
      require(exists(_id), "ERC1155Metadata: URI query for nonexistent token");

      return tokenURIs[_id];
   }

   function mintNFT(
      address owner_,
      string calldata tokenURI_, 
      uint256 amount_
   ) external nonReentrant {
      require (msg.sender == marketplaceAddress || msg.sender == owner(), 'no permission');
      require (amount_ > 0, 'should mint at lease one');

      _mint(owner_, currentIndex, amount_, bytes(""));
      tokenURIs[currentIndex ++] = tokenURI_;

      uint256[] memory tokenIDs = new uint256[](1);
      tokenIDs[0] = currentIndex - 1;

      emit minted(
         owner_,
         tokenURI_,
         currentIndex - 1,
         amount_
      );
   }

   function _beforeTokenTransfer(
      address operator,
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
   ) internal override(ERC1155, ERC1155Supply) {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
   }
}