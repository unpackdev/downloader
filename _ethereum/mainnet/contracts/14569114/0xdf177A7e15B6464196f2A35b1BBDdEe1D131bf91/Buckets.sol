//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./console.sol";

contract Buckets is ERC721, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private supply;

  uint256 public publicCost = .025 ether;
  uint256 public maxMintAmountPlusOne = 21;
  uint256 public maxSupplyPlusOne = 901;
  uint256 public freeMintThreshold = 100;

  bool public saleIsActive;

  string public PROVENANCE;
  string private _baseURIextended;

  // N
  address payable public nAddress = payable(0xff2e87BbaA3bfA1134b0Bdc564837fcFA59B1AD4);

  // D
  address payable public mAddress = payable(0x256971009f4D7907c98175C76982C2d9DF70e31C);

  constructor() ERC721("BUCKETS", "BUCKETS") {
    saleIsActive = false;
    _baseURIextended = "ipfs://QmNWyfFhYkEk9hzy99HApGZ5EqtnmKW3n4MCAANwTRTp7Q/";
    _mintLoop(mAddress, 1);
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable {
    require (saleIsActive, "Public sale inactive");

    if (supply.current() + _mintAmount > freeMintThreshold) {
        require(msg.value >= publicCost * _mintAmount, "Not enough eth sent!");
    }

    require(_mintAmount > 0 && _mintAmount < maxMintAmountPlusOne, "Invalid mint amount!");
    require(supply.current() + _mintAmount < maxSupplyPlusOne, "Max supply exceeded!");
    _mintLoop(msg.sender, _mintAmount);
  }

  function setSale(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  function setPublicCost(uint256 _newCost) public onlyOwner {
    publicCost = _newCost;
  }

  function lowerSupply(uint256 newSupply) public onlyOwner {
      if (maxSupplyPlusOne < newSupply) {
          maxSupplyPlusOne = newSupply;
      }
  }

  function changeFreeMintThreshold(uint256 newThreshold) public onlyOwner {
    freeMintThreshold = newThreshold;
  }

  function setProvenance(string memory provenance) public onlyOwner {
    PROVENANCE = provenance;
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
    Address.sendValue(nAddress, balance.mul(50).div(100));
    Address.sendValue(mAddress, balance.mul(50).div(100));
  }

}