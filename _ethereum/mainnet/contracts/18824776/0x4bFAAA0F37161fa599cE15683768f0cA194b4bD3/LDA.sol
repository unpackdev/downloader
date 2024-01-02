// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Little Diamond Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//              _ .-') _     ('-.         //
//             ( (  OO) )   ( OO ).-.     //
//     ,--.     \     .'_   / . --. /     //
//     |  |.-') ,`'--..._)  | \-.  \      //
//     |  | OO )|  |  \  '.-'-'  |  |     //
//     |  |`-' ||  |   ' | \| |_.'  |     //
//    (|  '---.'|  |   / :  |  .-.  |     //
//     |      | |  '--'  /  |  | |  |     //
//     `------' `-------'   `--' `--'     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract LDA is ERC721Creator {
    constructor() ERC721Creator("Little Diamond Art", "LDA") {}
}
