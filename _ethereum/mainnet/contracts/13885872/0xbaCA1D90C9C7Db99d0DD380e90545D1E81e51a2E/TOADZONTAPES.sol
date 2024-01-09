/* SPDX-License-Identifier: MIT 

TOADZ ON TAPES
TAPES.XYZ & CRYPTOADZ

*/
pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./TOADZ.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title TOADZ ON TAPES
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

 contract TOADZONTAPES is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    Cryptoadz private immutable Toadz = Cryptoadz(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6);
	 string private baseURI;
    bool public HoldersSaleIsActive = false;
    bool public PublicSaleIsActive = false;
    // 0.01 ETH mint price for Cryptoadz holders
    uint256 public HoldersSalePrice = 10000000000000000;
    // 0.02 ETH mint Price for public sale
    uint256 public PublicSalePrice = 20000000000000000;
	 mapping(uint256 => bool) public TapesMinted;
    mapping(address => uint256) public MintedWallets;
		
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

     function MintTapeToadzHolders(uint256[] memory TOADZ_IDs) external payable nonReentrant {
        require(HoldersSaleIsActive, "Sale isn't active yet!");
        for (uint256 j=0; j<TOADZ_IDs.length;j++){
			  require(Toadz.ownerOf(TOADZ_IDs[j]) == msg.sender, "You don't own one of the Cryptoadz");
	        require(!TapesMinted[TOADZ_IDs[j]], "The Tape for that Toad has been claimed");
        }    
        uint costToMint = HoldersSalePrice * TOADZ_IDs.length;
        require(costToMint == msg.value, "Eth value incorrect.");
        for(uint256 i=0; i < TOADZ_IDs.length; i++ ) {
            uint256 mintIndex = TOADZ_IDs[i];
            _safeMint(msg.sender, mintIndex);
            TapesMinted[TOADZ_IDs[i]] = true;
        }
     }
		 
     function MintTapePublic(uint256[] memory TOADZ_IDs) external payable nonReentrant {
        require(PublicSaleIsActive, "Sale isn't active yet!");
        require(MintedWallets[msg.sender] + TOADZ_IDs.length <= 3, "Each wallet can only mint up to 3 Tapes.");
        for (uint256 j=0; j<TOADZ_IDs.length;j++){
            require(TOADZ_IDs[j] <= 6969 && TOADZ_IDs[j] > 0, "Tape doesnt exist."); 
            require(!TapesMinted[TOADZ_IDs[j]], "The Tape for a Toad entered has been claimed");
        }    
        uint costToMint = PublicSalePrice * TOADZ_IDs.length;
        require(costToMint == msg.value, "Eth value incorrect.");
        for(uint256 i=0; i < TOADZ_IDs.length; i++ ) {
            uint256 mintIndex = TOADZ_IDs[i];
            _safeMint(msg.sender, mintIndex);
            TapesMinted[TOADZ_IDs[i]] = true;
        }
        MintedWallets[msg.sender] = MintedWallets[msg.sender] + TOADZ_IDs.length;
     }

     function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
     }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require((tokenId <= 6969 && tokenId > 0) || (tokenId != 0 && tokenId < 56000001 && tokenId % 1000000 == 0), "Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	 }

     function whoOwnsTheMusic() external pure returns (string memory) {
        return "Copyright free. No one owns this music. It's for everyone. "
            "Take it and make it good.";
     }
}