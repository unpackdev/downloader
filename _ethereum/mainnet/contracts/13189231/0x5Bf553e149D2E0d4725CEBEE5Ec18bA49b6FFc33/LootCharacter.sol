// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NonTransferablebERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";


interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}


contract LootCharacter is NonTransferablebERC721URIStorage, Ownable {
    // There are 8000 Loot. More Loot starts at 8001
    uint256 private TOTAL_LOOT = 8000;

    //Loot & mLoot
    address private lootAddress;
    address private mLootAddress;

    // Contracts that are allowed to mint
    mapping(address => bool) public minters;

    // Base URI for tokens
    string public baseURI;

    constructor(address _lootAddress, address _mLootAddress, string memory _baseURI) ERC721("Loot Character", "LCHAR") {
        lootAddress = _lootAddress;
        mLootAddress = _mLootAddress;
        baseURI = _baseURI;  // NOTE - double underscore to not shadow _baseURI method
    }

    /**
     * @dev Add an address that is allowed to mint
     * @param minter that is allowed to mint
     * @param canMint bool minter status
     */
    function updateMinter(address minter, bool canMint) external onlyOwner {
		minters[minter] = canMint;
	}

    /**
     * @dev Mint
     * @param tokenId Token ID to mint
	 * @param owner address to set ownership to
     */
    function mint(uint256 tokenId, address owner) external {
		require(minters[msg.sender], "This address cannot mint");
		if(!ERC721._exists(tokenId)) {
            _safeMint(owner, tokenId);  // "Mint" Loot Character
        }
	}

    /**
     * @dev Return the token URI through the Loot Expansion interface
     * @param lootId The Loot Character URI
     */
    function lootExpansionTokenUri(uint256 lootId) public view returns (string memory) {
        return tokenURI(lootId);
    }

    /**
     * @dev URI for all tokens
	 * @param tokenId Token to retrieve metadata URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    /**
     * @dev ERC721 ownerOf method override. This is an associative NFT. It has the same owner as the Loot (or More Loot) with the same ID.
     * @param tokenId The ID of the Loot Character to look up ownership of.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if(tokenId <= TOTAL_LOOT) {
            return LootInterface(lootAddress).ownerOf(tokenId);
        } else {
            return LootInterface(mLootAddress).ownerOf(tokenId);
        }
    }

    /**
     * @dev Set baseURI
     * @param _baseURI New baseUri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}
