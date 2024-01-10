// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Passages is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public _baseTokenURI;
  
  uint256 public constant maxSupply = 800;
  uint256 public price = 0.08 ether;
  uint256 public maxMintAmountPerTx = 5;

  bool public saleActive = false;

  constructor() ERC721("Passages", "PSG") {
    _baseTokenURI = "ipfs://QmP3BYoGotb6NGrxxHGWJiS1MoheLQLGoCrFaPr5uuRtiv/";
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function refundIfOver(uint256 _price) private {
    require(msg.value >= _price, "Need to send more ETH.");
    if (msg.value > _price) {
      payable(msg.sender).transfer(msg.value - _price);
    }
  }

  function mint(uint256 _mintAmount) public payable {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded");
    require(saleActive, "Sale is not active");
    
    if (msg.sender != owner()) {
      refundIfOver(price * _mintAmount);
    }

    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(msg.sender, supply.current());
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 _supply = totalSupply();
    uint256[] memory tokenIds = new uint256[](balanceOf(_owner));

    uint256 currIndex = 0;
    for (uint256 i = 1; i <= _supply; i++) {
        if (_owner == ownerOf(i)) tokenIds[currIndex++] = i;
    }

    return tokenIds;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setSaleState(bool _state) public onlyOwner {
    saleActive = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
}