// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721A.sol";

contract Placeholder is Ownable, ERC721A {
    using Counters for Counters.Counter;

    string public baseURI;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721A("Placeholder", "P") {
        _safeMint(_msgSender(), 1);
    }

    function mint(address account, uint256 quantity) external onlyOwner {
        _safeMint(account, quantity);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
