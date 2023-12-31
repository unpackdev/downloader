// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: inhabitants of thought
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//      ,,                ,,                 ,,        ,,                                                                               //
//      db              `7MM                *MM        db   mm                        mm                                                //
//                        MM                 MM             MM                        MM                                                //
//    `7MM  `7MMpMMMb.    MMpMMMb.   ,6"Yb.  MM,dMMb.`7MM mmMMmm  ,6"Yb.  `7MMpMMMb.mmMMmm ,pP"Ybd                                      //
//      MM    MM    MM    MM    MM  8)   MM  MM    `Mb MM   MM   8)   MM    MM    MM  MM   8I   `"                                      //
//      MM    MM    MM    MM    MM   ,pm9MM  MM     M8 MM   MM    ,pm9MM    MM    MM  MM   `YMMMa.                                      //
//      MM    MM    MM    MM    MM  8M   MM  MM.   ,M9 MM   MM   8M   MM    MM    MM  MM   L.   I8                                      //
//    .JMML..JMML  JMML..JMML  JMML.`Moo9^Yo.P^YbmdP'.JMML. `Mbmo`Moo9^Yo..JMML  JMML.`MbmoM9mmmP'                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                ,...                                                                                                                  //
//              .d' ""                                                                                                                  //
//              dM`                                                                                                                     //
//     ,pW"Wq. mMMmm                                                                                                                    //
//    6W'   `Wb MM                                                                                                                      //
//    8M     M8 MM                                                                                                                      //
//    YA.   ,A9 MM                                                                                                                      //
//     `Ybmd9'.JMML.                                                                                                                    //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//             ,,                                     ,,                                                                                //
//      mm   `7MM                                   `7MM        mm                                                                      //
//      MM     MM                                     MM        MM                                                                      //
//    mmMMmm   MMpMMMb.  ,pW"Wq.`7MM  `7MM  .P"Ybmmm  MMpMMMb.mmMMmm                                                                    //
//      MM     MM    MM 6W'   `Wb MM    MM :MI  I8    MM    MM  MM                                                                      //
//      MM     MM    MM 8M     M8 MM    MM  WmmmP"    MM    MM  MM                                                                      //
//      MM     MM    MM YA.   ,A9 MM    MM 8M         MM    MM  MM                                                                      //
//      `Mbmo.JMML  JMML.`Ybmd9'  `Mbod"YML.YMMMMMb .JMML  JMML.`Mbmo                                                                   //
//                                         6'     dP                                                                                    //
//                                         Ybmmmd'                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//     ,,                                                                                                                               //
//    *MM                                                                                                                               //
//     MM                                                                                                                               //
//     MM,dMMb.`7M'   `MF'                                                                                                              //
//     MM    `Mb VA   ,V                                                                                                                //
//     MM     M8  VA ,V                                                                                                                 //
//     MM.   ,M9   VVV                                                                                                                  //
//     P^YbmdP'    ,V                                                                                                                   //
//                ,V                                                                                                                    //
//             OOb"                                                                                                                     //
//                                                                                                                                      //
//                                                                       ,,    ,,                                                       //
//      mm                                                             `7MM  `7MM            mm                                         //
//      MM                                                               MM    MM            MM                                         //
//    mmMMmm ,pW"Wq.`7MMpMMMb.`7M'   `MF'    `7M'    ,A    `MF',6"Yb.    MM    MM  ,pP"Ybd mmMMmm `7Mb,od8 ,pW"Wq.`7MMpMMMb.pMMMb.      //
//      MM  6W'   `Wb MM    MM  VA   ,V        VA   ,VAA   ,V 8)   MM    MM    MM  8I   `"   MM     MM' "'6W'   `Wb MM    MM    MM      //
//      MM  8M     M8 MM    MM   VA ,V          VA ,V  VA ,V   ,pm9MM    MM    MM  `YMMMa.   MM     MM    8M     M8 MM    MM    MM      //
//      MM  YA.   ,A9 MM    MM    VVV            VVV    VVV   8M   MM    MM    MM  L.   I8   MM     MM    YA.   ,A9 MM    MM    MM      //
//      `Mbmo`Ybmd9'.JMML  JMML.  ,V              W      W    `Moo9^Yo..JMML..JMML.M9mmmP'   `Mbmo.JMML.   `Ybmd9'.JMML  JMML  JMML.    //
//                               ,V                                                                                                     //
//                            OOb"                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//     pd*"*b.  ,pP""Yq.   pd*"*b.  pd""b.                                                                                              //
//    (O)   j8 6W'    `Wb (O)   j8 (O)  `8b                                                                                             //
//        ,;j9 8M      M8     ,;j9      ,89                                                                                             //
//     ,-='    YA.    ,A9  ,-='       ""Yb.                                                                                             //
//    Ammmmmmm  `Ybmmd9'  Ammmmmmm       88                                                                                             //
//                                 (O)  .M'                                                                                             //
//                                  bmmmd'                                                                                              //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract INHABIT is ERC721Creator {
    constructor() ERC721Creator("inhabitants of thought", "INHABIT") {}
}
