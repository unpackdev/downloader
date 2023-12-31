// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRIFTICLE PASS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//                                                   (                      //
//     (               (        )          (         )\ )                   //
//     )\ )    (   (   )\ )  ( /( (        )\   (   (()/(    )              //
//    (()/(    )(  )\ (()/(  )\()))\   (  ((_) ))\   /(_))( /(  (   (       //
//     /(_))_ (()\((_) /(_))(_))/((_)  )\  _  /((_) (_))  )(_)) )\  )\      //
//    (_)) __| ((_)(_)(_) _|| |_  (_) ((_)| |(_))   | _ \((_)_ ((_)((_)     //
//      | (_ || '_|| | |  _||  _| | |/ _| | |/ -_)  |  _// _` |(_-<(_-<     //
//       \___||_|  |_| |_|   \__| |_|\__| |_|\___|  |_|  \__,_|/__//__/     //
//                                                                          //
//    ------------------------- BY HARSHA ------------------------------    //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract GP is ERC721Creator {
    constructor() ERC721Creator("GRIFTICLE PASS", "GP") {}
}
