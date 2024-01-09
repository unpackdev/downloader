
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ramblings by Eva
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//     ____   __   _  _  ____  __    __  __ _   ___  ____     //
//    (  _ \ / _\ ( \/ )(  _ \(  )  (  )(  ( \ / __)/ ___)    //
//     )   //    \/ \/ \ ) _ (/ (_/\ )( /    /( (_ \\___ \    //
//    (__\_)\_/\_/\_)(_/(____/\____/(__)\_)__) \___/(____/    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract EG is ERC721Creator {
    constructor() ERC721Creator("Ramblings by Eva", "EG") {}
}
