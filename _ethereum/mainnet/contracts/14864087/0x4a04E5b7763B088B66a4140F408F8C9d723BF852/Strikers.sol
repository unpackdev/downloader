// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./draft-EIP712.sol";

contract Strikers is ERC721, EIP712, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  string _baseUri;
  string _contractUri;

  uint public price;
  bool public isSalesActive;
  uint[] public bundlePrices;
  uint[] public bundleSizes;
  uint public maxSupply;
  uint public maxFreeMints;
  uint public maxFreeMintsPerTx;
  uint public maxFreeMintsPerWallet;

  mapping (address => uint) public accountToMintedFreeTokens;

  constructor() ERC721("Strikers", "STRIKERS") EIP712("STRIKERS", "1.0.0") {
    _contractUri = "ipfs://QmaqHpbqJcuuadoGe4HnycoWoP7QHpGRMZnv65Y4fUWar8";
    maxSupply = 10000;
    maxFreeMints = 2000;
    maxFreeMintsPerTx = 11;
    maxFreeMintsPerWallet = 11;
    price = 0.005 ether;
    isSalesActive = true;
    bundleSizes = [3, 7, 11];
    bundlePrices = [
      0.01 ether,
      0.02 ether,
      0.03 ether
    ];
  }

  function mint(uint quantity) external payable {
    require(isSalesActive, "sale is not active");
    require(totalSupply() + quantity <= maxSupply, "sold out");
    require(quantity <= maxFreeMintsPerTx, "quantity exceeds max mints per tx");
    require(msg.value >= price * quantity, "ether sent is under price");

    for (uint i = 0; i < quantity; i++) {
      safeMint(msg.sender);
    }
  }

  function mintBundle(uint bundleId) payable external {
    require(isSalesActive, "sale is not active");
    require(bundleId < bundlePrices.length, "invalid blundle id");
    require(msg.value >= bundlePrices[bundleId], "not enough ethers");

    uint quantity = bundleSizes[bundleId];

    require(totalSupply() + quantity <= maxSupply, "sold out");

    for (uint i = 0; i < quantity; i++) {
      safeMint(msg.sender);
    }
  }

  function freeMint(uint quantity) external {
    require(isSalesActive, "sale is not active");
    require(totalSupply() + quantity <= maxSupply, "sold out");
    require(totalSupply() + quantity <= maxFreeMints, "quantity exceeds max free mints");
    require(accountToMintedFreeTokens[msg.sender] + quantity <= maxFreeMintsPerWallet, "quantity exceeds allowance");

    for (uint i = 0; i < quantity; i++) {
      safeMint(msg.sender);
    }

    accountToMintedFreeTokens[msg.sender] += quantity;
  }

  function safeMint(address to) internal {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  }

  function totalSupply() public view returns (uint) {
    return _tokenIdCounter.current();
  }

  function setIsSaleActive(bool isSalesActive_) external onlyOwner {
    isSalesActive = isSalesActive_;
  }

  function contractURI() public view returns (string memory) {
    return _contractUri;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _baseUri = newBaseURI;
  }

  function setContractURI(string memory newContractURI) external onlyOwner {
    _contractUri = newContractURI;
  }

  function setPrice(uint newPrice) external onlyOwner {
    price = newPrice;
  }

  function setMaxSupply(uint newSupply) external onlyOwner {
    maxSupply = newSupply;
  }

  function setBundlePrices(uint[] memory newBundlePrices, uint[] memory newBundleSizes) external onlyOwner {
    bundlePrices = newBundlePrices;
    bundleSizes = newBundleSizes;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseUri;
  }

  function withdraw(uint amount) external onlyOwner {
    require(payable(msg.sender).send(amount));
  }

  function withdrawAll() external onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}
