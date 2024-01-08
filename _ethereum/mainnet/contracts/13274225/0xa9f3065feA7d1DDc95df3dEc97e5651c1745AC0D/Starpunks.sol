// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///////////////////////////////////////////////////////////////////////////////////////////
//   __    _  _______  _______  _______  _______  ___      __   __  _______              // 
//  |  |  | ||       ||       ||       ||       ||   |    |  | |  ||  _    |             // 
//  |   |_| ||    ___||_     _||  _____||       ||   |    |  | |  || |_|   |             //
//  |       ||   |___   |   |  | |_____ |       ||   |    |  |_|  ||       |             //
//  |  _    ||    ___|  |   |  |_____  ||      _||   |___ |       ||  _   |              //
//  | | |   ||   |      |   |   _____| ||     |_ |       ||       || |_|   |             //
//  |_|  |__||___|      |___|  |_______||_______||_______||_______||_______|             //
//   _______  _______  _______  ______    _______  __   __  __    _  ___   _  _______    //
//  |       ||       ||   _   ||    _ |  |       ||  | |  ||  |  | ||   | | ||       |   //
//  |  _____||_     _||  |_|  ||   | ||  |    _  ||  | |  ||   |_| ||   |_| ||  _____|   //
//  | |_____   |   |  |       ||   |_||_ |   |_| ||  |_|  ||       ||      _|| |_____    //
//  |_____  |  |   |  |       ||    __  ||    ___||       ||  _    ||     |_ |_____  |   //
//   _____| |  |   |  |   _   ||   |  | ||   |    |       || | |   ||    _  | _____| |   //
//  |_______|  |___|  |__| |__||___|  |_||___|    |_______||_|  |__||___| |_||_______|   //
// 	 																					 //
///////////////////////////////////////////////////////////////////////////////////////////


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

interface StandardToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address reveiver, uint256 amount) external returns (bool);
    function burn(address sender, uint256 amount) external returns (bool);
}

contract Starpunks is ERC721Enumerable, Ownable {
  uint public constant MAX_SUPPLY = 6038;
  string _baseTokenURI = "https://starpunk.nftsclub.io/";
  bool public isActive = true;

  uint256 unitPrice = 60000000000000000; // 0.06 ether
  uint256 maxPerUser = 20;

  constructor() ERC721("Starpunks", "STP")  {
    address _to = 0x713ba7a2B5271aeb8600b5ee4142Bb9758e3921F;
    for(uint i = 0; i < 40; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function mint(address _to, uint _count) public payable {
    require(isActive, "!active");
    require(_count <= maxPerUser, "> maxPerUser");
    require(totalSupply() < MAX_SUPPLY, "Ended");
    require(totalSupply() + _count <= MAX_SUPPLY, ">limit");
    require(msg.value >= price(_count), "!value");

    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }


  function price(uint _count) public view returns (uint256) {
    return _count * unitPrice;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokensIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensIds;
  }

  function setActive(bool _active) public onlyOwner {
    isActive = _active;
  }

  // allows the owner to withdraw BNB and other tokens
  function ownerWithdraw(uint256 amount, address _to, address _tokenAddr) public onlyOwner{
    require(_to != address(0));
    if(_tokenAddr == address(0)){
      payable(_to).transfer(amount);
    }else{
      StandardToken(_tokenAddr).transfer(_to, amount);  
    }
  }
}