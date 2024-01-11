// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721PB.sol";


contract PlutosCreations is ERC721PB
{
    constructor(address admin)
        ERC721PB("Pluto's Creations",
                 "PID",
                 "https://gateway.ipfs.io/ipns/k51qzi5uqu5dhrvqhejvgg814fnnu7uevmmay5ekgji4tef2fl0srjl2hfamvq/",
                 admin,
                 ~uint256(0)) {
        _setDefaultRoyalty(0xA6A452B914f53fE81f94873cDaF11E5D2E99cf86, 700);
    }
}
