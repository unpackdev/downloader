// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

contract pixelgoblintownwtf is ERC721A, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    bool public publicSale = true;
    string public baseURI;
    uint256 public cost = 0.005 ether;
    uint256 public maxSupply = 5000;
    uint256 public maxFree = 2000;
    uint256 public maxperAddressFreeLimit = 4;
    uint256 public maxperAddressPublicMint = 10;

    mapping(address => uint256) public addressFreeMintedBalance;

    constructor(
        string memory _baseUri
    ) ERC721A("pixel goblintown.wtf", "PXLGOBTWN") {
        setBaseURI(_baseUri);

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

      // public sale
  modifier publicSaleOpen() {
      require(publicSale, "Public Sale Not Started");
      _;
  }
 
  function togglePublicSale() external onlyOwner {
      publicSale = !publicSale;
  }

//   free mint

    function mintFree(uint256 _mintAmount) public payable nonReentrant publicSaleOpen {
		uint256 s = totalSupply();
        uint256 addressFreeMintedCount = addressFreeMintedBalance[msg.sender];
        require(addressFreeMintedCount + _mintAmount <= maxperAddressFreeLimit, "Exceed Max Per Wallet");
		require(_mintAmount > 0, "Cant mint 0" );
		require(s + _mintAmount <= maxFree, "Sold Out" );
		for (uint256 i = 0; i < _mintAmount; ++i) {
            addressFreeMintedBalance[msg.sender]++;

		}
        _safeMint(msg.sender, _mintAmount);
		delete s;
        delete addressFreeMintedCount;
	}

// public mint

    function mintPublic(uint256 _mintAmount) public payable nonReentrant publicSaleOpen {
        uint256 s = totalSupply();
        require(_mintAmount > 0, "Cant mint 0");
        require(_mintAmount <= maxperAddressPublicMint, "Exceed Max Mint" );
        require(s + _mintAmount <= maxSupply, "Sold Out");
        require(msg.value >= cost * _mintAmount);
        _safeMint(msg.sender, _mintAmount);
        delete s;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
                : "";
    }


// functions
 function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

  function adminMint(address _recipient, uint256 _quantity)
      public
      onlyOwner
  {
      require(totalSupply() + _quantity <= maxSupply);
      _safeMint(_recipient, _quantity);
  }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawAny(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }
}