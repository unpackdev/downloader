
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Musthafa
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                               ,,                    ,...           //
//         ,.-==-.   `7MMM.     ,MMF'                     mm   `7MM                  .d' ""           //
//      ,pd'      `g.  MMMb    dPMM                       MM     MM                  dM`              //
//     ,P   ,dMb.A  Y. M YM   ,M MM `7MM  `7MM  ,pP"Ybd mmMMmm   MMpMMMb.   ,6"Yb.  mMMmm ,6"Yb.      //
//    ,P   dP  ,MP  j8 M  Mb  M' MM   MM    MM  8I   `"   MM     MM    MM  8)   MM   MM  8)   MM      //
//    8:  dM'  dM   d' M  YM.P'  MM   MM    MM  `YMMMa.   MM     MM    MM   ,pm9MM   MM   ,pm9MM      //
//    Wb  YML.dML..d'  M  `YM'   MM   MM    MM  L.   I8   MM     MM    MM  8M   MM   MM  8M   MM      //
//     Wb  ``""^`"'  .JML. `'  .JMML. `Mbod"YML.M9mmmP'   `Mbmo.JMML  JMML.`Moo9^Yo.JMML.`Moo9^Yo.    //
//      `M..     .,!                                                                                  //
//        `Ybmmd'                                                                                     //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MUSA is ERC721Creator {
    constructor() ERC721Creator("Musthafa", "MUSA") {}
}
