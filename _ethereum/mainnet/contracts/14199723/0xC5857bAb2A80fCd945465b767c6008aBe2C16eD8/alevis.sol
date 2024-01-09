
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alevi´s Originals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//               ,ggg,                                                   _,gggggg,_                                                                                    //
//              dP""8I   ,dPYb,                                        ,d8P""d8P"Y8b,                                                              ,dPYb,              //
//             dP   88   IP'`Yb                                       ,d8'   Y8   "8b,dP                                                           IP'`Yb              //
//            dP    88   I8  8I                        gg             d8'    `Ybaaad88P'          gg                gg                             I8  8I              //
//           ,8'    88   I8  8'                        ""             8P       `""""Y8            ""                ""                             I8  8'              //
//           d88888888   I8 dP   ,ggg,      ggg    gg  gg     ,g,     8b            d8 ,gggggg,   gg     ,gggg,gg   gg    ,ggg,,ggg,     ,gggg,gg  I8 dP    ,g,        //
//     __   ,8"     88   I8dP   i8" "8i    d8"Yb   88bg88    ,8'8,    Y8,          ,8P dP""""8I   88    dP"  "Y8I   88   ,8" "8P" "8,   dP"  "Y8I  I8dP    ,8'8,       //
//    dP"  ,8P      Y8   I8P    I8, ,8I   dP  I8   8I  88   ,8'  Yb   `Y8,        ,8P',8'    8I   88   i8'    ,8I   88   I8   8I   8I  i8'    ,8I  I8P    ,8'  Yb      //
//    Yb,_,dP       `8b,,d8b,_  `YbadP' ,dP   I8, ,8I_,88,_,8'_   8)   `Y8b,,__,,d8P',dP     Y8,_,88,_,d8,   ,d8I _,88,_,dP   8I   Yb,,d8,   ,d8b,,d8b,_ ,8'_   8)     //
//     "Y8P"         `Y88P'"Y88888P"Y8888"     "Y8P" 8P""Y8P' "YY8P8P    `"Y8888P"'  8P      `Y88P""Y8P"Y8888P"8888P""Y88P'   8I   `Y8P"Y8888P"`Y88P'"Y88P' "YY8P8P    //
//                                                                                                           ,d8I'                                                     //
//                                                                                                         ,dP'8I                                                      //
//                                                                                                        ,8"  8I                                                      //
//                                                                                                        I8   8I                                                      //
//                                                                                                        `8, ,8I                                                      //
//                                                                                                         `Y8P"                                                       //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract alevis is ERC721Creator {
    constructor() ERC721Creator(unicode"Alevi´s Originals", "alevis") {}
}
