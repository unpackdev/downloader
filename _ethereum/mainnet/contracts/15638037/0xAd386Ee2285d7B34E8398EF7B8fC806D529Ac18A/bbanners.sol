//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract BullishBanners is Ownable, ERC721A {
   using SafeMath for uint256;

   uint256 public collectionSize = 868;

   // === Max Mint Amounts per address ===
   uint256 public holdersQty = 1;

   // === Max Amount Per TX ===
   uint256 public publicAmountPerTx = 10;

   // === Reserved Mint Amounts ===
   uint256 public holdersResAmount = 50;

   // === To Check Private and VIP total Supplies ===
   uint256 public holdersTotalMinted = 0;

   // === Merkle List Configurations ===
   bytes32 public holdersRoot;

   // === Price Configurations ===
   uint256 public publicPrice = .02 ether;
   uint256 public holdersPrice = 0 ether;

   // == WALLETS == //
   address private constant ADDR1 = 0x5CB222516C12b876FD99d3903DeAd1bA18Bd950e;
   address private constant ADDR2 = 0x36202127220bBd5E123cE9747ef8983B2EA9D9d6;
   address private constant ADDR3 = 0xD68773132308D3FFaE55A719907e87cF00034cfF;

   // == Sale State Configuration ===
   enum SaleState {
     OFF,
     PUBLIC
   }

   SaleState public saleState = SaleState.OFF;

   string private baseURI;

   mapping(address => uint256) private holdersTracker;

   constructor(string memory initBaseUri) ERC721A("BullishBanners", "BBANNERS") {
     updateBaseUri(initBaseUri);
   }

   // *** Merkle Proofs ***
   // ===============================================================================

   function setholdersRoot(bytes32 _holdersRoot) public onlyOwner {
     holdersRoot = _holdersRoot;
   }

   function isholdersValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
     return MerkleProof.verify(proof, holdersRoot, leaf);
   }

// *** MINT FUNCTIONS ***
// ===============================================================================
/*
* public Sale Minting Function
*/
   function publicSale(uint256 quantity) external payable
   {
       require(
         saleState == SaleState.PUBLIC,
         "PUBLIC sale is not active"
         );
       require(
         publicPrice * quantity <= msg.value,
         "Insufficient funds sent."
       );
       securepublic(quantity);
  }


// ===============================================================================
/*
* holders Sale Minting Function
*/
   function holdersSale(bytes32[] calldata merkleProof, uint256 quantity) external payable
   {
       require(
         saleState == SaleState.PUBLIC,
         "HOLDERS sale is not active"
         );
       require(
         isholdersValid(merkleProof,
         keccak256(
             abi.encodePacked(msg.sender)
             )
         ),
         "Error - Verify Qualification"
       );
       require(
         holdersPrice * quantity <= msg.value,
         "Insufficient funds sent."
       );
       require(
         holdersTracker[msg.sender] + quantity <= holdersQty,
         "Already Minted Max Amount."
       );
       secureholders(quantity);
       holdersTracker[msg.sender] = holdersTracker[msg.sender] + quantity;
       holdersTotalMinted = holdersTotalMinted + quantity;
  }

// Secure public internal function.
   function securepublic(uint256 quantity) internal {
       require(
           quantity > 0,
           "Quantity cannot be zero"
       );
       require(
           totalSupply().add(quantity) <= collectionSize,
           "No items left to mint"
       );
       require(
           quantity <= publicAmountPerTx,
           "Too many tokens for one transaction."
       );
       _safeMint(msg.sender, quantity);
   }

// Secure holders internal function.
   function secureholders(uint256 quantity) internal {
       require(
           quantity > 0,
           "Quantity cannot be zero"
       );
       require(
           totalSupply().add(quantity) <= collectionSize,
           "No items left to mint"
       );
       require(
           holdersTotalMinted + quantity <= holdersResAmount,
           "Reached holders Sale Limit."
       );
       _safeMint(msg.sender, quantity);
   }

   function checkHoldersMinted(address owner) public view returns (uint256) {
     return holdersTracker[owner];   
   }


/*
* Airdrop Mint Function
*/
   function _ownerMint(address to, uint256 numberOfTokens) private {
       require(
           totalSupply() + numberOfTokens <= collectionSize,
           "Not enough tokens left"
       );

        _safeMint(to, numberOfTokens);
   }

   function ownerMint(address to, uint256 numberOfTokens) public onlyOwner {
        _ownerMint(to, numberOfTokens);
   }

// *** START/STOP SALES ***
// ===============================================================================
/**
* Set Sale State
* @param saleState_ 0: OFF, 1: public
*/
   function setSaleState(SaleState saleState_) external onlyOwner {
      saleState = saleState_;
   }

// *** METADATA URI ***
// ===============================================================================
/**
* Sets base URI
* @dev Only use this method after sell out as it will leak unminted token data.
*/
   function updateBaseUri(string memory baseUri) public onlyOwner {
       baseURI = baseUri;
   }

   function _baseURI() internal view virtual override returns (string memory) {
       return baseURI;
   }

/**
* Change public Mint Price
* @param _newPublicPrice Amount in WEI
*/
   function setPublicPrice(uint256 _newPublicPrice) public onlyOwner {
     publicPrice = _newPublicPrice;   
   }

// *** Team Withdrawal *** //
   function withdrawTeamSplit() public onlyOwner {
      uint balance = address(this).balance;
      payable(ADDR1).transfer(balance * 34 / 100);
      payable(ADDR2).transfer(balance * 33 / 100);
      payable(ADDR3).transfer(balance * 33 / 100);
   }

// *** Dev Withdrawal *** //
   function withdrawDev() public onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
   }
}