// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";


contract LootCharacterItems is ERC721URIStorage, Ownable {
    // Base URI for tokens 
    string public baseURI;

    // Addresses that are allowed to mint
	mapping(address => bool) public minters;

    modifier onlyMinters(address tryingToMint) {
        require(minters[tryingToMint]);
        _;
    }

    constructor(string memory _baseURI) ERC721("Loot Character Items", "LCHARITEMS") {
        baseURI = _baseURI;
    }

    /**
     * @dev Mint
     * @param tokenId Token ID to mint
     * @param owner address to set ownership to
     */
    function mint(uint256 tokenId, address owner) external onlyMinters(msg.sender) {
        _safeMint(owner, tokenId);
    }

    /**
     * @dev URI for all tokens
     * @param tokenId Token to retrieve metadata URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    /**
     * @dev Set baseURI
     * @param _baseURI New baseUri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Add an address that is allowed to mint
     * @param minter that is allowed to mint
     * @param canMint bool minter status
     */
    function updateMinter(address minter, bool canMint) external onlyOwner {
        minters[minter] = canMint;
    }
}
