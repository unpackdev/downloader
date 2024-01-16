// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721r.sol";

/*

╭━━━┳╮╱╱╭━━━╮╭━╮╭━╮╭╮╱╱╭┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━╮
┃╭━╮┃┃╱╱┃╭━╮┃╰╮╰╯╭╯┃╰╮╭╯┃╭━━┫╭━╮┃╭━╮┃╭━━┫╭━╮┃╭━━┫╭━╮┃╭━╮┃╭━╮┃╭━╮┃
┃╰━╯┃┃╱╱┃╰━╯┃╱╰╮╭╯╱╰╮┃┃╭┫╰━━┫╰━╯┃╰━━┫╰━━┫╰━━┫╰━━┫╰━╯┃╰━╯┃┃╱┃┃╰━╯┃
┃╭━━┫┃╱╭┫╭━━╯╱╭╯╰╮╱╱┃╰╯┃┃╭━━┫╭╮╭┻━━╮┃╭━━┻━━╮┃╭━━┫╭━━┫╭╮╭┫┃╱┃┃╭━━╯
┃┃╱╱┃╰━╯┃┃╱╱╱╭╯╭╮╰╮╱╰╮╭╯┃╰━━┫┃┃╰┫╰━╯┃╰━━┫╰━╯┃╰━━┫┃╱╱┃┃┃╰┫╰━╯┃┃
╰╯╱╱╰━━━┻╯╱╱╱╰━╯╰━╯╱╱╰╯╱╰━━━┻╯╰━┻━━━┻━━━┻━━━┻━━━┻╯╱╱╰╯╰━┻━━━┻╯
╭━━━━┳╮╱╭┳━━━╮╭━━━┳╮╭━┳╮╱╱╭┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━╮╭━━━┳━━━┳╮╱╱╭╮╱╱╭━━━┳━━━┳━━━━┳━━┳━━━┳━╮╱╭╮
┃╭╮╭╮┃┃╱┃┃╭━━╯┃╭━╮┃┃┃╭┫╰╮╭╯┃╭━╮┃╭━╮┃╭━╮┃╭━╮┃╭━╮┃╭━━┫╭━╮┃┃╭━╮┃╭━╮┃┃╱╱┃┃╱╱┃╭━━┫╭━╮┃╭╮╭╮┣┫┣┫╭━╮┃┃╰╮┃┃
╰╯┃┃╰┫╰━╯┃╰━━╮┃╰━━┫╰╯╯╰╮╰╯╭┫╰━━┫┃╱╰┫╰━╯┃┃╱┃┃╰━╯┃╰━━┫╰━╯┃┃┃╱╰┫┃╱┃┃┃╱╱┃┃╱╱┃╰━━┫┃╱╰┻╯┃┃╰╯┃┃┃┃╱┃┃╭╮╰╯┃
╱╱┃┃╱┃╭━╮┃╭━━╯╰━━╮┃╭╮┃╱╰╮╭╯╰━━╮┃┃╱╭┫╭╮╭┫╰━╯┃╭━━┫╭━━┫╭╮╭╯┃┃╱╭┫┃╱┃┃┃╱╭┫┃╱╭┫╭━━┫┃╱╭╮╱┃┃╱╱┃┃┃┃╱┃┃┃╰╮┃┃
╱╱┃┃╱┃┃╱┃┃╰━━╮┃╰━╯┃┃┃╰╮╱┃┃╱┃╰━╯┃╰━╯┃┃┃╰┫╭━╮┃┃╱╱┃╰━━┫┃┃╰╮┃╰━╯┃╰━╯┃╰━╯┃╰━╯┃╰━━┫╰━╯┃╱┃┃╱╭┫┣┫╰━╯┃┃╱┃┃┃
╱╱╰╯╱╰╯╱╰┻━━━╯╰━━━┻╯╰━╯╱╰╯╱╰━━━┻━━━┻╯╰━┻╯╱╰┻╯╱╱╰━━━┻╯╰━╯╰━━━┻━━━┻━━━┻━━━┻━━━┻━━━╯╱╰╯╱╰━━┻━━━┻╯╱╰━╯

*/

contract TheSkyscraperCollection is ERC721r, Ownable {
   using Strings for uint256;
   /*
    * Private Variables
    */

   uint256 private constant MAX_SKYSCRAPER_SUPPLY = 5000;
   string private _tokenBaseURI;
   address private crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

   enum SalePhase {
		Locked,
		PreSale,
		PublicSale
	}

   /*
    * Public Variables
    */ 

   uint256 public mintPrice = 0.1385 ether;
   SalePhase public phase = SalePhase.Locked;
   bytes32 public merkleRoot;

   /*
    * Constructor
    */

   constructor() ERC721r("The Skyscraper Collection", "TSC", MAX_SKYSCRAPER_SUPPLY) {}

   /*
    * Modifiers
    */

   modifier isCorrectPayment(uint256 _quantity) {
      require(mintPrice * _quantity == msg.value, "Incorrect ETH value sent");
      _;
   }

   modifier isValidMerkleProof(address _to, bytes32[] calldata _proof) {
      if (!MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_to)))) {
         revert("Invalid whitelist proof");
      }
      _;
   }
   
   // === Owner Functions

   function setBaseURI(string memory URI) external onlyOwner {
      _tokenBaseURI = URI;
   }

   function adjustMintPrice(uint256 _newPrice) external onlyOwner {
		mintPrice = _newPrice;
	}

   function enterPhase(SalePhase _phase) external onlyOwner {
		phase = _phase;
	}

   function withdraw() external onlyOwner {
      Address.sendValue(payable(msg.sender), address(this).balance);
   }

   function setMerkleRoot(bytes32 _root) external onlyOwner {
      merkleRoot = _root;
   }

   function setCrossmintAddress(address _crossmintAddress) external onlyOwner {
      crossmintAddress = _crossmintAddress;
   }

   // Function will be used before sale goes live for minting of NFTs that will go to the team.
   // Team cannot mint super-rare or rares, only commons.
   function mintSpecific(uint _index) external onlyOwner {
      require(_index > 49, 'Index cannot be within rares or super rares');
      _mintAtIndex(msg.sender, _index);
   }

   // Function will only be used by team if we have unsold nfts.
   function reserve(uint256 _quantity) 
      external 
      onlyOwner 
   {
      _mintRandom(msg.sender, _quantity);
   }

   // === Mint Functions

   function mint(address _to, uint256 _quantity) 
      external 
      payable 
      isCorrectPayment(_quantity)
   {
      require(phase == SalePhase.PublicSale, 'Public sale is not active');
      _mintRandom(_to, _quantity);
   }

   function whitelistMint(address _to, uint256 _quantity, bytes32[] calldata _proof)
      external
      payable
      isValidMerkleProof(_to, _proof)
      isCorrectPayment(_quantity)
   {
      require(phase == SalePhase.PreSale, 'Whitelist sale is not active');
      _mintRandom(_to, _quantity);
   }

   function crossmint(address _to, uint256 _quantity) 
      public 
      payable 
      isCorrectPayment(_quantity)
   {
      require(msg.sender == crossmintAddress,
         "This function is for Crossmint only."
      );

      _mintRandom(_to, _quantity);
   }

   // === Overrides

   function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
   {
      require(
         _exists(tokenId),
         "ERC721Metadata: URI query for nonexistent token"
      );

      string memory currentBaseURI = _tokenBaseURI;
      return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
      : "";
   }
}