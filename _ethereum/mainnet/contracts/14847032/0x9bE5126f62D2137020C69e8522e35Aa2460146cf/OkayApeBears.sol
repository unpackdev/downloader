// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721MACH1.sol";

contract OkayApeBears is ERC721MACH1 {
    constructor()
        ERC721MACH1("OkayApeBears", "OABEARS", 500, 5000, 55, 0.02 ether, 20)
    {}
}
