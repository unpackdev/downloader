// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a day in the life
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    ╱╱╱╱╱╭╮╱╱╱╱╱╭╮╱╱╱╭╮╭╮╱╱╱╱╱╭┳━╮      //
//    ╭━╮╱╭╯┣━╮╭┳╮┣╋━┳╮┃╰┫╰┳━╮╭╮┣┫━╋━╮    //
//    ┃╋╰╮┃╋┃╋╰┫┃┃┃┃┃┃┃┃╭┫┃┃┻┫┃╰┫┃╭┫┻┫    //
//    ╰━━╯╰━┻━━╋╮┃╰┻┻━╯╰━┻┻┻━╯╰━┻┻╯╰━╯    //
//    ╱╱╱╱╱╱╱╱╱╰━╯                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract DITL is ERC721Creator {
    constructor() ERC721Creator("a day in the life", "DITL") {}
}
