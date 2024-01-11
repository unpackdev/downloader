// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./Package_ERC173.sol";
import "./Package_ERC721Metadata.sol";

/**
 * @dev Supports interface bundle
 */
contract Bundle is Package_ERC721Metadata, Package_ERC173, ERC165 {
    constructor() Package_ERC721Metadata("The Happy Chemical Club", "THC", "bafybeif42ii3tgqjjou6ozzs6zc6kdj6ihybijvvnzznpzda7i5aulhjgy/prereveal.json") Package_ERC173(msg.sender) {}

    function supportsInterface(bytes4 interfaceId) public pure override(ERC165) returns (bool) {
        return
            interfaceId == type(ERC165).interfaceId ||
            interfaceId == type(ERC173).interfaceId ||
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC721Metadata).interfaceId ||
            interfaceId == type(ERC721Receiver).interfaceId;
    }
}
