
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./AvatarNFT.sol";

contract LikoNFTFinal is AvatarNFT {

    constructor() AvatarNFT(0 ether, 3500, 2, "ipfs://QmTpi886bHE4MLqva6hKE4RThsUfdKrKrC4RZbFVz5wrfG/", "LIKO", "LIKO") {}
}