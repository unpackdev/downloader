// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AlizéJirehLE
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//      )¯¯,¯\ °         |¯¯¯|°|¯¯¯|__' |\¯¯¯(\_/         //
//     /__/'\__\ (¯¯(_/     /| |_____'| \/     (/¯¯\°     //
//    |__ |/\|__|'\|¯¯¯¯¯¯|/  |_____'| |¯¯¯¯¯¯¯|          //
//    '               ¯¯¯¯¯¯'   ‘            ¯¯¯¯¯¯¯'     //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract AJLE is ERC1155Creator {
    constructor() ERC1155Creator(unicode"AlizéJirehLE", "AJLE") {}
}
