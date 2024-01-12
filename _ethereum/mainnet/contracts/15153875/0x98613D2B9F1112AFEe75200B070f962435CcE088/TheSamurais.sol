// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./BaseERC721.sol";

contract TheSamurais is BaseERC721 {
    constructor()
        BaseERC721("The Samurais", "SAMURAI", 3333)
    {}
}
