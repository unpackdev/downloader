
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Floodles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//      __  _                    _  _                //
//     / _|| |  ___    ___    __| || |  ___  ___     //
//    | |_ | | / _ \  / _ \  / _` || | / _ \/ __|    //
//    |  _|| || (_) || (_) || (_| || ||  __/\__ \    //
//    |_|  |_| \___/  \___/  \__,_||_| \___||___/    //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract Floodles is ERC721Creator {
    constructor() ERC721Creator("Floodles", "Floodles") {}
}
