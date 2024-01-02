// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In Scarlet's Embrace
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    ┳    ┏┓     ┓   ╹   ┏┓   ┓                   //
//    ┃┏┓  ┗┓┏┏┓┏┓┃┏┓╋ ┏  ┣ ┏┳┓┣┓┏┓┏┓┏┏┓           //
//    ┻┛┗  ┗┛┗┗┻┛ ┗┗ ┗ ┛  ┗┛┛┗┗┗┛┛ ┗┻┗┗            //
//                                      by Imok    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract ISE is ERC721Creator {
    constructor() ERC721Creator("In Scarlet's Embrace", "ISE") {}
}
