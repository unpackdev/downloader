// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Alpha9-44
// contract by: buildship.xyz

import "./ERC721Community.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//         \      |        _ \    |   |      \       _ \      //
//        _ \     |       |   |   |   |     _ \     (   |     //
//       ___ \    |       ___/    ___ |    ___ \   \__  |     //
//     _/    _\  _____|  _|      _|  _|  _/    _\    __/      //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////

contract A944 is ERC721Community {
    constructor() ERC721Community("Alpha9-44", "A944", 1888, 112, START_FROM_ONE, "ipfs://bafybeifb4fg6zncejwjez3c2rka47epiyozcii6wl5rleiclti3autbnkq/",
                                  MintConfig(0.007 ether, 2, 2, 0, 0x31827724473B97a2Ef86dC67DFFF5a599EBFEde8, false, false, false)) {}
}
