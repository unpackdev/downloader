// SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Mich is ERC721URIStorage, Ownable {
   using Counters for Counters.Counter;
   Counters.Counter private _tokenIds;

   constructor() ERC721("Mich", "MICH") {}

   function mintNFT(address recipient, string memory tokenURI)
       public onlyOwner
       returns (uint256)
   {
       _tokenIds.increment();

       uint256 newItemId = _tokenIds.current();
       _mint(recipient, newItemId);
       _setTokenURI(newItemId, tokenURI);

       return newItemId;
   }

    function mintMultipleNFT(address recipient, string[] memory tokenURI)
    public onlyOwner
    {
      for(uint i=0; i < tokenURI.length; i++) {
          mintNFT(recipient, tokenURI[i]);
      }
    }
}