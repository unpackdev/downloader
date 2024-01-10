
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Galloire
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//     __                __     __   __                                                                                           //
//    / _   /\  |   |   /  \ | |__) |_                                                                                            //
//    \__) /--\ |__ |__ \__/ | | \  |__                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    '                   .lkkkkkkkkkkkkkkkkkxxxkx;   ;xxkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxx;                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.  cO0000000000000000000000000000000000000000000000000O:                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.   ...................................................                        //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                                                                              //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                                                                              //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                                                                              //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                                                                              //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                                                                              //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                                                                              //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                                                                              //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                                                                              //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                               ........................                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              'kXXXXXXXXXXXXXXXXXXXXXKc                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              ,0MMMMMMMMMMMMMMMMMMMMMWl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.                              ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo.  .........................   ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. .d0K0000K0000000000000000l.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. 'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo. 'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  'OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMNl                       //
//    '                   ,0MMMMMMMMMMMMMMMMMMMMMWo  .OMMMMMMMMMMMMMMMMMMMMMMWd.  ,0MMMMMMMMMMMMMMMMMMMMMWl                       //
//    '                   .lxxxxxxxxxxxxxxxxxxxxxd;  .cxxxxxxxxxxxxxxxxxxxxxxx:.  .lxxxxxxxxxxxxxxxxxxxxxd;                       //
//    '                                                                                                                           //
//    '                                                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GAL is ERC721Creator {
    constructor() ERC721Creator("Galloire", "GAL") {}
}
