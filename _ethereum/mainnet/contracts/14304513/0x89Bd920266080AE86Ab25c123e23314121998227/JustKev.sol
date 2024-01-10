//SPDX-License-Identifier: UNLICENSED

/*

     ___  __   __  _______  _______    ___   _  _______  __   __ 
    |   ||  | |  ||       ||       |  |   | | ||       ||  | |  |
    |   ||  | |  ||  _____||_     _|  |   |_| ||    ___||  |_|  |
    |   ||  |_|  || |_____   |   |    |      _||   |___ |       |
 ___|   ||       ||_____  |  |   |    |     |_ |    ___||       |
|       ||       | _____| |  |   |    |    _  ||   |___  |     | 
|_______||_______||_______|  |___|    |___| |_||_______|  |___|  

*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./console.sol";

contract JustKev is ERC721, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private supply;

  uint256 public publicCost = .0269 ether;
  uint256 public maxMintAmountPlusOne = 11;

  uint256 public maxSupplyPlusOne = 6970;
  uint256 public devMintAmount = 69;

  uint256 public amountToDev = 0 ether;
  uint256 public devCap = 56 ether;

  string public PROVENANCE;
  string private _baseURIextended;

  bool public saleIsActive;

    // TODO: update
  address payable public immutable creatorAddress = payable(0xAF49e7A4A2AD880F1aAd9739F7Ba12B616054D73);
  address payable public immutable devAddress = payable(0x34C7D86ee0ae4C46759B1fa0A2Fb651Ef51f5b0F);

  constructor() ERC721("Just Kev", "JUSTKEV") {
    _baseURIextended = "ipfs://QmTZteeY6ckjSGp8uWioZ4QEnz7iqc7U7F1uha46PNjfuJ/";
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
    require(msg.value >= publicCost * _mintAmount, "Not enough eth sent!");
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

  function lowerSupply(uint256 newSupply) public onlyOwner {
      if (maxSupplyPlusOne < newSupply) {
          maxSupplyPlusOne = newSupply;
      }
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
      if (amountToDev < devCap) {
        Address.sendValue(creatorAddress, balance.mul(30).div(100));
        Address.sendValue(devAddress, balance.mul(70).div(100));
        amountToDev += balance.mul(70).div(100);
      } else {
        Address.sendValue(creatorAddress, balance);
      }
  }

}
