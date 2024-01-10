// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol"; 
import "./Ownable.sol";

contract BCPIE is ERC721A, Ownable {
  
    uint256 public mintPrice = 0.04 ether;
    uint256 public maxSupply = 2222;
    uint256 public maxPerTxn;
    string internal baseUri;
    string public tokenUriExt = ".json";

    bool public mintLive;
    address payable public charityWallet;

    modifier mintIsLive() {
        require(mintLive, "mint not live");
        _;
    }

  constructor(
    uint256 _maxSupply,
    uint256 _maxPerTxn,
    string memory initBaseURI
  ) ERC721A ("Bored Cutie Pie Club", "BCPIE", _maxSupply, _maxPerTxn) {

    maxSupply = _maxSupply;
    maxPerTxn = _maxPerTxn;
    baseUri = initBaseURI;
    _safeMint(msg.sender, 1);
  }

  //Internal

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }


   //Owner Functions

   function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    maxSupply = maxSupply_;
  }

   function setPriceInWei(uint256 price_) external onlyOwner {
    mintPrice = price_;
  }

  function setBaseUri(string calldata newBaseUri_) external onlyOwner
  {
    baseUri = newBaseUri_;
  }

  function setTokenUriExt(string calldata newTokenUriExt_) external onlyOwner
  {
    tokenUriExt = newTokenUriExt_;
  }

  function setCharityWallet(address charityWallet_) external onlyOwner {
    charityWallet = payable(charityWallet_);
  }

  function toggleMintLive() external onlyOwner {
        if (mintLive) {
            mintLive = false;
            return;
        }
        mintLive = true;
    }

   function setMaxPerTxn(uint256 maxPerTxn_) external onlyOwner {
    maxPerTxn = maxPerTxn_;
  }

  function withdraw() external onlyOwner {
    
    (bool hs,) = payable(charityWallet).call{value : address(this).balance * 70 / 100}("");
    require(hs);
    
    (bool os,) = payable(owner()).call{value : address(this).balance}("");
    require(os);
  }

  //Minting Function

  function mint(uint256 quantity_) external payable {
    require(mintLive, "minting not live");
    require(tx.origin == msg.sender, "contracts not allowed");
    require(msg.value == getPrice(quantity_), "wrong value");
    require(totalSupply() < maxSupply, "sold out");
    require(totalSupply() + quantity_ <= maxSupply, "exceeds max supply");
    require(quantity_ <= maxPerTxn, "exceeds max per txn");

    _safeMint(msg.sender, quantity_);
  }

  function airdrop(address _to, uint256 quantity_) external onlyOwner {
    require(totalSupply() + quantity_ <= maxSupply, "exceeds max supply");
    _safeMint(_to, quantity_);
  }

  //Public Functions

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function multiTransferFrom(address from_, address to_, uint256[] calldata tokenIds_) public {
    
    uint256 tokenIdsLength = tokenIds_.length;
    for (uint256 i = 0; i < tokenIdsLength; i++) {
      transferFrom(from_, to_, tokenIds_[i]);
    }
  }

  function multiSafeTransferFrom(address from_, address to_, uint256[] calldata tokenIds_, bytes calldata data_) 
  public {
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      safeTransferFrom(from_, to_, tokenIds_[i], data_);
    }
  }
    
  function getPrice(uint256 quantity_) public view returns (uint256) {
    return mintPrice * quantity_;
  }

  function tokenURI(uint256 tokenId_) public view override returns (string memory)
  {
    require(_exists(tokenId_), "Token does not exist!");
    return
      string(abi.encodePacked(baseUri, Strings.toString(tokenId_), tokenUriExt));
  }
}

        
        