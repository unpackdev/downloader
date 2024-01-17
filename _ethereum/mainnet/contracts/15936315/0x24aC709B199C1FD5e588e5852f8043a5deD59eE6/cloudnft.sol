pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./PullPayment.sol";

contract WhatDoYouSeeNFT is ERC721Tradable, PullPayment {
  using Counters for Counters.Counter;

  uint MINT_PRICE = 0.02 ether;
  bool MINT_OPEN = false;
  string BASE_TOKEN_URI = "ipfs://bafybeicnuxa5sggwjkddjlmgdp7jk6wbsz7h5xtcai6qafltojjpov7xka/";
  uint MAX_SUPPLY = 925;

  constructor(address _proxyRegistryAddress) ERC721Tradable("What Do You See", "WDYS", _proxyRegistryAddress) {
  }

  function isMinted(uint256 tokenId) public view virtual returns (bool) {
    return _exists(tokenId);
  }

  function totalSupply() public view virtual returns (uint256) {
    uint total = 0;
    for(uint i = 0; i < MAX_SUPPLY; i++) {
      if(isMinted(i)) {
        total++;
      }
    }
    return total;
  }

  function mint(address _to, uint256 _tokenId) public payable {
    bool isOwner = owner() == _msgSender();
    require(MINT_OPEN, "Minting is not open");
    require(msg.value == MINT_PRICE || isOwner, "Transaction value did not equal the mint price");
    require(!_exists(_tokenId), "Token is already minted");
    require(_tokenId <= MAX_SUPPLY && _tokenId >= 1, "Token ID invalid");

    if(msg.value > 0) {
      _asyncTransfer(owner(), msg.value);
    }
    _safeMint(_to, _tokenId);
  }

  function baseTokenURI() override public view returns (string memory) {
    return BASE_TOKEN_URI;
  }

  function setBaseTokenURI(string memory _uri) public onlyOwner {
    BASE_TOKEN_URI = _uri;
  }

  function setMintPrice(uint _price) public onlyOwner {
    MINT_PRICE = _price;
  }

  function setMintOpen(bool _open) public onlyOwner {
    MINT_OPEN = _open;
  }

  function withdrawPayments(address payable payee) public override onlyOwner virtual {
    require(payee == owner(), "Only owner can withdraw");
    super.withdrawPayments(payee);
  }
}
