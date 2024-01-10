// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract Invisible3Landers is ERC721A, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;
  uint256 public price = 0.0333 ether;
  uint256 public batch = 20;
  uint256 public supply;
  uint256 public free;
  string public baseUrl;
  mapping(address => bool) public freeMinted;
  bool public revealed = false;
  address w1 = 0x1Ecc5ab7C84D7F8A45559A5DfEEEB5431537f04A;
  address w2 = 0xe2559F51fA76294D3dC838B92555e919f041737d;
  address w3 = 0xaD20ad98DE5D5A88A1070c0164039cA579FB9d43;

  enum MintStatus {
    OFF, FREE, PAID
  }

  MintStatus public mintStatus;

  constructor(uint256 _supply, uint256 _free) ERC721A("Invisible 3Landers", "IV3L", batch, _supply) {
    supply = _supply;
    free = _free;
  }

  function freeMint() external {
    require(mintStatus == MintStatus.FREE, "Free mint off");
    require(!freeMinted[msg.sender], "Wallet already free minted");
    require(totalSupply() + 1 <= free, "Exceeds free supply");
    _safeMint(msg.sender, 1);
    freeMinted[msg.sender] = true;
  }

  function mint(uint256 quantity) external payable {
    require(mintStatus == MintStatus.PAID, "Mint off");
    require(totalSupply() + quantity <= supply, "Exceeds supply");
    require(quantity <= batch, "Exceeds batch");
    require(msg.value >= price * quantity, "Insufficient eth");
    _safeMint(msg.sender, quantity);
  }

  function reserve(address to, uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= supply, "Exceeds supply");
    require(quantity <= batch, "Reserving too much");
    _safeMint(to, quantity);
  }

  function withdrawTeam() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to withdraw");
    require(payable(w1).send(balance.mul(33).div(100)));
    require(payable(w2).send(balance.mul(34).div(100)));
    require(payable(w3).send(balance.mul(33).div(100)));
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to withdraw");
    require(payable(w3).send(balance));
  }

  function deposit() external payable {}

  function _baseURI() internal view virtual override returns (string memory) {
    return baseUrl;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    if (bytes(baseURI).length <= 0) return "";
    return revealed ? string(abi.encodePacked(baseURI, tokenId.toString())) : string(abi.encodePacked(baseURI));
  }

  function setBaseUrl(string memory _baseUrl) external onlyOwner {
    baseUrl = _baseUrl;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setReveal(bool _revealed) external onlyOwner {
    revealed = _revealed;
  }

  function setMintStatus(uint256 status) external onlyOwner {
    require(status <= uint256(MintStatus.PAID), "Invalid mint status");
    mintStatus = MintStatus(status);
  }
}