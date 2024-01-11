// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "ERC721xyz.sol";
import "Ownable.sol";

contract CollectionMH is ERC721xyz, Ownable {
    string private baseURI;
    bool internal isLockedURI;

    constructor(string memory name_, string memory symbol_,
                uint256 tokensCount_, string memory baseURI_,
                address receiver_) ERC721xyz(name_, symbol_) {
        baseURI = baseURI_;
        // Instant airdrop
        _mint(receiver_, tokensCount_);
    }

    // return Base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Lock metadata forever
    function lockURI() external onlyOwner {
        isLockedURI = true;
    }

    // modify the base URI
    function changeBaseURI(string memory newBaseURI) onlyOwner public {
        require(!isLockedURI, "URI change has been locked");
        baseURI = newBaseURI;
    }
}
