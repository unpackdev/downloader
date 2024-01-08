// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


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

contract Caterpillar is ERC721Enumerable, Ownable {
  uint public constant MAX_SUPPLY = 25000;
  uint256 maxPerUser = 10;
  string _baseTokenURI = "https://caterpillar.magicbutterfly.io/";
  bool public isActive = false;
  address payable public treasury;

  uint256 unitPrice = 25000000000000000; // 0.025 ether

  constructor(address payable _treasury) ERC721("Caterpillar", "CPR")  {
    treasury = _treasury;
  }

  function mintCaterpillar(address _to, uint _count) public payable {
    require(isActive, "!active");
    require(_count <= maxPerUser, "> maxPerUser");
    require(totalSupply() < MAX_SUPPLY, "Ended");
    require(totalSupply() + _count <= MAX_SUPPLY, ">limit");
    require(msg.value >= price(_count), "!value");
    treasury.transfer(msg.value);
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

  function setTreasury(address payable newTreasury) public onlyOwner {
    treasury = newTreasury;
  }

  function ownerWithdraw(uint256 amount, address _to, address _tokenAddr) public onlyOwner{
    require(_to != address(0));
    if(_tokenAddr == address(0)){
      payable(_to).transfer(amount);
    }else{
      StandardToken(_tokenAddr).transfer(_to, amount);
    }
  }
}