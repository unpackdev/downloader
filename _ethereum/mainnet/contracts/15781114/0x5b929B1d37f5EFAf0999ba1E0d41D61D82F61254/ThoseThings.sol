// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Those Things
// contract by: buildship.xyz

import "./ERC721Community.sol";

////////////////////////
//                    //
//                    //
//    Those Things    //
//                    //
//                    //
////////////////////////

contract ThoseThings is ERC721Community {
    constructor() ERC721Community("Those Things", "THTHI", 777, 20, START_FROM_ONE, "ipfs://bafybeidek5x24gzvhwkh7tlgl3kkdyre3xwhxxzyassb5tsyxvapwkk6de/",
                                  MintConfig(0.02 ether, 10, 50, 0, 0xA8011A5D9EC002c229Ee036397cE37188Bb41d33, false, false, false)) {}
}
