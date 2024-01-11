//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract AirHeadz is ERC721, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private supply;

  uint256 public publicCost = .003 ether;
  uint256 public maxMintAmountPlusOne = 6;

  uint256 public maxFreePlusOne = 2501; //11
  uint256 public maxSupplyPlusOne = 5001; //21
  uint256 public devMintAmount = 51;

  string public PROVENANCE;
  string private _baseURIextended;

  bool public saleIsActive;
  address payable public immutable devAddress = payable(0x30B9721de4c8acf3863C32C666359eA623A3E91f);
  address payable public immutable creatorAddress = payable(0x0F25b73e6f85f7F90B1865c536F1BDb9AD07f697);
  address payable public immutable marketingAddress = payable(0x03443e172ea6Bdb4EfC27eA2b3C12d659949635B);

  constructor() ERC721("AirHeadz", "AIRHEADZ") {
    _baseURIextended = "ipfs://Qmco8udX7hx5AvwCBXg2enTTYrrJaksbP4Njj52QLZWaHn/";
    _mintLoop(msg.sender, devMintAmount);
    saleIsActive = false; 
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount < maxMintAmountPlusOne, "Invalid mint amount!");
    require(supply.current() + _mintAmount < maxSupplyPlusOne, "Max supply exceeded!");
    _; 
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require (saleIsActive, "Public sale inactive");

    if (supply.current() + _mintAmount > maxFreePlusOne) {
        require(msg.value >= publicCost * _mintAmount, "Not enough eth sent!");
    }
    _mintLoop(msg.sender, _mintAmount);
  }

  function setSale(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  function setProvenance(string memory provenance) public onlyOwner {
    PROVENANCE = provenance;
  }

  function setPublicCost(uint256 _newCost) public onlyOwner {
    publicCost = _newCost;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function setBaseURI(string memory baseURI_) external onlyOwner() {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      Address.sendValue(devAddress, balance.mul(13).div(100));
      Address.sendValue(marketingAddress, balance.mul(5).div(100));
      Address.sendValue(creatorAddress, balance.mul(82).div(100));
  }
}
