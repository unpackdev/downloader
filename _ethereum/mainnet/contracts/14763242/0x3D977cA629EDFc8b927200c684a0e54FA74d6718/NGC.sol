
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neonrian Genisis Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//     :::=====  :::===== :::= === ::: :::===  ::: :::===     //
//     :::       :::      :::===== ::: :::     ::: :::        //
//     === ===== ======   ======== ===  =====  ===  =====     //
//     ===   === ===      === ==== ===     === ===     ===    //
//      =======  ======== ===  === === ======  === ======     //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract NGC is ERC721Creator {
    constructor() ERC721Creator("Neonrian Genisis Collection", "NGC") {}
}
