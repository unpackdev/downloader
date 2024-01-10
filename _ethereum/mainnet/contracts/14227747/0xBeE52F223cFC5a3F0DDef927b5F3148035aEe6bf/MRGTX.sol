
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mr. Gattax
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    `7MMM.     ,MMF'               .g8"""bgd          mm     mm                           //
//      MMMb    dPMM               .dP'     `M          MM     MM                           //
//      M YM   ,M MM  `7Mb,od8     dM'       `  ,6"Yb.mmMMmm mmMMmm  ,6"Yb.  `7M'   `MF'    //
//      M  Mb  M' MM    MM' "'     MM          8)   MM  MM     MM   8)   MM    `VA ,V'      //
//      M  YM.P'  MM    MM         MM.    `7MMF',pm9MM  MM     MM    ,pm9MM      XMX        //
//      M  `YM'   MM    MM  ,,     `Mb.     MM 8M   MM  MM     MM   8M   MM    ,V' VA.      //
//    .JML. `'  .JMML..JMML.db       `"bmmmdPY `Moo9^Yo.`Mbmo  `Mbmo`Moo9^Yo..AM.   .MA.    //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract MRGTX is ERC721Creator {
    constructor() ERC721Creator("Mr. Gattax", "MRGTX") {}
}
