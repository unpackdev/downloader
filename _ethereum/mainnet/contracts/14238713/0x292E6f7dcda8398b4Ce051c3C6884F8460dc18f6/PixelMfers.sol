// SPDX-License-Identifier: None

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Counters.sol";

contract PixelMfers is Ownable, ERC721 {
  
  using Counters for Counters.Counter;
  Counters.Counter private idCounter;

  using SafeMath for uint256;
  uint256 public price = 0.0069 ether;
  uint256 public free = 0;
  uint256 public maxSupply = 5555;
  uint256 public maxFreeMintSupply = 1000;
  mapping (address => uint256) freeClaimedByAddress;
  string public baseURI;
  address private deployer;

  constructor() ERC721("Pixel Mfers", "PM") { 
    deployer = msg.sender;
  }
  function currentPriceOfWallet(address wallet, uint256 amount) public view returns(uint256){
    if(totalSupply() < maxFreeMintSupply){
      if(freeClaimedByAddress[wallet] + amount <= 20){
        return free;
      }else{return price;}
    }else{
      return price;
    }
  }
  function mint(uint amount) external payable {
    require(amount <= 20, "Tx limit");
    require(msg.value >= currentPriceOfWallet(msg.sender, amount).mul(amount), "Pay more");
    create(msg.sender, amount);
  }
  function create(address wallet, uint amount) internal {
    uint currentSupply = idCounter.current();
    require(currentSupply.add(amount) <= maxSupply, "Sell out");
    freeClaimedByAddress[wallet]+= amount;
    for(uint i = 0; i< amount; i++){
    currentSupply++;
    _safeMint(wallet, currentSupply);
    idCounter.increment();
    }
  }
  function newFreeCount (uint256 newMax) public onlyOwner{
    maxFreeMintSupply = newMax;
  }
  function totalSupply() public view returns (uint){
    return idCounter.current();
  }
  function withdrawAll() public onlyOwner {
    require(address(this).balance > 0, "No money, honey");
    payable(deployer).transfer(address(this).balance); 
  }
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
  function setUri(string calldata newUri) public onlyOwner {
    baseURI = newUri;
  }

}