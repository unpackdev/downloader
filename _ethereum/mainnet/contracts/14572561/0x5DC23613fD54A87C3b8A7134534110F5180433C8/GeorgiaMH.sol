// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "ERC721xyz.sol";
import "Ownable.sol";

contract GeorgiaMH is ERC721xyz, Ownable {

    string private baseURI;
    bool internal isLockedURI;

    constructor(string memory name_, string memory symbol_,
                uint256 tokens_count, string memory URI_base,
                address receiver) payable ERC721xyz(name_, symbol_) {
        baseURI = URI_base;
        // Instant airdrop
        _mint(receiver, tokens_count);
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
    function changeBaseURI(string memory new_base_URI) onlyOwner public {
        require(!isLockedURI, "URI change has been locked");
        baseURI = new_base_URI;
    }
}
