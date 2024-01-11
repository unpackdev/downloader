// SPDX-License-Identifier: MIT
// Created by CreatorLab.io

pragma solidity ^0.8.4;

import "./Delegated.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract CreatorLabPass is Delegated, ERC721A, ReentrancyGuard {
    uint256 public constant maxBatchSize = 5;

    // TokenURI
    string public uri = "";

    uint256 public price = 0.5 ether;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex; 

    // Name, Symbol, Max batch size, collection size.
    constructor() ERC721A("CreatorLab Pass", "CLP") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // For marketing etc.
    function teamMint(uint256 quantity) external onlyDelegates {
        require(
            quantity % maxBatchSize == 0,
            "Can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
            _addOwnedToken(msg.sender, maxBatchSize);
        }
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(price != 0, "Public sale has not begun yet");
        require(
            msg.value >= price * quantity,
            "Ether value sent is not correct"
        );
        require(
            quantity <= maxBatchSize,
            "Cannot mint more than maxBatchSize"
        );
        payable(msg.sender).transfer(msg.value);
        _safeMint(msg.sender, quantity);
        _addOwnedToken(msg.sender, quantity);
    }

    function setURI(string calldata uri_) external onlyDelegates {
        uri = uri_;
    }

    function setPrice(uint256 price_) external onlyDelegates {
        price = price_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistant token"
        );
        return uri;
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function burn(uint256 tokenId) external onlyDelegates {
        address from = ownerOf(tokenId);
        _burn(tokenId, false);
        _removeOwnedToken(from, tokenId);
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev This is to get all tokenIds of the owner
     */
    function getAllTokensByOwner(address owner) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(owner));
        for (uint256 i = 0; i < balanceOf(owner); i++) {
            tokens[i] = _ownedTokens[owner][i];
        }
        return tokens;
    }

    function _addOwnedToken(address to, uint256 _count) private {
        uint256 lastTokenIndex = balanceOf(to) - _count;
        for (uint256 i = _count; i > 0; i--) {
            _ownedTokens[to][lastTokenIndex] = _currentIndex - i;
            _ownedTokensIndex[_currentIndex-i] = lastTokenIndex;
            lastTokenIndex++;
        }
    }

    function _removeOwnedToken(address from, uint256 tokenId) private {
        uint256 lastTokenIndex =  balanceOf(from);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-be-deleted token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // Delete the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _transferOwnedToken(address from, address to, uint256 tokenId) private {
        uint256 lastTokenIndex = balanceOf(to) - 1;
        _removeOwnedToken(from, tokenId);
        _ownedTokens[to][lastTokenIndex] = tokenId;
        _ownedTokensIndex[tokenId] = lastTokenIndex;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId) public override {
            super.safeTransferFrom(from, to, tokenId);
            _transferOwnedToken(from, to, tokenId);
    }
}