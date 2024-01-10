// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./ERC721A.sol";
import "./Ownable.sol";

contract KillerKoalas is ERC721A, Ownable {
   bool activeSale = false;
   string public baseTokenURI;
   uint256 MAX_SUPPLY = 3333; // Total Number of NFTs
   uint256 _price = 33000000000000000; //Price of NFTs 0.033 ETH

   // // metadata URI
   string private _baseTokenURI;
   event mintedNFTID(address sender, uint256 currentTotalSupply);

   constructor(string memory baseURI) ERC721A("KillerKoalas", "KK") { //KillerKoala ERC721A Contract
   }

   /// metadata URI
   function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
   }
   function setBaseURI(string calldata baseURI) external onlyOwner{
      _baseTokenURI = baseURI;
   }  

   //KillerKoalas NFT Sale State - Active/Inactive
   function updateSaleState(bool newState) external onlyOwner {
      activeSale = newState;
   }
   
   //Calculate the price for the number of tokens for validation
   function calculatePrice(uint256 numTokens) private view returns (uint256) {
      uint tokenPrice;
      tokenPrice = _price * numTokens;
      return tokenPrice; 
  }

  //Mint Function
   function mintNFT(uint256 numTokens) external payable{
      uint256 price = calculatePrice(numTokens);
      require(activeSale, "NFT sale must be active");
      require(msg.value >= price, "Amount of Ether sent is not correct.");
      require(totalSupply() + numTokens <= MAX_SUPPLY, "reached max supply");

      _safeMint(msg.sender, numTokens);
      emit mintedNFTID(msg.sender, totalSupply());
   }

   //Reserve NFT function for airdrop
   function reserveNFTs(uint256 numTokens) external onlyOwner{
      require(totalSupply() + numTokens <= MAX_SUPPLY, "reached max supply");
      _safeMint(msg.sender, numTokens);
   }

   function withdrawAll() external payable onlyOwner{
        uint256 _each = address(this).balance / 100;
        require(payable(t1).send(_each * 44));
        require(payable(t2).send(_each * 44));
        require(payable(t3).send(_each * 6));
        require(payable(t4).send(_each * 6));
   }
   address t1 = 0xe49325fB30874aA8218e6dd4E7Ea10782Ba97919;
   address t2 = 0x994f7b308Eba2A98aad163429b1c7c597BF4646c;
   address t3 = 0xBd63058D5ad7AcEEC812b80D781F56De0666C075;
   address t4 = 0x8E538a56F063c62D63A7941474B26593563b13Cb;

}