// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Consts {
    bytes1 constant FLAG_ERC721 = bytes1(uint8(0));
    bytes1 constant FLAG_ERC1155 = bytes1(uint8(1));

    bytes32 constant BEACON_PROXY_CODE_HASH = 0x3f74a55adef768b97d182c8a1b516d04f0c3e0c4c1b1b534037d7c6104a39a2b;
    address constant CREATE_GAME_RECIPIENT = address(0xAAAA00000000000000000000000000000000aaaa);
}
