
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manho
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                            //
//    The ASCII art is a signature detail of the Manifold Creator contract. ASCII art is used to visually identify your contract, and plus it just looks really cool. Take the time to pick some ASCII art that is meaningful and represents your work, identity, and creativity.                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                            //
//    Ideally, ASCII art used here should be less than 120 characters in width. Something like 150 characters is acceptable, but the more columns you add, the more you risk text wrapping when viewing your contract on certain displays. There is no limit to ASCII art height. Take note that a boarder and padding will be automatically generated when compiling your smart contract.    //
//                                                                                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MH is ERC721Creator {
    constructor() ERC721Creator("Manho", "MH") {}
}
