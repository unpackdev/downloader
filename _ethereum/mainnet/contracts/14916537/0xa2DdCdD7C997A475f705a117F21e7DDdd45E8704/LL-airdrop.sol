// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract summersmash is ERC721A, Ownable {
    using Strings for uint256;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {}

    string public baseURI;

    function airdrop(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _safeMint(addrs[i], 1);
        }
    }

    function airdropMultiple(uint256 quantity, address to) external onlyOwner {
        _safeMint(to, quantity);
    }

    function updateBaseUri(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}

