

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./AvatarNFT.sol";

contract LikoNFTFinal is AvatarNFT {

    constructor() AvatarNFT(0.22 ether, 8822, 2, "ipfs://Qmci7UqsFkmMbDvXjH7WXqPzEHyhx2CZ1ae7FfzDP4ZW4D/", "LIKOCOV", "LIKO") {}
}