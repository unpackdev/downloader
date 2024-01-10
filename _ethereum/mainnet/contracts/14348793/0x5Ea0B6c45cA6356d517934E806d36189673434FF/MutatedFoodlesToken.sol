// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IFoodlesSerumToken.sol";

contract MutatedFoodlesToken is ERC721, Ownable {
    using Strings for uint256;

    address public serumAddress;
    address public foodlesAddress;

    string public baseURI;
    string public placeholderURI;

    bool public canMutate;
    uint256 public totalSupply = 0;

    constructor() ERC721("MutatedFoodlesClub", "MFC") {}

    //
    // Admin functions
    //

    function setCanMutate(bool canMutate_) external onlyOwner {
        canMutate = canMutate_;
    }

    function setSerumAddress(address serumAddress_) external onlyOwner {
        serumAddress = serumAddress_;
    }

    function setFoodlesAddress(address foodlesAddress_) external onlyOwner {
        foodlesAddress = foodlesAddress_;
    }

    //
    // Mint by receiving serums
    //

    function mutateFoodles(uint256[] memory tokenIds) external {
        require(canMutate, "MutatedFoodlesToken: Mutations not active");

        IFoodlesSerumToken(serumAddress).burnSerum(msg.sender, tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                IERC721(foodlesAddress).ownerOf(tokenId) == msg.sender,
                "MutatedFoodlesToken: You must own this Foodle"
            );
            _safeMint(msg.sender, tokenId);
            totalSupply++;
        }
    }

    //
    // Metadata
    //

    /**
     * Sets base URI
     * @dev Only use this method after sell out as it will leak unminted token data.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Sets placeholder URI
     */
    function setPlaceholderURI(string memory _newPlaceHolderURI) external onlyOwner {
        placeholderURI = _newPlaceHolderURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, tokenId.toString(), ".json")) : placeholderURI;
    }

}
