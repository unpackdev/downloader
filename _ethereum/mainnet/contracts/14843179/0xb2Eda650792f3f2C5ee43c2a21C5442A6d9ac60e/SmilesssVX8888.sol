// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// All Smilesss LLC (www.smilesss.com)
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*********************************ALLSMILESSS**********************************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@&(**********/%@@@@@@@@@@@@@@*******************************&(@@@@@@@@@@/%*******************************@@@@@@@@@@@@@&(**********/%@@@@@@@@@@@@@@@@
// @@@@@@@@@@@(********************/&@@@@@@@@@@**************************(@@@@@@@@@@@@@@@@@@@@/&*************************@@@@@@@@@@(********************/&@@@@@@@@@@@
// @@@@@@@@%**************************/@@@@@@@@@**********************%@@@@@@@@@@@@@@@@@@@@@@@@@@/**********************@@@@@@@@%**************************/@@@@@@@@@
// @@@@@@&******************************(@@@@@@@@*******************&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(*******************@@@@@@@&******************************(@@@@@@@
// @@@@@#********************#(***********@@@@@@@@*****************#@@@@@@@@@@@@@@@@@@@@#(@@@@@@@@@@@*****************@@@@@@@#********************#(***********@@@@@@
// @@@@#********************/@@%***********@@@@@@@@***************#@@@@@@@@@@@@@@@@@@@@/**%@@@@@@@@@@@***************@@@@@@@#********************/@@%***********@@@@@
// @@@@/*****@@@@@/*@@@@@%***#@@#***********%@@@@@@@**************/@@@@@*****/@*****%@@@#**#@@@@@@@@@@@%************@@@@@@@@/*****@@@@@/*@@@@@%***#@@#***********%@@@
// @@@@******@@@@@/*@@@@@*****@@@**********#@@@@@@@@@*************@@@@@@*****/@*****@@@@@***@@@@@@@@@@#************@@@@@@@@@******@@@@@/*@@@@@*****@@@**********#@@@@
// @@@@/**********************@@@**********%@@@@@@@@@@************/@@@@@@@@@@@@@@@@@@@@@@***@@@@@@@@@@%***********@@@@@@@@@@/**********************@@@**********%@@@@
// @@@@%*****@@@@@/*@@@@@****#@@#*********(@@@@@@@@@@@@***********%@@@@@*****/@*****@@@@#**#@@@@@@@@@(***********@@@@@@@@@@@%*****@@@@@/*@@@@@****#@@#*********(@@@@@
// @@@@@&****@@@@@/*@@@@@***/@@%*********/@@@@@@@@@@@@@@***********&@@@@*****/@*****@@@/**%@@@@@@@@@/***********@@@@@@@@@@@@@&****@@@@@/*@@@@@***/@@%*********/@@@@@@
// @@@@@@@/******************#(*********%@@@@@@@@@@@@@@@@************/@@@@@@@@@@@@@@@@@@#(@@@@@@@@@%***********@@@@@@@@@@@@@@@@/******************#(*********%@@@@@@@
// @@@@@@@@@/*************************&@@@@@@@@@@@@@@@@@@@*************/@@@@@@@@@@@@@@@@@@@@@@@@@&************@@@@@@@@@@@@@@@@@@@/*************************&@@@@@@@@@
// @@@@@@@@@@@@(*******************%@@@@@@@@@@@@@@@@@@@@@@@***************(@@@@@@@@@@@@@@@@@@@%**************@@@@@@@@@@@@@@@@@@@@@@@(*******************%@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&%(//***/(#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@******************&%(//@@@/(#&******************@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%(//***/(#&@@@@@@@@@@@@@@@@@
// @@S@@@@@@@@@@@@I@@@@@@@@@@@@@@G@@@@@@@@@@@@@N@@@@@@@@@@@@@*O*************R*************C**************R*@@@@@@@@@@@@Y@@@@@@@@@@@@@P@@@@@@@@@@@@@@T@@@@@@@@@@@@@O@@

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract SmilesssVX8888 is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _counter;

  // Smart contract status
  enum MintStatus {
    CLOSED,
    OPEN
  }
  MintStatus public status = MintStatus.CLOSED;

  // ERC721 params
  string private _name = "SMILESSS-VX8888";
  string private _symbol = "VX8888";
  string private _baseTokenURI;

  // Smilesss Contract
  ERC721Enumerable public smilesssContract = ERC721Enumerable(0x177EF8787CEb5D4596b6f011df08C86eb84380dC);

  // Event declaration
  event ChangedStatusEvent(uint256 newStatus);
  event ChangedBaseURIEvent(string newURI);

  // Contructor
  constructor(string memory baseURI) ERC721(_name, _symbol) {
    setBaseURI(baseURI);
  }

  // To be used to claim your pfp
  function claim(uint256[] calldata tokenIds) external nonReentrant{
    require(tx.origin == msg.sender, "Smart contract interactions disabled");

    uint256 tot = tokenIds.length;
    uint256 smilesssvrsSupply = smilesssContract.totalSupply();

    for(uint256 i = 0; i<tot; ++i) {
      uint256 _tokenId = tokenIds[i];
      require(smilesssvrsSupply >= _tokenId, "Invalid ID");
      require(smilesssContract.ownerOf(_tokenId) == msg.sender, "Ownership requirements not satisfied");

      if(_exists(_tokenId)) {
        require(ownerOf(_tokenId) != msg.sender, "Already claimed");
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
      } else {
        _safeMint(msg.sender, _tokenId);
        _counter.increment();
      }
    }    
  }

  // Getters
  function canClaim(uint256 _tokenId, address _address) public view returns(bool) {
    if(_exists(_tokenId)) {
      return (ownerOf(_tokenId) != _address && smilesssContract.ownerOf(_tokenId) == _address);
    } else {
      return true;  
    }
  }

  function claimableBy(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = smilesssContract.balanceOf(_owner);
    uint256 counter = 0;

    for (uint256 i=0; i < tokenCount; i++) {
      uint256 _tokenId = smilesssContract.tokenOfOwnerByIndex(_owner, i);
      if(canClaim(_tokenId, _owner)){
        counter ++;
      }
    }

    uint256 counter2 = 0;
    uint256[] memory tokensId = new uint256[](counter);
    for (uint256 i=0; i < tokenCount; i++) {
      uint256 _tokenId = smilesssContract.tokenOfOwnerByIndex(_owner, i);
      if(canClaim(_tokenId, _owner)){
        tokensId[counter2] = _tokenId;
        counter2++;
      }
    }
    return tokensId;
  }

  function _baseURI() internal view virtual override(ERC721)
    returns (string memory)
  {
    return _baseTokenURI;
  }

  function tokenExists(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  function totalSupply() public view returns (uint256) {
      return _counter.current();
  }

  // Setters
  function setBaseURI(string memory _URI) public onlyOwner {
    _baseTokenURI = _URI;
    emit ChangedBaseURIEvent(_URI);
  }

  function setStatus(uint256 _status) external onlyOwner {
    // _status -> 0: CLOSED, 1: OPEN
    require(_status >= 0 && _status <= 1, "Mint status must be between 0 and 1");
    status = MintStatus(_status);
    emit ChangedStatusEvent(_status);
  }


  // Disable functions
  function approve(address to, uint256 tokenId) public virtual override(ERC721) {
    require(false, "disabled");
  }

  function setApprovalForAll(address operator, bool approved) public virtual override(ERC721) {
    require(false, "disabled");
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721) {
    require(false, "disabled");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721) {
    require(false, "disabled");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override(ERC721) {
    require(false, "disabled");
  }

  function setSmilesssvrs(address _address) external onlyOwner {
    smilesssContract = ERC721Enumerable(_address);
  }
}
