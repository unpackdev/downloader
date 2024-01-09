/* SPDX-License-Identifier: MIT 

ROCKS ON TAPES
TAPES.XYZ & ETHER ROCK

*/
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ROCKS.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title ROCKS ON TAPES
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

 contract ROCKSONTAPES is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    Etherrock private immutable Rock = Etherrock(0x41f28833Be34e6EDe3c58D1f597bef429861c4E2);
	 string private baseURI;
    bool public HoldersSaleIsActive = false;
    bool public PublicSaleIsActive = false;
    // 0.01 ETH mint price for Etherrock holders
    uint256 public HoldersSalePrice = 10000000000000000;
    // 0.02 ETH mint Price for public sale
    uint256 public PublicSalePrice = 20000000000000000;
		
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol){}

     function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
     }

     function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
     }

     function flipHoldersSaleState() external onlyOwner {
        HoldersSaleIsActive = !HoldersSaleIsActive;
     }
    
     function flipPublicSaleState() external onlyOwner {
        PublicSaleIsActive = !PublicSaleIsActive;
     }

     // for emergencies only
     function setHoldersSalePrice(uint256 newPrice) external onlyOwner {
         HoldersSalePrice = newPrice;
     }

     // for emergencies only
     function setPublicSalePrice(uint256 newPrice) external onlyOwner {
         PublicSalePrice = newPrice;
     }

     // for admin to send out tapes to rock owners with cold wallets
     function AdminMintTape(address to, uint256 tokenId) external onlyOwner {
         require((tokenId <= 100), "Nonexistent token");
         _safeMint(to, tokenId);
     }

     function MintTapeRockHolders(uint256[] memory ROCK_IDs) external payable nonReentrant {
        require(HoldersSaleIsActive, "Sale isn't active yet");
        for (uint256 j=0; j<ROCK_IDs.length;j++){
			  require(Rock.ownerOf(ROCK_IDs[j]) == msg.sender, "You don't own the Rock entered");
	        require(!_exists(ROCK_IDs[j]), "The Tape for that Rock has been claimed");
        }    
        uint costToMint = HoldersSalePrice * ROCK_IDs.length;
        require(costToMint == msg.value, "Eth value incorrect");
        for(uint256 i=0; i < ROCK_IDs.length; i++ ) {
            _safeMint(msg.sender, ROCK_IDs[i]);            
        }
     }
		 
     function MintTapePublic(uint256 ROCK_ID) external payable nonReentrant {
        require(PublicSaleIsActive, "Sale isn't active yet");
        require(balanceOf(msg.sender) + 1 <= 1, "Each wallet can only mint 1 Tape");
        require(ROCK_ID <= 99, "Tape doesnt exist"); 
        require(!_exists(ROCK_ID), "That Tape has already been claimed");
        require(PublicSalePrice == msg.value, "Eth value incorrect");
        _safeMint(msg.sender, ROCK_ID);
     }

     function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
     }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require((tokenId <= 100), "Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	 }

     function whoOwnsTheMusic() external pure returns (string memory) {
        return "Copyright free. No one owns this music. It's for everyone. "
            "Take it and make it good.";
     }
}