// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract HonsBunsNFT is ERC721A, Ownable {
  using Strings for uint256;

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  enum CouponType {
    AllowList
  }

  bool public saleIsActive = false;
  bool public isAllowListActive = false;

  uint public _phase1Max = 2500;
  uint public _phase2Max = 5000;
  uint public _phase3Max = 7500;
  uint public _maxSupply = 10000;
  uint public _maxPublicMint;
  uint public _maxAllowListMint;
  uint public _pricePerToken = 0.03 ether;

  mapping(uint8 => string) public _tokenURI;
  mapping(address => uint8) private _allowList;

  address private immutable _adminSigner;

  constructor(
    address adminSigner, 
    uint256 phase1Max, 
    uint256 phase2Max, 
    uint256 phase3Max, 
    uint256 maxSupply,
    uint256 maxPublicMint,
    uint256 maxAllowListMint
  ) ERC721A("HonsBuns NFT", "BUNS") {
    _adminSigner = adminSigner;
    _phase1Max = phase1Max;
    _phase2Max = phase2Max;
    _phase3Max = phase3Max;
    _maxSupply = maxSupply;
    _maxPublicMint = maxPublicMint;
    _maxAllowListMint = maxAllowListMint;
  }

  // Setters
  // =============================
  function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
    isAllowListActive = _isAllowListActive;
  }

  function setMaxSupply(uint maxSupply) external onlyOwner {
    _maxSupply = maxSupply;
  }

  function setMaxPublicMint(uint maxPublicMint) external onlyOwner {
    _maxPublicMint = maxPublicMint;
  }

  function setPricePerToken(uint pricePerToken) external onlyOwner {
    _pricePerToken = pricePerToken;
  }

  function setMaxAllowListLimit(uint maxAllowListMint) external onlyOwner {
    _maxAllowListMint = maxAllowListMint;
  }

  function numAvailableToMint(address addr) external view returns (uint256) {
    return _maxPublicMint - _allowList[addr];
  }

  function setTokenURI(uint8 _phase, string memory uri) external onlyOwner {
    _tokenURI[_phase] = uri;
  }

  function setSaleState(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  // Getters
  // =============================

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI(tokenId);
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function _baseURI(uint256 _tokenId) internal view virtual returns(string memory) {
    if (_tokenId >= 0 && _tokenId <= _phase1Max) {
      return _tokenURI[1];
    }
    if (_tokenId > _phase1Max && _tokenId <= _phase2Max) {
      return _tokenURI[2];
    }

    if (_tokenId > _phase2Max && _tokenId <= _phase3Max) {
      return _tokenURI[3];
    }

    if (_tokenId > _phase3Max) {
      return _tokenURI[4];
    }

    return _tokenURI[1];
  }

  // Utils
  // =============================
  function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);

    // Check for Zero address
    require(signer != address(0), "ECDSA: invalid signature");
    
    return signer == _adminSigner;
  }

  // Minting
  // =============================
  function mintAllowList(uint8 numberOfTokens, Coupon memory coupon) external payable {
    uint256 ts = totalSupply();

    require(isAllowListActive, "Allow list not active");
    require(numberOfTokens + _allowList[msg.sender] <= _maxAllowListMint, "Exceeded max allow list limit");
    require(ts + numberOfTokens <= _maxSupply, "Purchase exceeds max supply"); 
    require(_pricePerToken * numberOfTokens <= msg.value, "Ether value sent insufficient"); 

    // Create digest for coupon validation
		bytes32 digest = keccak256(abi.encode(CouponType.AllowList, msg.sender));

    // Validate coupon
    require(_isVerifiedCoupon(digest, coupon), "Invalid coupon"); 

    // Add to total tokens
    _allowList[msg.sender] += numberOfTokens; 

    _safeMint(msg.sender, numberOfTokens);
  }

  function mint(uint numberOfTokens) public payable {
    uint256 ts = totalSupply();

    require(saleIsActive, "Sale must be active to mint");
    require(numberOfTokens <= _maxPublicMint, "Exceeded max token limit");
    require(numberOfTokens + _allowList[msg.sender] <= _maxPublicMint, "Exceeded max token limit");
    require(ts + numberOfTokens <= _maxSupply, "Purchase exceeds max supply");
    require(_pricePerToken * numberOfTokens <= msg.value, "Ether value sent insufficient");

    _safeMint(msg.sender, numberOfTokens);
  }

  // Owner
  // =============================
  function reserve(uint256 numberOfTokens) public onlyOwner {
    _safeMint(msg.sender, numberOfTokens);
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;

    require(balance > 0, "Nothing to withdraw");

    payable(msg.sender).transfer(balance);
  }
}

