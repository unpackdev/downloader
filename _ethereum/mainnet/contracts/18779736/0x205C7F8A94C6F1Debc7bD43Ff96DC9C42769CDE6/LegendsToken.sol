// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";

/**
 * @title LegendsToken
 * @dev Extends ERC721 Non-Fungible Token Standard with Ownable and Royalty features.
 * Supports efficient batch minting and user burning of tokens.
 */
contract LegendsToken is ERC721,  ERC721Royalty, ERC721Enumerable, Ownable {
    uint256 public maxSupply;
    string private _baseTokenURI;

    event BatchMint(address indexed to, uint256 quantity);
    event TokenBurned(uint256 indexed tokenId);
    event RoyaltyInfoSet(address indexed recipient, uint96 feeBasisPoints);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    error MaxSupplyExceeded(string message);
    error QuantityError(string message);
    error NotAuthorizedToBurn(string message);

    /**
     * @dev Sets up the ERC721 with name, symbol, and maximum supply. 
     * Also sets Royalty Recipient and Base URI
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        string memory baseTokenURI,
        address royaltyRecipient
    ) ERC721(name, symbol) {
        maxSupply = _maxSupply;
        _baseTokenURI = baseTokenURI;
        _setDefaultRoyalty(royaltyRecipient, 500); // 5%
    }

    /**
     * @dev Allows minting any quantity of tokens to a specified address.
     * Emits a BatchMint event upon successful minting.
     *
     * Requirements:
     * - the caller must be owner
     * - the total supply plus the quantity to mint must not exceed `maxSupply`.
     *
     * @param to Address to which the tokens will be minted.
     * @param quantity Number of tokens to mint.
     */
    function batchMint(address to, uint256 quantity) external onlyOwner {
        if (quantity == 0) {revert QuantityError("Invalid qty");}
        if (totalSupply() + quantity > maxSupply) {revert MaxSupplyExceeded("Max supply exceeded");}

        for (uint256 i = 0; i < quantity; i++) {
            // Start token IDs from 1
            uint256 tokenId = totalSupply() + 1; 
            _safeMint(to, tokenId);
        }
        emit BatchMint(to, quantity);
    }

    /**
     * @dev Sets royalty information for all tokens.
     * Emits a RoyaltyInfoSet event upon successful setup.
     *
     * @param recipient Address to receive the royalties.
     * @param feeBasisPoints Fee basis points for the royalties.
     */
    function setRoyaltyInfo(address recipient, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(recipient, feeBasisPoints);
        emit RoyaltyInfoSet(recipient, feeBasisPoints);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(
        ERC721, 
        ERC721Enumerable, 
        ERC721Royalty) 
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721Enumerable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    /**
     * @dev Sets the base URI for computing {tokenURI}. This base URI is 
     * prefixed to the token-specific URI segment to form the full token URI.
     * 
     * Can only be called by the owner.
     *
     * Emits BatchMetadataUpdate for all tokens.
     * 
     * @param baseTokenURI The base URI to be set for the token metadata.
     */
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
        emit BatchMetadataUpdate(1, maxSupply);
    }

    /**
     * @dev Internal function to return the base part of the URI for all tokens.
     * This base URI is used in {tokenURI} to prepend to the token-specific URI segment.
     *
     * Overridden to return the private _baseTokenURI set by {setBaseURI}.
     *
     * @return The base URI set for the token metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Helper function that emits an event to update metadata
     *
     * @param _fromTokenId initial token id to be updated
     * @param _toTokenId last token id to be updated
     */
    function updateMetadata(
        uint256 _fromTokenId,
        uint256 _toTokenId
    ) external onlyOwner {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

    /**
     * @dev Internal function to burn a token.
     * Inherits the burn functionality from ERC721 and ERC721Royalty.
     * The ownership check is performed in the base contracts.
     * Emits a TokenBurned event upon successful burning.
     *
     * @param tokenId Id of the token to burn.
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        if (ownerOf(tokenId) != msg.sender) revert NotAuthorizedToBurn("Caller is not authorized to burn");
        super._burn(tokenId);
        emit TokenBurned(tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}

