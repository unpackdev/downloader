// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract certaincentaurs is ERC721A, Ownable {
    uint256 public maxMintAmountPerTxn = 5;
    uint256 public maxFreeMintPerWalletAmount = 1;
    uint256 public maxSupply = 3000;
    uint256 public mintPrice = 0.003 ether;
    bool public paused = true;

    string public baseURI = "";

    constructor() ERC721A("Certain Centaurs", "cece") {}

    function reserveNFTs() public onlyOwner {
            _safeMint(msg.sender, 100);
    }

    modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "The contract is paused!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(_mintAmount > 0 &&  _numberMinted(msg.sender) + _mintAmount <= maxMintAmountPerTxn, "Invalid mint amount!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 costToSubtract = 0;
    
    if (_numberMinted(msg.sender) < maxFreeMintPerWalletAmount) {
      uint256 freeMintsLeft = maxFreeMintPerWalletAmount - _numberMinted(msg.sender);
      costToSubtract = mintPrice * freeMintsLeft;
    }
   
    require(msg.value >= mintPrice * _mintAmount - costToSubtract, "Insufficient funds!");
    _;
  }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        _safeMint(_msgSender(), _mintAmount);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

      function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMints(uint256 _maxMintAmountPerTxn) public onlyOwner {
        maxMintAmountPerTxn = _maxMintAmountPerTxn;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
}