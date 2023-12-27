// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";
import "./ERC721.sol";

contract HighGiraffeAcademy is Ownable, ERC721, PaymentSplitter {
  using SafeMath for uint256;

  uint256 public constant mintPrice = 0.03 ether;
  uint256 public constant mintLimit = 20;

  uint256 public totalSupply;

  uint256 public supplyLimit = 10000;
  uint256 public saleStartTime = 1638388800; // Dec 1 2021 20:00:00 GMT+0000

  string public baseURI;

  address[] private payeeAddresses = [
    0xD0B598aAE8b5aB07a94D8F5F2FBaB33A6Be6C7C6,
    0xd1423F1a6C80fcE7c865783A09328e79cA9C4C8b,
    0x872CF3AA10AF64Ed0e32A602Cc219851A721281b,
    0xf46DB6A846d94e091393938A9D61833481e97Ddb,
    0x43792F058C66Db6a44c5b44DDC1337ABc53f402D,
    0x4fD7841a7B69843453a0f76d4CF53040Ee386A20,
    0xEBfe1ab93D1122E065adCaFD8C3174261e8E726F,
    0xDDbaaF86604Ab0e9470660C463F060A0ddeC6858
  ];

  uint256[] private payeeShares = [
    22,
    20,
    21,
    10,
    4,
    4,
    4,
    15
  ];

  constructor() 
  ERC721("High Giraffe Academy", "HGA") 
  PaymentSplitter(payeeAddresses, payeeShares)
  { }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function saleActive() public view returns(bool) {
    return block.timestamp > saleStartTime;
  }

  function setSaleStartTime(uint256 newTime) external onlyOwner {
    saleStartTime = newTime;
  }

  function mint(uint numberOfTokens) external payable {
    require(saleActive(), "Sale is not active.");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction.");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment.");

    _mint(numberOfTokens);
  }

  function _mint(uint numberOfTokens) private {
    require(totalSupply.add(numberOfTokens) <= supplyLimit, "Not enough tokens left.");

    uint256 newId = totalSupply;

    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(msg.sender, newId);
    }

    totalSupply += numberOfTokens;
  }

  function reserve(uint256 numberOfTokens) external onlyOwner {
    _mint(numberOfTokens);
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw.");

    for (uint256 i = 0; i < payeeAddresses.length; i++) {
      release(payable(payee(i)));
    }
  }
}