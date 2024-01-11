
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Badgers Dream Contract 22
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    I have the most rare vision. I had a dream,                                        //
//    Past the wit of artist to explain what dream it was…                               //
//    The eye of collector Gary not heard, the ear of collector Trevor had not seen,     //
//    Franks hand is unable to taste,                                                    //
//    his lizard tongue to conceive, nor Terry’s heart to report,                        //
//    what my dream was.                                                                 //
//                                                                                       //
//    If we artists have offended.                                                       //
//    Think but this, and all is mended.                                                 //
//    That you have but slumbered here                                                   //
//    While these NFTs did appear.                                                       //
//                                                                                       //
//    I dream and create, the two are one.                                               //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract BDC22 is ERC721Creator {
    constructor() ERC721Creator("Badgers Dream Contract 22", "BDC22") {}
}
