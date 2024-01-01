// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anita Gryz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//     \│/ ╔═╗┌┐┌┬┌┬┐┌─┐ ╔═╗┬─┐┬ ┬┌─┐ \│/    //
//     ─ ─ ╠═╣││││ │ ├─┤ ║ ╦├┬┘└┬┘┌─┘ ─ ─    //
//     /│\ ╩ ╩┘└┘┴ ┴ ┴ ┴ ╚═╝┴└─ ┴ └─┘ /│\    //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract AG is ERC721Creator {
    constructor() ERC721Creator("Anita Gryz", "AG") {}
}
