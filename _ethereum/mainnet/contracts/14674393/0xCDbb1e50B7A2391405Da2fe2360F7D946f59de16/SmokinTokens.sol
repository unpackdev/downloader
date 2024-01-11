// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SmokinTokens is ERC721Enumerable, Ownable {

  using Strings for uint256;
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealURI;
  address[] public WW;
  mapping(address => uint256) public WB;
  bool public isReveal = false;
  bool public isPause = false;
  bool public isWhitelistMode = true;
  uint256 public Price = 0.05 ether;
  uint256 public WLPrice = 0.03 ether;
  uint256 public MaxToken = 3333;

  constructor(string memory _initBaseURI,string memory _initnotRevealURI)
    ERC721("Smokin' Tokens", "ST") { setBaseURI(_initBaseURI); setnotRevealURI(_initnotRevealURI); }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(isReveal == false) {
        return notRevealURI;
    }
    string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  function isWW(address _user) public view returns (bool) {
    for (uint i = 0; i < WW.length; i++) {
      if (WW[i] == _user) { return true;
      }
    } return false;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    } return tokenIds;
  }

  function mint(uint256 _mintAmount) public payable {
    require(!isPause, "Paused!");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "Select 1 NFT");
    require(supply + _mintAmount <= MaxToken, "Sold Out");   
     if (msg.sender != owner()) {
        if (isWhitelistMode == true) {
            require(isWW(msg.sender), "Wallet not Whitelisted");
            uint256 ownerMintedCount = WB[msg.sender];
            require(ownerMintedCount + _mintAmount <= 10, "Max NFTs Reached");
            require(msg.value >= WLPrice * _mintAmount, "WL: Balance Insufficient");
        }
        else {
            require(!isWhitelistMode, "Whitelist ON");
            uint256 ownerMintedCount = WB[msg.sender];
            require(ownerMintedCount + _mintAmount <= 10, "Max NFTs Reached");
            require(msg.value >= Price * _mintAmount, "MS: Balance Insufficient"); 
        }
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      WB[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function Airdrop(address _to, uint256 _mintAmount) external onlyOwner() {
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= MaxToken, "Sold Out" );
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
        }
  }

  function ownerMint(uint256 _mintAmount) external onlyOwner() {
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= MaxToken, "Sold Out" );
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
        }
  }

  function RevealMode() public onlyOwner {
    isReveal = true;
  }

  function addWL(address[] calldata _users) public onlyOwner {
    delete WW;
    WW = _users;
  }

  function PauseMode(bool _state) public onlyOwner {
    isPause = _state;
  }

  function WhitelistMode(bool _state) public onlyOwner {
    isWhitelistMode = _state;
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    Price = _newPrice;
  }

  function setWLPrice(uint256 _newWLPrice) public onlyOwner {
    WLPrice = _newWLPrice;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setnotRevealURI(string memory _notRevealURI) public onlyOwner {
    notRevealURI = _notRevealURI;
  }
 
  function withdraw() public payable onlyOwner {
    (bool mod, ) = payable(owner()).call{value: address(this).balance}("");
    require(mod);
  }
}