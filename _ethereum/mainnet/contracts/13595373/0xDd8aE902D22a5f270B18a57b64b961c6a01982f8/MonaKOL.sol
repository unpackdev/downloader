// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IMonaKOL.sol";
import "./IMonaKOLMetadata.sol";

contract MonaKOL is ERC721Enumerable, Ownable, IMonaKOL, IMonaKOLMetadata, ReentrancyGuard {

  using Strings for uint256;
  
  uint256 public constant TOTAL_LIMIT = 100;
  
  bool public isSaleActive;

  uint256 public minted;

  mapping(address => bool) private _mintList;

  string private _contractURI;
  
  string private _tokenBaseURI;

  constructor(
    string memory name,
    string memory symbol
  ) ERC721(name, symbol) {}

  function isOnMintList(address addr)
    external
    view
    override
    returns (bool)
  {
    return _mintList[addr];
  }  

  function addToMintList(address[] calldata addresses)
    external
    override
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can not add the null address");
      _mintList[addresses[i]] = true;      
    }
  }

  function removeFromMintList(address[] calldata addresses)
    external
    override
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can not add the null address");
      delete _mintList[addresses[i]];      
    }
  }

  function mint()
    external
    override
    payable
    nonReentrant
  {
    require(isSaleActive, "no sale active");
    require(_mintList[msg.sender],
            "You are not on the KOL List");
    require(minted + 1 < TOTAL_LIMIT, "out of limit");    

    uint256 tokenId = minted;
    minted++;
    _mintList[msg.sender] = false;
    _safeMint(msg.sender, tokenId);
  }

  function withdraw() external override onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setSaleActive(bool active) external override onlyOwner {
    isSaleActive = active;
  }

  function setContractURI(string calldata URI) external override onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external override onlyOwner {
    _tokenBaseURI = URI;
  }

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    return bytes(_tokenBaseURI).length > 0 ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : "";    
  }
  
}
