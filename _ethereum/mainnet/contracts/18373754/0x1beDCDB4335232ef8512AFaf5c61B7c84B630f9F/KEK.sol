// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kek Chronicles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    _-_ _,,               ,,                 //
//       -/  )    _         ||     '           //
//      ~||_<    < \, -_-_  ||/\\ \\  _-_      //
//       || \\   /-|| || \\ || || || || \\     //
//       ,/--|| (( || || || || || || ||/       //
//      _--_-'   \/\\ ||-'  \\ |/ \\ \\,/      //
//     (              |/      _/               //
//                    '                        //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract KEK is ERC721Creator {
    constructor() ERC721Creator("Kek Chronicles", "KEK") {}
}
