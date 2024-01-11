
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MadMax
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//               __,__                //
//       .--.  .-"     "-.  .--.      //
//      / .. \/  .-. .-.  \/ .. \     //
//     | |  '|  /   Y   \  |'  | |    //
//     | \   \  \ 0 | 0 /  /   / |    //
//      \ '- ,\.-"`` ``"-./, -' /     //
//       `'-' /_   ^ ^   _\ '-'`      //
//           |  \._   _./  |          //
//           \   \ `~` /   /          //
//    madmax  '._ '-=-' _.'           //
//               '~---~'              //
//                                    //
//                                    //
////////////////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("MadMax", "MM") {}
}
