// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./IERC721AQueryable.sol";
import "./ERC165.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract gridBlocks is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
  bool public mintNotReady = true;
  string public baseURI = "ipfs:///";
  uint256 public cost = 0.002 ether;
  uint256 public maxSupply = 3333;
  uint256 public maxPerWallet = 50;
  using Strings for uint256;
  constructor () ERC721A("gridBlocks", "GBLOCKS") {
    }

  function mint(uint256 _mintAmount) public payable {
    require(!mintNotReady, 'The publicMint is paused!');
    require(_mintAmount > 0);
    require(_numberMinted(msg.sender) + _mintAmount <= maxPerWallet);
    require(totalSupply() + _mintAmount <= maxSupply, 'No Supply Left!');
    require(msg.value >= cost * _mintAmount, 'Insufficient Eth sent!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
    require(_newMaxSupply <= totalSupply(), "New max supply must be greater than the current total supply");
    maxSupply = _newMaxSupply;
  }

  function airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setMaxMintAmountPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setMintReady(bool _state) public onlyOwner {
    mintNotReady = _state;
  }

  function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }
}