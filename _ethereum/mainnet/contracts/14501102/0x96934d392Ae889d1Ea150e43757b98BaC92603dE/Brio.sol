
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brío Presents
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                    U  ___ u  ____       _          //
//     __        __    \/"_ \/ |  _"\  U  /"\  u      //
//     \"\      /"/    | | | |/| | | |  \/ _ \/       //
//     /\ \ /\ / /\.-,_| |_| |U| |_| |\ / ___ \       //
//    U  \ V  V /  U\_)-\___/  |____/ u/_/   \_\      //
//    .-,_\ /\ /_,-.     \\     |||_    \\    >>      //
//     \_)-'  '-(_/     (__)   (__)_)  (__)  (__)     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Brio is ERC721Creator {
    constructor() ERC721Creator(unicode"Brío Presents", "Brio") {}
}
