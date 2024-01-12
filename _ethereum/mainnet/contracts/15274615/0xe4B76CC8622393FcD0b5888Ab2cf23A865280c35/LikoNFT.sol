
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./AvatarNFT.sol";

contract LikoNFTFinal is AvatarNFT {

    constructor() AvatarNFT(0.1 ether, 800, 800, "ipfs://QmVGSVvoCyqMonDeyNsNHB7RUJ1j2mziVqxqqTr72oNRVu/", "LIKOFASHION", "LIKOFASHION") {}
}