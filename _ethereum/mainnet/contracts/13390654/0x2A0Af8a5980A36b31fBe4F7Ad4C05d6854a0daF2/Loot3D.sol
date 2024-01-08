// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./NonTransferablebERC721URIStorage.sol";

contract Loot3D is NonTransferablebERC721URIStorage, Ownable {
    // Contracts that have been claimed
    mapping(address => bool) public minters;

    // Base URI for tokens
    string public baseURI;

    constructor(
        string memory _baseURI
    ) ERC721("Loot 3D", "LOOT3D") {
        baseURI = _baseURI; // NOTE - double underscore to not shadow _baseURI method
    }

    /**
     * @dev Add an address that is allowed to mint
     * @param minter that is allowed to mint
     * @param isMint bool minter status
     */
    function updateMinter(address minter, bool isMint) external onlyOwner {
        minters[minter] = isMint;
    }

    /**
     * @dev Claim
     * @param tokenId Token ID to claim
     */
    function claim(uint256 tokenId) external {
        address to = msg.sender;
        require(!minters[to], "This address has been claimed");
        if (!ERC721._exists(tokenId)) {
            _safeMint(to, tokenId); // "Mint" Loot 3D
            minters[to] = true;
        }
    }

    /**
     * @dev OwnerClaim
     * @param tokenId Token ID to claim
     */
    function ownerClaim(uint256 tokenId) external onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
        address to = owner();
        _safeMint(to, tokenId);
        minters[to] = true;
    }

    /**
     * @dev Mint
     * @param tokenId Token ID to mint
     * @param owner address to set ownership to
     */
    function mint(uint256 tokenId, address owner) external onlyOwner {
        if (!ERC721._exists(tokenId)) {
            _safeMint(owner, tokenId); // "Mint" Loot 3D
        }
    }

    /**
     * @dev URI for all tokens
     * @param tokenId Token to retrieve metadata URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }

    /**
     * @dev Set baseURI
     * @param _baseURI New baseUri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}
