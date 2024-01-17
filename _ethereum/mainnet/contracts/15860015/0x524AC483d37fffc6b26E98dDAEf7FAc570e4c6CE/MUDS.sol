// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Mudkings
// contract by: buildship.xyz

import "./ERC721Community.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    ##   ##  ##  ###  ### ##    ## ##       //
//     ## ##   ##   ##   ##  ##  ##   ##      //
//    # ### #  ##   ##   ##  ##  ####         //
//    ## # ##  ##   ##   ##  ##   #####       //
//    ##   ##  ##   ##   ##  ##      ###      //
//    ##   ##  ##   ##   ##  ##  ##   ##      //
//    ##   ##   ## ##   ### ##    ## ##       //
//                                           //
//                                            //
//                                            //
////////////////////////////////////////////////

contract MUDS is ERC721Community {
    constructor() ERC721Community("Mudkings", "MUDS", 999, 20, START_FROM_ONE, "ipfs://bafybeih523r43b4jvf4gagx5ysrmysshzhb25dwde5ssz3apeehskptkce/",
                                  MintConfig(0.005 ether, 10, 10, 0, 0x3175fF080df947626db9DB81D6D873839ADAE008, false, false, false)) {}
}
