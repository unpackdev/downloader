// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Twisted Nightmares
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract TWNM is ERC721Community {
    constructor() ERC721Community("Twisted Nightmares", "TWNM", 777, 15, START_FROM_ONE, "ipfs://bafybeifwvv3zxdpksvndezlfuxiyk64i5ovftrdbvi3xbtf5vbtt6np3py/",
                                  MintConfig(0.007 ether, 10, 10, 0, 0x14a86581f55456647218463Fbeda6a14b14ec8B6, false, false, false)) {}
}
