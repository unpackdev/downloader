// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.17;

import "./IERC165.sol";
import "./IERC1155Receiver.sol";
import "./IERC721Metadata.sol";

abstract contract ERC165 is IERC165, IERC1155Receiver, IERC721Metadata {
    mapping(bytes4 => bool) private interfaces;
    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor () {
        /**
        *   I guess I will just register everything here, to keep it simple
        */
        registerInterface(type(IERC165).interfaceId);
        registerInterface(type(IERC721).interfaceId);
        registerInterface(type(IERC721Metadata).interfaceId);
        registerInterface(type(IERC1155Receiver).interfaceId);
        registerInterface(INTERFACE_ID_ERC2981);
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaces[interfaceId];
    }

    function registerInterface(bytes4 interfaceId) private {
        interfaces[interfaceId] = true;
    }
}


