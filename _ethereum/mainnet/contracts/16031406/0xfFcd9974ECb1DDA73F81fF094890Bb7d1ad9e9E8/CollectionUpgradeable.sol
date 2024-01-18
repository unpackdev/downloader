// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Counters.sol";
import "./ERC1155URIStorageUpgradeable.sol";

contract CollectionUpgradeable is ERC1155URIStorageUpgradeable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    function initialize(string memory uri_) initializer public {
        _setBaseURI(uri_);
    }

    function mintToken(
        uint256 amount,
        string memory tokenURI,
        bytes memory data
    ) external {
        tokenIds.increment();
        uint256 tokenId = tokenIds.current();

        _mint(msg.sender, tokenId, amount, data);
        _setURI(tokenId, tokenURI);
    }
}
