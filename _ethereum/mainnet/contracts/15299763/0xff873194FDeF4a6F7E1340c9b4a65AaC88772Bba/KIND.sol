
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kind Soul Commune
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//              )                    )      //
//       (   ( /(   (    (    (   ( /(      //
//     ( )\  )\())( )\   )\ ( )\  )\())     //
//     )((_)((_)\ )((_)(((_))((_)((_)\      //
//    ((_)_|_ ((_|(_)_ )\__((_)___ ((_)     //
//     | _ ) |/ / | _ |(/ __| _ ) \ / /     //
//     | _ \ ' <  | _ \| (__| _ \\ V /      //
//     |___/_|\_\ |___/ \___|___/ |_|       //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract KIND is ERC721Creator {
    constructor() ERC721Creator("Kind Soul Commune", "KIND") {}
}
