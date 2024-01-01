// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feel of Emotion
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMHpppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppMMMMMMMMM    //
//    MMMMMMMMMHpppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppMMMMMMMMM    //
//    MMMMMMMMMHpppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppWUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUWpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======================================================================================dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======================================================================================dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======================================================================================dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_`````````````````````````````````````````````````````````````` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_`````````````````````````````````````````````````````````````` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                                      ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_````                                      Feel of Emotion ```` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_`````````````````````````````````````````````````````````````` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~_`````````````````````````````````````````````````````````````` ~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~~_______________________________________________________________~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+=====dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======================================================================================dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======================================================================================dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppR======================================================================================dpppppppMMMMMMMMM    //
//    MMMMMMMMMHppppppWeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedpppppppMMMMMMMMM    //
//    MMMMMMMMMHpppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppMMMMMMMMM    //
//    MMMMMMMMMHpppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppMMMMMMMMM    //
//    MMMMMMMMMHpppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppMMMMMMMMM    //
//    MMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM_danny    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FOE is ERC721Creator {
    constructor() ERC721Creator("Feel of Emotion", "FOE") {}
}
