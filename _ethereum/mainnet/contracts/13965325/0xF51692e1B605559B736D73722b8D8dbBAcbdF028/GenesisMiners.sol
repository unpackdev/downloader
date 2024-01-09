// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract GenesisMiners is ERC721, Pausable, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  string private _metadataBaseURI;

  uint256 private _maxSupply;
  uint256 private _maxMint;
  uint256 private _price = 0.05 ether;

  uint256 private _reserved = 7;

  bool private _presale = true;
  mapping(address => uint8) private _whitelist;

  constructor(uint256 maxSupply, uint256 maxMint, string memory metadataBaseURI) ERC721("Miners Genesis", "MINER") {
    _metadataBaseURI = metadataBaseURI;
    _maxSupply = maxSupply;
    _maxMint = maxMint;
  }

  function mintedCount() external view returns (uint256 supply) {
    return _tokenIdCounter.current();
  }

  function reservedCount() external view returns (uint256 count) {
    return _reserved;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataBaseURI;
  }

  function setBaseURI(string memory uri) external onlyOwner {
    _metadataBaseURI = uri;
  }

  // Pausing

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function getPrice() public view returns (uint256) {
    return _price;
  }

  /** For if ETH price goes wack */
  function setPrice(uint256 newPrice) public onlyOwner {
    _price = newPrice;
  }

  function setReserved(uint256 newReserved) external onlyOwner {
    _reserved = newReserved;
  }
  
  function bulkWhitelist(address[] memory addrs) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) {
      _whitelist[addrs[i]] = 1;
    }
  }

  function startPublicSale() external onlyOwner {
    _presale = false;
  }

  function mintAMiner() external payable {
    require(msg.value >= _price, 'Ether sent not correct');
    if (_presale) {
      require(_whitelist[msg.sender] == 1, 'Not on list or already minted.');
      _whitelist[msg.sender] = 0;
    }
    uint256 tokenId = _tokenIdCounter.current();
    require(tokenId < _maxSupply - _reserved, 'Sold Out');
    require(balanceOf(msg.sender) < _maxMint, 'Exceeded max mint per account');

    _tokenIdCounter.increment();
    _safeMint(msg.sender, tokenId);
  }

  function giveAwayMiner(address to) external onlyOwner {
    require(_reserved > 0, 'Exceeds reserved supply');
    uint256 tokenId = _tokenIdCounter.current();

    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
    _reserved--;
  }

  function withdrawAll() external payable onlyOwner {
    uint256 _amount = address(this).balance;
    
    (bool success1, ) = payable(owner()).call{value: _amount}("");
    require(success1, "Failed to send Ether to owner");
  }
}