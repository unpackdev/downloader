// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeeZeGems
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//     ______       .-_'''-.       .-''-.  ,---.    ,---.   .-'''-.      //
//    |    _ `''.  '_( )_   \    .'_ _   \ |    \  /    |  / _     \     //
//    | _ | ) _  \|(_ o _)|  '  / ( ` )   '|  ,  \/  ,  | (`' )/`--'     //
//    |( ''_'  ) |. (_,_)/___| . (_ o _)  ||  |\_   /|  |(_ o _).        //
//    | . (_) `. ||  |  .-----.|  (_,_)___||  _( )_/ |  | (_,_). '.      //
//    |(_    ._) ''  \  '-   .''  \   .---.| (_ o _) |  |.---.  \  :     //
//    |  (_.\.' /  \  `-'`   |  \  `-'    /|  (_,_)  |  |\    `-'  |     //
//    |       .'    \        /   \       / |  |      |  | \       /      //
//    '-----'`       `'-...-'     `'-..-'  '--'      '--'  `-...-'       //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract DGEMs is ERC1155Creator {
    constructor() ERC1155Creator("DeeZeGems", "DGEMs") {}
}
