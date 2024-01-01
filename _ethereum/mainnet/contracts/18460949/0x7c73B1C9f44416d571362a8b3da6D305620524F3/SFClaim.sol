// contracts/SFClaim.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./ISFToken.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract SFClaim is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // addresses
    address public sfAddress = 0x019D4Fa0dB9CF1512cC42E89D5515B9C17Ec5801;

    // integers
    string private _tokenBaseURI;

    // mappings
    mapping(uint256 => bool) public tokenToClaimed;

    constructor(string memory tokenBaseUri, string memory tokenName, string memory tokenSymbol) ERC721A(tokenName, tokenSymbol) {
        _tokenBaseURI = tokenBaseUri;

        // mint one token to owner
        _safeMint(_msgSender(), 1);
    }

    function setBaseUri(string memory tokenBaseUri) external onlyOwner {
        _tokenBaseURI = tokenBaseUri;
    }

    /*
    MINTING FUNCTIONS
    */
    /**
     * @dev Function to claim for a single tokenId
     */
    function claim(uint256 tokenId) external nonReentrant {
        require(_msgSender() == ISFToken(sfAddress).ownerOf(tokenId), "Not owner of token");
        require(!tokenToClaimed[tokenId], "Token already claimed");

        tokenToClaimed[tokenId] = true;
        _safeMint(_msgSender(), 1);
    }

    /**
     * @dev Function to claim multiple tokens
     */
    function claimMultiple(uint256[] calldata tokenIds) external nonReentrant {
        for(uint i; i < tokenIds.length;){
            require(_msgSender() == ISFToken(sfAddress).ownerOf(tokenIds[i]), "Not owner of token");
            require(!tokenToClaimed[tokenIds[i]], "Token already claimed");

            tokenToClaimed[tokenIds[i]] = true;
            unchecked { i++; }
        }
        _safeMint(_msgSender(), tokenIds.length);
    }

    // Read functions
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenBaseURI;
    }

    /**
     * @dev Address can claim a token
     */
    function canClaim(address tokenOwner, uint256 tokenId) public view returns (bool) {
        if(tokenOwner != ISFToken(sfAddress).ownerOf(tokenId)) {
            return false;
        }
        if(tokenToClaimed[tokenId]) {
            return false;
        }
        return true;
    }

    /**
     * @dev Withdraw ETH to owner
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}