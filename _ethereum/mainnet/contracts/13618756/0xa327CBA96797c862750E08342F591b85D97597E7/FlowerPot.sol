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

contract FlowerPot is ERC721Enumerable, Ownable {
  uint public constant MAX_SUPPLY = 5000;
  string _baseTokenURI = "https://pot.magicbutterfly.io/";
  bool public isActive = false;
  address payable public treasury;

  uint256 unitPrice = 250000000000000000; // 0.25 ether

  constructor(address payable _treasury) ERC721("FlowerPot", "POT")  {
    treasury = _treasury;
  }

  function mintPot(address _to) public payable {
    require(isActive, "!active");
    require(totalSupply() < MAX_SUPPLY, "Ended");
    require(msg.value >= unitPrice, "!value");
    treasury.transfer(msg.value);
    _safeMint(_to, totalSupply());
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