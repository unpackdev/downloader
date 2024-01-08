// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NonTransferablebERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";


contract LootCharacterNote is NonTransferablebERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Base URI for these tokens
    string public baseURI;

    // Map address to their token. An address can only own 1 token.
    mapping(address => uint256) public ownerTokenId;

    // Contracts that are allowed to mint
    mapping(address => bool) public minters;

    constructor(string memory _baseURI) ERC721("Loot Character Note", "LCHARNOTE") {
        baseURI = _baseURI;
    }

    /**
     * @dev Mint
     * @param owner address to set ownership to
     */
    function mint(address owner) external {
        require(minters[msg.sender] || owner == msg.sender, "This address cannot mint");
        // NOTE - we don't require this so external callers don't blow up if a note already exists
        if(ownerTokenId[owner] == 0) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(owner, newItemId);
            ownerTokenId[owner] = newItemId;
        }
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
     * @dev Set baseUri
     * @param _baseUri New baseUri
     */
    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    /**
     * @dev URI for all tokens
     * @param tokenId Token to retrieve metadata URI
     * @return token URI for given tokenId
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }
}
