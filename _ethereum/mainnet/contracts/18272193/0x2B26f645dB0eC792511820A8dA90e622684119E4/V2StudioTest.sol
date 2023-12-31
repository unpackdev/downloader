// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// name: V2StudioTest
// contract by: artgene.xyz

import "./Artgene721.sol";

contract V2StudioTest is Artgene721 {
    constructor() Artgene721("V2StudioTest", "V2StudioTest", 1000, 1, START_FROM_ONE, "https://metadata.artgene.xyz/api/g/v2studio-test/",
                              MintConfig(0.01 ether, 1, 1, 0, 0x653d8554B690d54EA447aD82C933A6851CC35BF2, false, 0, 0)) {}
}
