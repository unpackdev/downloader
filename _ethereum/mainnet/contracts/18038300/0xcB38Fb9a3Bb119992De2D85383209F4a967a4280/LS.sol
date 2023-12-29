// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Legacy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//    This series of works is based on my reflections on the relationship between primitive art, namely rock art and modern art.                                                                                                             //
//    In my works I often refer to the theme of nature and the world around me, trying to capture my feelings and emotions, to convey the atmosphere of a place or phenomenon.                                                               //
//    Thousands of years ago, the man sought to show what surrounds him.                                                                                                                                                                     //
//    This connection between the modern artist and the man who lived 65 thousand years ago and tried to depict the world around him for posterity is amazing.                                                                               //
//    That is why I decided to dedicate this series to rock painting and of course to nature, which for centuries inspires creators to depict it on their canvases.                                                                          //
//    In these works you can see both an amazing variety of flora and fauna.                                                                                                                                                                 //
//    These abstract generative works on the theme of nature and its relationship to rock art are not only beautiful works of art, but also a way to reflect a cultural heritage that is important to the development of art in general.     //
//    They allow the viewer to immerse themselves in the world of living nature to experience its beauty and majesty as it was seen thousands of years ago.                                                                                  //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LS is ERC721Creator {
    constructor() ERC721Creator("Legacy", "LS") {}
}
