//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./NPass.sol";

/**
 * @title NPrimitivesMinerals
 * @author NPrimitives (twitter.com/nprimitives) <n.primitives@gmail.com>
 */
contract NPrimitivesMinerals is NPass {
  using Strings for uint256;

  string public baseURI;

  constructor(
    string memory name,
    string memory symbol,
    bool onlyNHolders,
    uint256 maxTotalSupply,
    uint16 reservedAllowance,
    uint256 priceForNHoldersInWei,
    uint256 priceForOpenMintInWei,
    string memory linkedBaseURI
   ) 
   NPass(name, symbol, onlyNHolders, maxTotalSupply, reservedAllowance, priceForNHoldersInWei, priceForOpenMintInWei) {
     baseURI = linkedBaseURI;
   }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      string memory __baseURI = _baseURI();
      return bytes(__baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }

  function _baseURI() override internal view virtual returns (string memory) {
      return baseURI;
  }

  function mint(uint256 tokenId) override public payable virtual nonReentrant {
        require(tokenId > 0 && tokenId <= maxTotalSupply, "NPass:INVALID_ID");
        require(msg.value == priceForOpenMintInWei, "NPass:INVALID_PRICE");
        _safeMint(msg.sender, tokenId);
    }
  
}