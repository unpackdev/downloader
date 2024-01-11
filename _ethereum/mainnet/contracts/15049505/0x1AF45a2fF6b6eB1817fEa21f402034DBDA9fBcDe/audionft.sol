// SPDX-License-Identifier: MIT
// Author: NFTit - Ritwik Chakravarty - github.com/spikeyrock

import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Context.sol";
import "./Base64.sol";
import "./ERC721Enumerable.sol";
pragma solidity >=0.8.0 <0.9.0;

contract audionft is ERC721Enumerable, Ownable {
  using Strings for uint256;
 
  uint256 minted = 0;

   struct NFT { 
      string name;
      string description;
      string audio;
      string animation_url;
      string image;
      string rarity;
   }
  
  mapping (uint256 => NFT) public nfts;
  
  constructor() ERC721("Fully On Chain", "FOC") {}

  // public
  function mint(string memory name, string memory description, string memory mididata, string memory rarity) public payable {
    uint256 supply = totalSupply();
    require(supply + 1 <= 50);
    
    
    NFT memory newNFT = NFT(
        string(abi.encodePacked(name)), 
        string(abi.encodePacked(description)),
        string(abi.encodePacked('data:audio/midi;base64,', mididata)),
        string(abi.encodePacked('ipfs://QmWicFuoZ4qwSRPymMxZpRTQKjy5D6JAHruvzL3PUpU5w6/', uint256(supply + 1).toString(), '.mp4')),
        string(abi.encodePacked('ipfs://QmUbxaYhEcqyRY5auhX1pGyen1un9mXzEVGsEkwZ4ivhxi/', uint256(supply + 1).toString(),'.png')),
        string(abi.encodePacked(rarity))

        );
    
    if (msg.sender != owner()) {
      require(msg.value >= 0.5 ether);
    }
    
    nfts[supply + 1] = newNFT;
    _safeMint(msg.sender, supply + 1);
    minted = minted +1;
  }
  
  function buildMetadata(uint256 _tokenId) public view returns(string memory) {
      NFT memory currentWord = nfts[_tokenId];
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          currentWord.name,
                          '", "description":"', 
                          currentWord.description,
                          '", "audio": "', 
                          currentWord.audio,
                          '", "animation_url":"', 
                          currentWord.animation_url,
                          '", "image": "', 
                          currentWord.image,
                          '", "attributes": [{"trait_type": "rarity", "value" : "', 
                          currentWord.rarity,
                          '"}]}'
                          )))));
                          }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      return buildMetadata(_tokenId);
  }

 function transferOwnership(address newOwner) public virtual override onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}