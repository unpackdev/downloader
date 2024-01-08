// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract PudgenzaPenguins is ERC721Enumerable, Ownable {
  using SafeMath for uint256;

  string _baseTokenURI;
  uint256 private _maxMint = 5;
  uint256 private _price = 6 * 10**16; //0.06 ETH;
  bool public _saleActive = false;
  uint public constant RESERVED = 10;
  uint public _MaxEntries = 1111;
  uint256 private _devShare = 30;

  address public constant creatorAddress = 0xe8c91CA22662Ab1356Ada98937Fd15fd41f26D8e;
  address public constant devAddress = 0x6469FA368936c92c36E3018846EBb1B4E8A7839C;

  constructor(string memory baseURI) ERC721("Pudgenza Penguins", "PudgenzaPenguins") {
    setBaseURI(baseURI);
  }

  function mint(address _to, uint256 num) public payable {
    uint256 supply = totalSupply();

    if(msg.sender != owner()) {
      require(_saleActive, "Sale not Active");
      require( num < (_maxMint+1),"You can mint a maximum of 5 Penguins in one transaction" );
      require( msg.value >= _price * num, "Ether sent is not correct" );
      require( supply + num < (_MaxEntries-RESERVED+1), "Exceeds maximum supply" );
    } else {
      require( supply + num < (_MaxEntries+1), "Exceeds maximum supply" );
    }

    for(uint256 i; i < num; i++){
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner) public view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);

      uint256[] memory tokensId = new uint256[](tokenCount);
      for(uint256 i; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
  }

  function getPrice() public view returns (uint256){
      if(msg.sender == owner()) {
          return 0;
      }
      return _price;
  }

  function setPrice(uint256 _newPrice) public onlyOwner() {
      _price = _newPrice;
  }

  function getMaxMint() public view returns (uint256){
      return _maxMint;
  }

  function setMaxMint(uint256 _newMaxMint) public onlyOwner() {
      _maxMint = _newMaxMint;
  }

  function get_MaxEntries() public view returns (uint256){
      return _MaxEntries;
  }

  function set_MaxEntries(uint256 _new_MaxEntries) public onlyOwner() {
      _MaxEntries = _new_MaxEntries;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
  }

  function setsaleBool(bool val) public onlyOwner {
      _saleActive = val;
  }

  function withdrawAll() public payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    require(payable(devAddress).send(balance.mul(_devShare).div(100)), "Transfer to dev failed");
    require(payable(creatorAddress).send(address(this).balance), "Transfer to creator failed");
  }
}