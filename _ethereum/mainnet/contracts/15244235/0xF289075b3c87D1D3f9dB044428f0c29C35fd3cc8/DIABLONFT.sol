
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Diablo NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//          (                  )  (           )         )                                 //
//          )\ )  (      )  ( /(  )\       ( /(      ( /(    (                            //
//         (()/(  )\  ( /(  )\())((_) (    )\()) (   )\())  ))\  (                        //
//          ((_))((_) )(_))((_)\  _   )\  (_))/  )\ ((_)\  /((_) )\ )                     //
//          _| |  (_)((_)_ | |(_)| | ((_) | |_  ((_)| |(_)(_))  _(_/(                     //
//        / _` |  | |/ _` || '_ \| |/ _ \ |  _|/ _ \| / / / -_)| ' \))                    //
//        \__,_|  |_|\__,_||_.__/|_|\___/  \__|\___/|_\_\ \___||_||_|                     //
//                                                                                        //
//                   Diablo NFTs are a Diablo Token project                               //
//                                                                                        //
//               Diablo Token is a experiment that demonstrates                           //
//             how simple deflationary tokenomics can be executed                         //
//                to build value thru volume and entertainment.                           //
//                        DiabloToken.eth / 0xrDan 2022                                   //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract DIABLONFT is ERC721Creator {
    constructor() ERC721Creator("Diablo NFTs", "DIABLONFT") {}
}
