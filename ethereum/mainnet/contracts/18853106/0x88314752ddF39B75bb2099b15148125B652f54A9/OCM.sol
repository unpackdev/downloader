// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: on-chain musings
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                    .,,uod8B8bou,,.                                        //
//                  ..,uod8BBBBBBBBBBBBBBBBRPFT?l!i:.                        //
//             ,=m8BBBBBBBBBBBBBBBRPFT?!||||||||||||||                       //
//             !...:!TVBBBRPFT||||||||||!!^^""'   ||||                       //
//             !.......:!?|||||!!^^""'            ||||                       //
//             !.........||||                     ||||                       //
//             !.........||||  ##                 ||||                       //
//             !.........||||                     ||||                       //
//             !.........||||                     ||||                       //
//             !.........||||                     ||||                       //
//             !.........||||                     ||||                       //
//             `.........||||                    ,||||                       //
//              .;.......||||               _.-!!|||||                       //
//       .,uodWBBBBb.....||||       _.-!!|||||||||!:'                        //
//    !YBBBBBBBBBBBBBBb..!|||:..-!!|||||||!iof68BBBBBb....                   //
//    !..YBBBBBBBBBBBBBBb!!||||||||!iof68BBBBBBRPFT?!::   `.                 //
//    !....YBBBBBBBBBBBBBBbaaitf68BBBBBBRPFT?!:::::::::     `.               //
//    !......YBBBBBBBBBBBBBBBBBBBRPFT?!::::::;:!^"`;:::       `.             //
//    !........YBBBBBBBBBBRPFT?!::::::::::^''...::::::;         iBBbo.       //
//    `..........YBRPFT?!::::::::::::::::::::::::;iof68bo.      WBBBBbo.     //
//      `..........:::::::::::::::::::::::;iof688888888888b.     `YBBBP^'    //
//        `........::::::::::::::::;iof688888888888888888888b.     `         //
//          `......:::::::::;iof688888888888888888888888888888b.             //
//            `....:::;iof688888888888888888888888888888888899fT!            //
//              `..::!8888888888888888888888888888888899fT|!^"'              //
//                `' !!988888888888888888888888899fT|!^"'                    //
//                    `!!8888888888888888899fT|!^"'                          //
//                      `!988888888899fT|!^"'                                //
//                        `!9899fT|!^"'                                      //
//                          `!^"'                                            //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract OCM is ERC721Creator {
    constructor() ERC721Creator("on-chain musings", "OCM") {}
}
