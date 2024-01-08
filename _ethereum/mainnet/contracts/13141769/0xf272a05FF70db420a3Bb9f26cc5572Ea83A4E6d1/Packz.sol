// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

import "./ITraitz.sol";

// ███    ███ ███████ ████████  █████  ███████ ██   ██ ██ █████████ ███████
// ████  ████ ██         ██    ██   ██ ██      ██  ██  ██ ██     ██    ███
// ██ ████ ██ █████      ██    ███████ ███████ █████   ██ ██     ██   ███
// ██  ██  ██ ██         ██    ██   ██      ██ ██  ██  ██ ██     ██  ███
// ██      ██ ███████    ██    ██   ██ ███████ ██   ██ ██ ██     ██ ███████
// 🥯 bagelface
// 🐦 @bagelface_
// 🎮 bagelface#2027
// 📬 bagelface@protonmail.com

contract Packz is ERC721, ERC721Enumerable, Ownable, PaymentSplitter {
  using Address for address;

  uint256 public EDITION = 0;
  uint256 public MAX_MINT = 10;
  uint256 public MAX_SUPPLY = 10_000;
  uint256 public MAX_RESERVED = 111;
  uint256 public MINT_PRICE = 0.0555 ether;
  uint256 public TRAITZ_PER_PACK = 12;

  ITraitz private _traitz;
  address[] private _payees;
  uint256 private _tokenIds;
  uint256 private _reserved;
  string private _packzURI;
  string private _contractURI;
  bool private _saleActive;

  constructor(
    string memory packzURI,
    address traitzAddress,
    address[] memory payees,
    uint256[] memory shares
  )
    PaymentSplitter(payees, shares)
    ERC721("metaSKINZ Packz", "PACKZ")
  {
    _traitz = ITraitz(traitzAddress);
    _packzURI = packzURI;
    _payees = payees;
  }

  function tokenIds() public view returns (uint256) {
    return _tokenIds;
  }

  function saleActive() public view returns (bool) {
    return _saleActive;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return _packzURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function flipSaleActive() public onlyOwner {
    _saleActive = !_saleActive;
  }

  function setPackzURI(string memory URI) public onlyOwner {
    _packzURI = URI;
  }

  function setPackzContractURI(string memory URI) public onlyOwner {
    _contractURI = URI;
  }

  function setTraitzMetadataURI(string memory URI) public onlyOwner {
    _traitz.setMetadataURI(URI);
  }

  function setTraitzContractURI(string memory URI) public onlyOwner {
    _traitz.setContractURI(URI);
  }

  function setTraitzBaseURI(string memory URI) public onlyOwner {
    _traitz.setBaseTokenURI(URI);
  }

  function setTraitzPrivateSeed(bytes32 privateSeed) public onlyOwner {
    _traitz.setPrivateSeed(privateSeed);
  }

  function reserve(uint256 amount, address to) public onlyOwner {
    require(_reserved < MAX_RESERVED, "Exceeds maximum number of reserved tokens");

    _mintAmount(amount, to);
    _reserved += 1;
  }

  function mint(uint256 amount) public payable {
    require(amount <= MAX_MINT,               "Exceeds the maximum amount to mint at once");
    require(msg.value >= MINT_PRICE * amount, "Invalid Ether amount sent");
    require(_saleActive,                      "Sale is not active");

    _mintAmount(amount, msg.sender);
  }

  function _mintAmount(uint256 amount, address to) private {
    require(_tokenIds + amount < MAX_SUPPLY, "Exceeds maximum number of tokens");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIds);
      _tokenIds += 1;
    }
  }

  function open(uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, "Caller is not the owner of this token");

    _traitz.mint(TRAITZ_PER_PACK, msg.sender);
    _burn(tokenId);
  }

  function openMultiple(uint256[] calldata tokenIds) public {
    require(tokenIds.length <= MAX_MINT, "Exceeds the maximum amount to open at once");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(ownerOf(tokenIds[i]) == msg.sender, "Caller is not the owner of this token");
    }

    _traitz.mint(TRAITZ_PER_PACK * tokenIds.length, msg.sender);

    for (uint256 i = 0; i < tokenIds.length; i++) {
      _burn(tokenIds[i]);
    }
  }

  function withdrawAll() public onlyOwner {
    for (uint256 i = 0; i < _payees.length; i++) {
      release(payable(_payees[i]));
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}