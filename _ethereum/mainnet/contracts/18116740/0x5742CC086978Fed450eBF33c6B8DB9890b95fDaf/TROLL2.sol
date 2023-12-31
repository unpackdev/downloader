// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Bobby Troll

import "./ERC721Community.sol";

contract TROLL2 is ERC721Community {
    constructor() ERC721Community("Bobby Troll", "TROLL2", 1000, 1, START_FROM_ONE, "ipfs://bafybeie42ukvoipkablvpvwu2cotqxf3itx3rauvnr5gvllpsofndy677e/",
                                  MintConfig(1 ether, 10, 10, 0, 0x7d678e09B8F3668fe89434623D5c71EbfF8A6DF5, true, false, false)) {}
}
