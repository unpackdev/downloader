// SPDX-License-Identifier: MIT

/*                                                                                                        
_|                                                                              _|                      
_|  _|    _|    _|  _|  _|_|    _|_|          _|_|_|    _|_|    _|_|_|  _|_|          _|_|_|    _|_|_|  
_|_|      _|    _|  _|_|      _|    _|      _|        _|    _|  _|    _|    _|  _|  _|        _|_|      
_|  _|    _|    _|  _|        _|    _|      _|        _|    _|  _|    _|    _|  _|  _|            _|_|  
_|    _|    _|_|_|  _|          _|_|          _|_|_|    _|_|    _|    _|    _|  _|    _|_|_|  _|_|_|    
  

Total Supply:1,111
Max 2 per Address
12 Reserved for founders

KOMICPASS✨ is a collection of 1,111 memberships to Kuro Comics

KDAO TOKEN CONTRACT ADDRESS: 0xE0703247AC5A9cBda3647713cA810Fb9c7025123

https://kurocomics.com
*/

pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract KomicPass is Ownable, ERC721A, ReentrancyGuard {

  using SafeMath for uint256;

  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  uint256 private publicPrice = 250000000000000000; // 0.25 ETH
  
  bool public contractLocked = false;
  bool public publicSale = false;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_
  ) ERC721A("KOMICPASS", "KOMICPASS", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForDevs = amountForDevs_;
    require(amountForDevs_ <= collectionSize_,"larger collection size needed");
  }

  // Check user is not contract
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  // Mint function
  function mintComicPass(uint256 quantity) external payable callerIsUser {
    // By calling this function, you agreed that you have understood the risks involved with using smart this contract.
    require(publicSale == true, "Sales have not started");

    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,"can not mint this many");
    
    require(msg.value >= publicPrice * quantity, "insufficient funds");
    _safeMint(msg.sender, quantity);
  }

  // Toggle public sales
  function togglePublicSales() public onlyOwner {
        publicSale = !publicSale;
 }

  // For team
  function teamMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= amountForDevs,"too many already minted before team mint");
    require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize");
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  // Metadata URI
  string private _baseTokenURI;

  // Lock Contract
  function lockContract() public onlyOwner {
    contractLocked = true;   
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    require(contractLocked == false, "Contract has been locked and URI can't be changed");
    _baseTokenURI = baseURI;
  }

  function withdrawEth() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }
}