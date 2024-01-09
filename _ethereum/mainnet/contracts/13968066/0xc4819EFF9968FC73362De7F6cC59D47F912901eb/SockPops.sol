// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Counters.sol";



contract SockPops is Ownable, ERC721 {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  uint256 public latePrice = 10000000000000000;
  uint256 public earlyPrice = 0;
  uint256 public mintLimit = 20;
  

  uint256 public maxSupply = 5000;
  uint256 public maxFreeMintSupply = 1000;

  Counters.Counter private _tokenIdCounter;


  bool public publicSaleState = false;

  string public baseURI;


  address private deployer;
  address payable private artist = payable(0xAaB32294f0c6D35b1e08cEDc46a7a9fb4b2cbc41);
  address payable private teamLead = payable(0xa91d6B3B06043296A7003327A31AF8eF2a598c02);

  constructor() ERC721("Sock Pops", "SP") { 
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

  function changeFreeMaxMints (uint256 newMax) external onlyOwner{
    maxFreeMintSupply = newMax;
  }

  function airdropToWallet(address walletAddress, uint amount) public onlyOwner{
    mintInternal(walletAddress, amount);
  }

  function mint(uint numberOfTokens) external payable {
    require(publicSaleState, "Sale is not active");
    require(msg.value >= getCurrentMintPrice().mul(numberOfTokens), "Insufficient payment");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction");

    mintInternal(msg.sender, numberOfTokens);
  }

  function getCurrentMintPrice() public view returns(uint256){
    if(totalSupply() < maxFreeMintSupply){
      return earlyPrice;
    }else{
      return latePrice;
    }
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
  
  function withdrawAll() public onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    uint256 balance = address(this).balance;
    artist.transfer(balance*30/100);
    teamLead.transfer(balance*30/100);
    payable(deployer).transfer(address(this).balance); 
  }

}