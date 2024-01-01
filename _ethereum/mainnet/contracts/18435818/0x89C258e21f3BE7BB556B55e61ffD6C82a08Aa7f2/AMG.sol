// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AMGalería
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                 ,AMGaleríaxxxAMGaleríaxxxAMGalería,                 //
//               ,aP8b    _,dYba,       ,adPb,_    d8Ya,               //
//             ,aP"  Yb_,dP"   "Yba, ,adP"   "Yb,_dP  "Ya,             //
//           ,aP"    _88"         )888(         "88_    "Ya,           //
//         ,aP"   _,dP"Yb      ,adP"8"Yba,      dP"Yb,_   "Ya,         //
//       ,aPYb _,dP8    Yb  ,adP"   8   "Yba,  dP    8Yb,_ dPYa,       //
//     ,aP"  YdP" dP     YbdP"      8      "YbdP     Yb "YbP  "Ya,     //
//    I8aaaaaa8aaa8baaaaaa8AMGalería8AMGalería8aaaaaad8aaa8aaaaaa8I    //
//    `Yb,   d8a, Ya      d8b,      8      ,d8b      aP ,a8b   ,dP'    //
//      "Yb,dP "Ya "8,   dI "Yb,    8    ,dP" Ib   ,8" aP" Yb,dP"      //
//        "Y8,   "YaI8, ,8'   "Yb,  8  ,dP"   `8, ,8IaP"   ,8P"        //
//          "Yb,   `"Y8ad'      "Yb,8,dP"      `ba8P"'   ,dP"          //
//            "Yb,    `"8,        "Y8P"        ,8"'    ,dP"            //
//              "Yb,    `8,         8         ,8'    ,dP"              //
//                "Yb,   `Ya        8        aP'   ,dP"                //
//                  "Yb,   "8,      8      ,8"   ,dP"                  //
//                    "Yb,  `8,     8     ,8'  ,dP"   Normand          //
//                      "Yb, `Ya    8    aP' ,dP"     Veilleux         //
//                        "Yb, "8,  8  ,8" ,dP"                        //
//                          "Yb,`8, 8 ,8',dP"                          //
//                            "Yb,Ya8aP,dP"                            //
//                              "Y88888P"                              //
//                                "Y8P"                                //
//                                  "                                  //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract AMG is ERC1155Creator {
    constructor() ERC1155Creator(unicode"AMGalería", "AMG") {}
}
