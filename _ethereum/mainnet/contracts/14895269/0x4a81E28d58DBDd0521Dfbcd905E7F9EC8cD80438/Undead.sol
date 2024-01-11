// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

error AmountExceedsSupply();
error AmountExceedsTransactionLimit();
error OnlyExternallyOwnedAccountsAllowed();
error InsufficientPayment();

contract Undead is ERC721A, Ownable, ReentrancyGuard {

  address private _treasury;
  string private _baseTokenURI;
  uint256 private _salePrice = 0.0033 ether;
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 private totalFree = 6677;
  uint256 private devMint = 100;

  mapping(address => uint256) private _roundMinted;

  constructor(address treasury, string memory baseURI) ERC721A("UNDEAD", "UNDEAD") {
    _baseTokenURI = baseURI;
    _treasury = treasury;
    _safeMint(treasury, devMint);
  }

  function setSalePrice(uint256 price) external onlyOwner {
    _salePrice = price;
  }

  function renounceOwnership() public view override onlyOwner {
    revert("can't renounceOwnership here");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function tokensOf(address owner) public view returns (uint256[] memory){
    uint256 count = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](count);
    for (uint256 i; i < count; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }

  modifier onlyEOA() {
    if (tx.origin != msg.sender) revert OnlyExternallyOwnedAccountsAllowed();
    _;
  }

  function checkExceedMintedLimit (address minter, uint256 quantity, uint256 cost) internal view returns (bool) {
    if(cost == 0) {
      return  _roundMinted[minter] + quantity > 1;
    } else {
      return _roundMinted[minter] + quantity > 3;
    }
  }

  function mint(uint256 quantity) external payable nonReentrant onlyEOA {
    
    if (totalSupply() + quantity > MAX_SUPPLY)  revert AmountExceedsSupply();
    uint256 cost = _salePrice;
    if(totalSupply() + quantity < devMint + totalFree + 1) {
      cost = 0;
    }
    if (msg.value < quantity * cost) revert InsufficientPayment();
    if (checkExceedMintedLimit(msg.sender, quantity, cost)) revert AmountExceedsTransactionLimit();

    _roundMinted[msg.sender] = _roundMinted[msg.sender] + quantity;
    _safeMint(msg.sender, quantity);
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = _treasury.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}