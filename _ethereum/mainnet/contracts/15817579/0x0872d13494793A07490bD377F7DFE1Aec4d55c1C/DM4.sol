// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Ditto Man 4
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract DM4 is ERC721Community {
    constructor() ERC721Community("Ditto Man 4", "DM4", 20, 5, START_FROM_ONE, "ipfs://bafybeif6oaysw6causrwu2rzs5p6u2ge3lb6ya3tldiwzwqgiasqpa25cm/",
                                  MintConfig(0.2 ether, 3, 3, 0, 0xCE9aDc407014024908e866CC5b12fA5554FB583e, false, false, false)) {}
}
