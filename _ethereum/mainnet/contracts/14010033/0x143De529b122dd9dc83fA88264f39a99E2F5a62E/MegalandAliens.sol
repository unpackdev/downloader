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

contract MegalandAliens is ERC721Enumerable, Ownable {
  uint public constant MAX_SUPPLY = 10101;
  string _baseTokenURI = "https://api.megalandaliens.com/";

  uint256 unitPricePrivateSale = 0.07 ether;
  uint256 unitPricePublicSale = 0.1 ether;

  uint256 maxPerUserPrivateSale = 3;
  uint256 maxPerUserPublicSale = 20;

  bool publicSaleStarted = false;
  bool privateSaleStarted = false;

  constructor() ERC721("Megaland Aliens", "MAL")  {
  }

  function mint(address _to, uint _count) public payable {
    require(publicSaleStarted, "!started");
    require(_count <= maxPerUserPublicSale, "> maxPerUser");
    require(totalSupply() + _count <= MAX_SUPPLY, "Ended");
    require(msg.value >= price(_count), "!value");

    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function mintPrivate(address _to, uint _count) public payable {
    require(privateSaleStarted, "!started");
    require(_count <= maxPerUserPrivateSale, "> maxPerUser");
    require(totalSupply() + _count <= 3000, "Ended");
    require(msg.value >= price(_count), "!value");

    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function premint(address _to, uint256 _count) public onlyOwner{
    require(_count + totalSupply() <= 121, ">121");
    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function price(uint _count) public view returns (uint256) {
    return _count * (publicSaleStarted ? unitPricePublicSale : unitPricePrivateSale);
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

  function updateSettings(bool _privateSaleStarted, bool _publicSaleStarted) public onlyOwner {
    publicSaleStarted = _publicSaleStarted;
    privateSaleStarted = _privateSaleStarted;
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