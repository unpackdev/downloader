// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./ICNP.sol";



contract FCNP is Ownable, ERC721{
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  
  ICNP public CNPContract;
  

  uint256 public maxSupply = 3333;
  Counters.Counter private _tokenIdCounter;

  bool public publicSaleState = false;

  string public baseURI;

  address private deployer;

  constructor() ERC721("Flipped Crypto Noun Punks", "FCNP") { 
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
  

  function mintOne(uint tokenID) external {
    require(publicSaleState, "Sale is not active");

    mintInternal(msg.sender, tokenID);
  }

  function mintBulk(uint[] memory tokenIDs) external {
    require(publicSaleState, "Sale is not active");
    
    for(uint i = 0; i < tokenIDs.length; i++){
      mintInternal(msg.sender, tokenIDs[i]);
    }

    
  }


  function mintInternal(address wallet, uint mintID) internal {
    require(!_exists(mintID), "This token ID already exists!");
    address ownerOf = CNPContract.ownerOf(mintID);
    require(msg.sender == ownerOf, "You aren't the owner of this id!");
    uint currentTokenSupply = _tokenIdCounter.current();
    require(currentTokenSupply.add(1) <= maxSupply, "Not enough tokens left");
    

    currentTokenSupply++;
    _safeMint(wallet, mintID);
    _tokenIdCounter.increment();
}


  function totalSupply() public view returns (uint){
    return _tokenIdCounter.current();
  }
  
  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    payable(deployer).transfer(address(this).balance); 
  
  }


  function setCNPContract(address _contract) external onlyOwner{
    require (_contract != address(0), "Can't set Address 0 as contract address!");
    CNPContract = ICNP(_contract);
  }

  function getCNPBalance(address _wallet) external view{
    require(_wallet != address(0), "Can't check the balance of address 0!");
    CNPContract.balanceOf(_wallet);
  }

}