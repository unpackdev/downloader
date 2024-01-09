
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gabriel Dean Roberts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//    Gabriel Dean Roberts is a multidisciplinary artist specializing in fine art photography and animated digital art. His background in film, television and fashion inform his style which often brings new light to chiaroscuro imagery.    //
//                                                                                                                                                                                                                                              //
//    Gabriel is a resident of New York City where he keeps his studio, and a VICE and VOGUE veteran with a Master of Interdisciplinary Arts from The University of Washington                                                                  //
//                                                                                                                                                                                                                                              //
//    Gabrieldeanroberts.com                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GDR is ERC721Creator {
    constructor() ERC721Creator("Gabriel Dean Roberts", "GDR") {}
}
