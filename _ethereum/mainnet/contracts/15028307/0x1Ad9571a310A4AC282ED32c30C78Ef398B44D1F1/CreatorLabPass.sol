// SPDX-License-Identifier: MIT
/**
   ______ ____   ______ ___   ______ ____   ____   __     ___     ____ 
  / ____// __ \ / ____//   | /_  __// __ \ / __ \ / /    /   |   / __ )
 / /    / /_/ // __/  / /| |  / /  / / / // /_/ // /    / /| |  / __  |
/ /___ / _, _// /___ / ___ | / /  / /_/ // _, _// /___ / ___ | / /_/ / 
\____//_/ |_|/_____//_/  |_|/_/   \____//_/ |_|/_____//_/  |_|/_____/  
                                                                                                                                                       
 */

pragma solidity ^0.8.4;

import "./Delegated.sol";
import "./ERC721A.sol";


contract CreatorLabPass is Delegated, ERC721A {
    uint256 public constant maxBatchSize = 5;

    // TokenURI
    string public uri = "";

    uint256 public price = 0 ether;

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
    function teamMint(uint256 quantity_) external onlyDelegates {
        uint256 maxBatchSize_ = maxBatchSize;
        require(
            quantity_ % maxBatchSize_ == 0,
            "Can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks_ = quantity_ / maxBatchSize_;
        for (uint256 i = 0; i < numChunks_; i++) {
            _safeMint(msg.sender, maxBatchSize_);
            _addOwnedToken(msg.sender, maxBatchSize_);
        }
    }

    function publicMint(uint256 quantity_) external payable callerIsUser {
        uint256 price_ = price;
        require(price_ != 0, "Public sale has not begun yet");
        require(
            quantity_ <= maxBatchSize,
            "Cannot mint more than maxBatchSize"
        );
        uint256 amount_ = price_ * quantity_;
        require(
            msg.value >= amount_,
            "Ether value sent is not correct"
        );
        if (msg.value > amount_) {
            payable(msg.sender).transfer(msg.value - amount_);
        }
        _safeMint(msg.sender, quantity_);
        _addOwnedToken(msg.sender, quantity_);
    }

    function setURI(string calldata uri_) external onlyDelegates {
        uri = uri_;
    }

    function setPrice(uint256 price_) external onlyDelegates {
        price = price_;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId_),
            "ERC721AMetadata: URI query for nonexistant token"
        );
        string memory currentBaseURI_ = uri;
        return
            bytes(currentBaseURI_).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI_,
                        _toString(tokenId_),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function burn(uint256 tokenId_) external onlyDelegates {
        address from_ = ownerOf(tokenId_);
        _burn(tokenId_, false);
        _removeOwnedToken(from_, tokenId_);
    }

    /**
     * @dev Withdraw all the money from smart contract to Owner's wallet
     */
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev This is to get all tokenIds of the owner
     */
    function getAllTokensByOwner(address owner_) public view returns (uint256[] memory) {
        uint256[] memory tokens_ = new uint256[](balanceOf(owner_));
        for (uint256 i = 0; i < balanceOf(owner_); i++) {
            tokens_[i] = _ownedTokens[owner_][i];
        }
        return tokens_;
    }

    function _addOwnedToken(address to_, uint256 count_) private {
        uint256 lastTokenIndex_ = balanceOf(to_) - count_;
        for (uint256 i = count_; i > 0; i--) {
            uint256 currentIndex_ = _nextTokenId();
            _ownedTokens[to_][lastTokenIndex_] = currentIndex_ - i;
            _ownedTokensIndex[currentIndex_-i] = lastTokenIndex_;
            lastTokenIndex_++;
        }
    }

    function _removeOwnedToken(address from_, uint256 tokenId_) private {
        uint256 lastTokenIndex_ =  balanceOf(from_);
        uint256 tokenIndex_ = _ownedTokensIndex[tokenId_];

        if (tokenIndex_ != lastTokenIndex_) {
            uint256 lastTokenId_ = _ownedTokens[from_][lastTokenIndex_];

            _ownedTokens[from_][tokenIndex_] = lastTokenId_; // Move the last token to the slot of the to-be-deleted token
            _ownedTokensIndex[lastTokenId_] = tokenIndex_; // Update the moved token's index
        }

        // Delete the contents at the last position of the array
        delete _ownedTokensIndex[tokenId_];
        delete _ownedTokens[from_][lastTokenIndex_];
    }

    function _transferOwnedToken(address from_, address to_, uint256 tokenId_) private {
        uint256 lastTokenIndex_ = balanceOf(to_) - 1;
        _removeOwnedToken(from_, tokenId_);
        _ownedTokens[to_][lastTokenIndex_] = tokenId_;
        _ownedTokensIndex[tokenId_] = lastTokenIndex_;
    }

    /**
    * @dev This is equivalent to transferFrom(from, to, tokenId) in ERC721A. See {IERC721-safeTransferFrom}
    */
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_) public override {
            super.transferFrom(from_, to_, tokenId_);
            _transferOwnedToken(from_, to_, tokenId_);
    }

}