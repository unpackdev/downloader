// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Be Ordinary
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                        ,,    ,,                                               //
//    `7MM"""Yp,                .g8""8q.                `7MM    db                                               //
//      MM    Yb              .dP'    `YM.                MM                                                     //
//      MM    dP  .gP"Ya      dM'      `MM `7Mb,od8  ,M""bMM  `7MM  `7MMpMMMb.   ,6"Yb.  `7Mb,od8 `7M'   `MF'    //
//      MM"""bg. ,M'   Yb     MM        MM   MM' "',AP    MM    MM    MM    MM  8)   MM    MM' "'   VA   ,V      //
//      MM    `Y 8M""""""     MM.      ,MP   MM    8MI    MM    MM    MM    MM   ,pm9MM    MM        VA ,V       //
//      MM    ,9 YM.    ,     `Mb.    ,dP'   MM    `Mb    MM    MM    MM    MM  8M   MM    MM         VVV        //
//    .JMMmmmd9   `Mbmmd'       `"bmmd"'   .JMML.   `Wbmd"MML..JMML..JMML  JMML.`Moo9^Yo..JMML.       ,V         //
//                                                                                                   ,V          //
//                                                                                                OOb"           //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOG is ERC721Creator {
    constructor() ERC721Creator("Be Ordinary", "BOG") {}
}
