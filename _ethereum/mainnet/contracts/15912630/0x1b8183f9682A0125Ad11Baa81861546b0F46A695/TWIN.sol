
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Twinstar Industries
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//              .'\   /`.                //
//             .'.-.`-'.-.`.             //
//        ..._:   .-. .-.   :_...        //
//      .'    '-.(o ) (o ).-'    `.      //
//     :  _    _ _`~(_)~`_ _    _  :     //
//    :  /:   ' .-=_   _=-. `   ;\  :    //
//    :   :|-.._  '     `  _..-|:   :    //
//     :   `:| |`:-:-.-:-:'| |:'   :     //
//      `.   `.| | | | | | |.'   .'      //
//        `.   `-:_| | |_:-'   .'        //
//     jgs  `-._   ````    _.-'          //
//              ``-------''              //
//                                       //
//                                       //
///////////////////////////////////////////


contract TWIN is ERC721Creator {
    constructor() ERC721Creator("Twinstar Industries", "TWIN") {}
}
