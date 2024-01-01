// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: El Día de Muertos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//      ___   __   __     __   _  _  ____  ____   __      //
//     / __) / _\ (  )   / _\ / )( \(  __)(  _ \ / _\     //
//    ( (__ /    \/ (_/\/    \\ \/ / ) _)  )   //    \    //
//     \___)\_/\_/\____/\_/\_/ \__/ (____)(__\_)\_/\_/    //
//    Creator seansalexa                                  //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract EDDM is ERC721Creator {
    constructor() ERC721Creator(unicode"El Día de Muertos", "EDDM") {}
}
