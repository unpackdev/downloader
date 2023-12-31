// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BOTANICAL ILLUSIONS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//      o            o__ __o      o              o    o__ __o__/_     //
//     <|>          /v     v\    <|>            <|>  <|    v          //
//     / \         />       <\   < >            < >  < >              //
//     \o/       o/           \o  \o            o/    |               //
//      |       <|             |>  v\          /v     o__/_           //
//     / \       \\           //    <\        />      |               //
//     \o/         \         /        \o    o/       <o>              //
//      |           o       o          v\  /v         |               //
//     / \ _\o__/_  <\__ __/>           <\/>         / \  _\o__/_     //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract FLO is ERC721Creator {
    constructor() ERC721Creator("BOTANICAL ILLUSIONS", "FLO") {}
}
