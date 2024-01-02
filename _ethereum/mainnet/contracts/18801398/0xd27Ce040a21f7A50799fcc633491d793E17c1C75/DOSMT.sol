// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DoSomething
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//      __        __                                          //
//    |/  |      /                   /    /    /              //
//    |   | ___ (___  ___  _ _  ___ (___ (___    ___  ___     //
//    |   )|   )    )|   )| | )|___)|    |   )| |   )|   )    //
//    |__/ |__/  __/ |__/ |  / |__  |__  |  / | |  / |__/     //
//                                                   __/      //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract DOSMT is ERC721Creator {
    constructor() ERC721Creator("DoSomething", "DOSMT") {}
}
