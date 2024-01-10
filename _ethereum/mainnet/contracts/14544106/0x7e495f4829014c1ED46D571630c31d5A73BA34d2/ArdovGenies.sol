// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Counters.sol";



contract ArdovGenies is Ownable, ERC721 {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  uint256 public mintPrice = 0.01 ether;
  uint256 public mintLimit = 25 ;
  

  uint256 public maxSupply = 500;
  Counters.Counter private _tokenIdCounter;

  bool public publicSaleState = false;

  string public baseURI;

  address private deployer;

  constructor() ERC721("ArdovGenies", "AG") { 
    deployer = msg.sender;
  }
  


  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }
  
  function changeStatePublicSale() public onlyOwner returns(bool) {
    publicSaleState = !publicSaleState;
    return publicSaleState;
  }
  

  function mint(uint numberOfTokens) external payable {
    require(publicSaleState, "Sale is not active");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment");

    mintInternal(msg.sender, numberOfTokens);
  }


  function mintInternal(address wallet, uint amount) internal {

    uint currentTokenSupply = _tokenIdCounter.current();
    require(currentTokenSupply.add(amount) <= maxSupply, "Not enough tokens left");

    
    for(uint i = 0; i< amount; i++){
    currentTokenSupply++;
    _safeMint(wallet, currentTokenSupply);
    _tokenIdCounter.increment();
    }
    

}


  function reserve(uint256 numberOfTokens) external onlyOwner {
    mintInternal(msg.sender, numberOfTokens);
  }

  function totalSupply() public view returns (uint){
    return _tokenIdCounter.current();
}
  
  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    payable(deployer).transfer(address(this).balance); 
    }

}