// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Be Ordinary (editions)
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ┳┓  ┏┓   ┓•        ┏┓ ┓• •         //
//    ┣┫┏┓┃┃┏┓┏┫┓┏┓┏┓┏┓┓┏┣ ┏┫┓╋┓┏┓┏┓┏    //
//    ┻┛┗ ┗┛┛ ┗┻┗┛┗┗┻┛ ┗┫┗┛┗┻┗┗┗┗┛┛┗┛    //
//                      ┛                //
//                                       //
//                                       //
///////////////////////////////////////////


contract BOE is ERC1155Creator {
    constructor() ERC1155Creator("Be Ordinary (editions)", "BOE") {}
}
