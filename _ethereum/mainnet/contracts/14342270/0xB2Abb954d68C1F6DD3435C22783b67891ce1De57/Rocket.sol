// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./Math.sol";
import "./SafeCast.sol";
import "./ERC721A.sol";

contract Rocket is ERC721A, Ownable {
  uint256 public maxSupply;
  uint256 public mintPrice;

  string public baseURI;

  uint256 public publicLimit; // Set to >0 to start public sale

  constructor(uint256 supply, uint256 price) ERC721A("Rocket", "ROCKET") {
    maxSupply = supply;
    mintPrice = price;
  }

  function setMaxSupply(uint256 newSupply) external onlyOwner {
    maxSupply = Math.max(totalSupply(), Math.min(maxSupply, newSupply));
  }

  function setMintPrice(uint256 newPrice) external onlyOwner {
    mintPrice = newPrice;
  }

  function setPublicLimit(uint256 newLimit) external onlyOwner {
    publicLimit = newLimit;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setPrivateLimit(address[] calldata addresses, uint256[] calldata num) external onlyOwner {
    require(addresses.length == num.length, "length mismatch");
    for (uint256 i = 0; i < addresses.length; i++) {
      _setAux(addresses[i], SafeCast.toUint64(num[i]));
    }
  }

  function privateLimit(address owner) public view returns (uint64) {
    return _getAux(owner);
  }

  function numberMinted(address owner) external view returns (uint256) {
    return _numberMinted(owner);
  }

  function ownershipStart(uint256 tokenId) external view returns (uint64) {
    return ownershipOf(tokenId).startTimestamp;
  }

  function mint(uint256 num) external payable {
    require(tx.origin == msg.sender, "cannot call from contract");
    require(totalSupply() + num <= maxSupply, "max supply reached");
    require(msg.value == mintPrice * num, "wrong payment amount");

    uint256 minted = _numberMinted(msg.sender);
    uint256 limit = Math.max(publicLimit, privateLimit(msg.sender));
    uint256 remaining = limit > minted ? limit - minted : 0;
    require(num <= remaining, "mint limit exceeded");

    _safeMint(msg.sender, num);
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }
}
