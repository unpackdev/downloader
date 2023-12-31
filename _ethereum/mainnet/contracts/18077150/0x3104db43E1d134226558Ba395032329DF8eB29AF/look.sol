// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Look Highward
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                ,,            ,,                                               ,,      //
//    `7MMF'                        `7MM          `7MMF'  `7MMF'  db          `7MM                                             `7MM      //
//      MM                            MM            MM      MM                  MM                                               MM      //
//      MM         ,pW"Wq.   ,pW"Wq.  MM  ,MP'      MM      MM  `7MM  .P"Ybmmm  MMpMMMb.`7M'    ,A    `MF',6"Yb.  `7Mb,od8  ,M""bMM      //
//      MM        6W'   `Wb 6W'   `Wb MM ;Y         MMmmmmmmMM    MM :MI  I8    MM    MM  VA   ,VAA   ,V 8)   MM    MM' "',AP    MM      //
//      MM      , 8M     M8 8M     M8 MM;Mm         MM      MM    MM  WmmmP"    MM    MM   VA ,V  VA ,V   ,pm9MM    MM    8MI    MM      //
//      MM     ,M YA.   ,A9 YA.   ,A9 MM `Mb.       MM      MM    MM 8M         MM    MM    VVV    VVV   8M   MM    MM    `Mb    MM      //
//    .JMMmmmmMMM  `Ybmd9'   `Ybmd9'.JMML. YA.    .JMML.  .JMML..JMML.YMMMMMb .JMML  JMML.   W      W    `Moo9^Yo..JMML.   `Wbmd"MML.    //
//                                                                   6'     dP                                                           //
//                                                                   Ybmmmd'                                                             //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract look is ERC721Creator {
    constructor() ERC721Creator("Look Highward", "look") {}
}
