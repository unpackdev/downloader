// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./CountersUpgradeable.sol";

import "./D4AERC721WithFilter.sol";

contract PDERC721WithFilter is D4AERC721WithFilter {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    function initialize(string memory name, string memory symbol, uint256 startTokenId) public override initializer {
        __D4AERC721_init(name, symbol);
        __DefaultOperatorFilterer_init();
        _tokenIds._value = startTokenId;
    }

    function mintItem(
        address player,
        string memory uri,
        uint256 tokenId
    )
        public
        override
        onlyRole(MINTER)
        returns (uint256)
    {
        if (tokenId == 0) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(player, newItemId);
            _setTokenURI(newItemId, uri);
            return newItemId;
        } else {
            _mint(player, tokenId);
            _setTokenURI(tokenId, uri);
            return tokenId;
        }
    }
}

// contract D4AERC721WithFilterFactory is ID4AERC721Factory {
//     using Clones for address;

//     D4AERC721 impl;

//     event NewD4AERC721WithFilter(address addr);

//     constructor() {
//         impl = new D4AERC721WithFilter();
//     }

//     function createD4AERC721(string memory _name, string memory _symbol) public returns (address) {
//         address t = address(impl).clone();
//         D4AERC721WithFilter(t).initialize(_name, _symbol);
//         D4AERC721WithFilter(t).changeAdmin(msg.sender);
//         D4AERC721WithFilter(t).transferOwnership(msg.sender);
//         emit NewD4AERC721WithFilter(t);
//         return t;
//     }
// }
