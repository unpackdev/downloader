// SPDX-License-Identifier: MIT
// contract written by @certainxp

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MemorialNFT is ERC721, Ownable {
  using Strings for uint256;

  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;

  string public ipfsURIKiss = '';
  string public ipfsURIHair = '';
  string public ipfsURIEyes = '';

  mapping(uint256 => uint256) public tokenTypeById;

  uint256 public preSalePrice = 0.08 ether;
  uint256 public publicSalePrice = 0.1 ether;

  uint256 public constant preSaleAmount = 66;
  uint256 public constant publicSaleAmount = 266;

  uint256 public kissAmountMinted;
  uint256 public hairAmountMinted;
  uint256 public eyesAmountMinted;
  uint256 public constant maxSupply = 10000;
  uint256 public constant ownerMintLimit = 100;

  bool public presaleActive = false;
  bool public publicSaleActive = false;

  constructor(string memory _ipfsURIKiss, string memory _ipfsURIHair, string memory _ipfsURIEyes) ERC721("Memorial NFT", "MNFT") {
    _nextTokenId.increment();
    ipfsURIKiss = _ipfsURIKiss;
    ipfsURIHair = _ipfsURIHair;
    ipfsURIEyes = _ipfsURIEyes;
  }

  // Public mint function
  function mint(uint256 _kind, uint256 _mintAmount) public payable {
    require(presaleActive || publicSaleActive, "Mint is paused");

    if (_kind == 1) {
      if(presaleActive) {
        require(hairAmountMinted + _mintAmount < preSaleAmount, "All this type NFT were already minted");
      } else {
        require(hairAmountMinted + _mintAmount < preSaleAmount + publicSaleAmount, "All this type NFT were already minted");
      }
      hairAmountMinted += _mintAmount;
    } else if (_kind == 2) {
      if(presaleActive) {
        require(kissAmountMinted + _mintAmount < preSaleAmount, "All this type NFT were already minted");
      } else {
        require(kissAmountMinted + _mintAmount < preSaleAmount + publicSaleAmount, "All this type NFT were already minted");
      }
      kissAmountMinted += _mintAmount;
    } else {
      if(presaleActive) {
        require(eyesAmountMinted + _mintAmount < preSaleAmount, "All this type NFT were already minted");
      } else {
        require(eyesAmountMinted + _mintAmount < preSaleAmount + publicSaleAmount, "All this type NFT were already minted");
      }
      eyesAmountMinted += _mintAmount;
    }
    uint256 price = preSalePrice;
    if (publicSaleActive) {
      price = publicSalePrice;
    }

    require(msg.value >= price * _mintAmount, "insufficient funds");
    require(msg.sender == tx.origin, "caller should not be a contract.");

    for (uint256 i = 0; i < _mintAmount; i++) {
	    tokenTypeById[_nextTokenId.current()] = _kind;
      _safeMint(msg.sender, _nextTokenId.current());
      _nextTokenId.increment();
    }
  }

  // Owner mint function
  function ownerMint(address _to, uint256 _kind, uint256 _mintAmount) public onlyOwner {
    if (_kind == 1) {
      if(presaleActive) {
        require(hairAmountMinted + _mintAmount < preSaleAmount, "All this type NFT were already minted");
      } else {
        require(hairAmountMinted + _mintAmount < preSaleAmount + publicSaleAmount, "All this type NFT were already minted");
      }
      hairAmountMinted += _mintAmount;
    } else if (_kind == 2) {
      if(presaleActive) {
        require(kissAmountMinted + _mintAmount < preSaleAmount, "All this type NFT were already minted");
      } else {
        require(kissAmountMinted + _mintAmount < preSaleAmount + publicSaleAmount, "All this type NFT were already minted");
      }
      kissAmountMinted += _mintAmount;
    } else {
      if(presaleActive) {
        require(eyesAmountMinted + _mintAmount < preSaleAmount, "All this type NFT were already minted");
      } else {
        require(eyesAmountMinted + _mintAmount < preSaleAmount + publicSaleAmount, "All this type NFT were already minted");
      }
      eyesAmountMinted += _mintAmount;
    }
    for (uint256 i = 0; i < _mintAmount; i++) {
	    tokenTypeById[_nextTokenId.current()] = _kind;
      _safeMint(_to, _nextTokenId.current());
      _nextTokenId.increment();
    }
  }

  // Function to return the total supply
  function totalSupply() public view returns (uint256) {
      return _nextTokenId.current() - 1;
  }

  // Function to set the mint price  
  function setPresalePrice(uint256 _newPrice) public onlyOwner {
    preSalePrice = _newPrice;
  }

  // Function to set the mint price  
  function setPublicSalePrice(uint256 _newPrice) public onlyOwner {
    publicSalePrice = _newPrice;
  }

  // return URI for each NFT
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    uint kind = tokenTypeById[tokenId];
    if (kind == 0) {
      return ipfsURIHair;
    } else if (kind == 1) {
      return ipfsURIKiss;
    }
    return ipfsURIEyes;
	}

  // Function to get current sale price
  function currentPrice() public view returns (uint256) {
    if (presaleActive) {
      return preSalePrice;
    }
    return publicSalePrice;
  }

  // Function to toggle the presale mint
  function togglePresaleMint() public onlyOwner {
    presaleActive = !presaleActive;
  }

  // Function to toggle the public mint
  function togglePublicSaleMint() public onlyOwner {
    presaleActive = false;
    publicSaleActive = !publicSaleActive;
  }

  // PARTY TIME! Function to change the ipfs kiss URI
  function setKissURI(string memory _ipfsURI) public onlyOwner {
    ipfsURIKiss = _ipfsURI;
  }

  // PARTY TIME! Function to change the ipfs hair URI
  function setHairURI(string memory _ipfsURI) public onlyOwner {
    ipfsURIHair = _ipfsURI;
  }

  // PARTY TIME! Function to change the ipfs eyes URI
  function setEyesURI(string memory _ipfsURI) public onlyOwner {
    ipfsURIEyes = _ipfsURI;
  }

  // Function to withdraw funds from the contract
  function withdrawBalance() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}