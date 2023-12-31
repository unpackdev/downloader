// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Troll 4

import "./ERC721Community.sol";

contract TROLL4 is ERC721Community {
    constructor() ERC721Community("Troll 4", "TROLL4", 10000, 1, START_FROM_ONE, "ipfs://bafybeidswovum6rlrn7ospe7hymzybj2yg55th3rcapmrlk2nphmr3ltwm/",
                                  MintConfig(0.01 ether, 20, 20, 0, 0x7d678e09B8F3668fe89434623D5c71EbfF8A6DF5, true, false, false)) {}
}
