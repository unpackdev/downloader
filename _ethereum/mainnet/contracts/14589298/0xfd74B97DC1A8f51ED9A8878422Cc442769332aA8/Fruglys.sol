// SPDX-License-Identifier: MIT

/**

    &&&&&&&&&&   ////           (((     ###      //   ,    ,,     ####      
  &&&&     &   /// ///   (((   (((( #####,     //(/  ,,, ,,,   ####         
  &&&&        ///  ///   (((   (((( ###        ///    ,,,,,   ####          
  &&&&&&&&    ///////    (((   (((( ### #####  (/(      ,,,    #######      
  &&&&        ///,////   (((   (((  #### *###  ///      ,,,        ####     
  &&&&         //   //// (((  (((    #######  .(/(/*    ,,,,       ####     
  &&&&         //         ((((((                /////    ,,    .######      

                    fruglys be vibin, leapin & trippin. 

                      fruglys be public domain (CC0)
                    
                @fruglys created by @thenftdude and @notuart

                            https://fruglys.com
 */

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Fruglys is ERC721A, Ownable {
  using Strings for uint256;

  bool public paused = true;
  uint256 public price = 0.04 ether;

  uint256 public constant MAX_SUPPLY = 5000;
  uint256 public constant MAX_PER_TX = 20;
  uint256 public constant MAX_PER_WALLET = 20;
  
  string public constant PROVENANCE = "3553b1316dbfa5daf14c47f0db257cc0";
  string public constant BASE_URI = "ipfs://QmTCVoLkQZANUkKhCAWVNNrKTttjBQvT7FD3C6cfCeYjVD/";

  constructor() ERC721A("Fruglys", "FRUGLY") {}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function flipPause() external onlyOwner {
    paused = !paused;
  }
  
  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(BASE_URI, _tokenId.toString(), ".json"));
  }
  
  function mint(uint256 quantity) external payable {
    require (!paused, "Mint not live");
    require ((totalSupply() + quantity) <= MAX_SUPPLY, "Minted out");
    require (quantity > 0, "Invalid quantity");
    require (quantity <= MAX_PER_TX, "Invalid quantity");
    require ((balanceOf(msg.sender) + quantity) <= MAX_PER_WALLET, "Minted max frugs");
    require (msg.value == (price * quantity), "Invalid price");
    
    _safeMint(msg.sender, quantity);
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    
    require (success);
  }
}