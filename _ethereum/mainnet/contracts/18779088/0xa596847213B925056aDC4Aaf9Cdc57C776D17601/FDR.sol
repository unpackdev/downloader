// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Motion
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                 /¯¯¯¯ |   /¯¯¯¯\ °     /¯¯¯\ '            /\                              /\‚           /¯¯¯\ '                       /\‚                                                   //
//               /      /|  |  /  /|      |    /         \‚         /    \__________'        /    \‚       /         \‚                    /    \ ‚                                            //
//             /      /::|  |/  /:/      /|‘ /            '\°      |                        \°    /      /|     /            '\°                /        \‘                                    //
//           /      /::::|__/:/      /::| |        |\      \°    |\____         _       \'  |      |:'|    |        |\      \°             |\          \                                       //
//         /      /:::::/|:::|/      /::::|‘|        |::\      \ '‚ |:|::::::|\       \:|\     /|° |      |:'|    |        |::\      \ '‚        /\|::\         '\  '                          //
//       /      /:::::/  |::/      /:::::/°|\       '\:::\      \ '|:|::::::|::\       \::\/:::|  |\      \/    |\       '\:::\      \ '     /    \:::\         \‚                             //
//     /      /:::::/    |/      /:::::/'‚  |::\       '\::|      |  \|::::::|::::\       \:|:::|  |::\      \   |::\       '\::|      |    /        \:::\        '\ °                         //
//    |      |:::::/    /      /:::::/'     |::::\       '\|      |    ¯¯¯ \:::::\       \:::/‘ |:::|      |'  |::::\       '\|      |   |\          \::|         |'                           //
//    |\      \::/     |      |:::::/‘       \:::::\            /|            \::::|        |/'   \:::|      |°  \:::::\            /|   |:|       |\  \/        /|‘                           //
//    |::\    /|/      |\      \::/‘           \:::::\____ /::|              \'/        /|‘      \/      /|     \:::::\____ /::|   |/       /|::\____ /::|'                                    //
//    |::::\/::|       |::\    /|/               \::::|::::::|:::'|              |\       /::|'     /      /::|       \::::|::::::|:::'|  /       /::|:::|::::::|:::|‘                         //
//    \::::|:::|       |::::\/::|                  \::|::::::|::/‘ '             |::\   /::::|'    |\    /::::|°        \::|::::::|::/‘ '|\     /::::|\::|::::::|::/‘                          //
//      \::|::/        \::::|:::|‘                   \|::::::|/‘   '             |:::'\/:::::/‘    |::\/:::::/            \|::::::|/‘   '|::\ /:::::/   \|::::::|/  '                          //
//        \|/            \::|::/'                      ¯¯¯'                   \::::|::::/ '‚    |:::|::::/ '‚             ¯¯¯'      |:::|::::/       ¯¯¯                                       //
//                         \|/       °                ‘                          \::|::/ '‚       \::|::/                 ‘            \::|::/                                                 //
//                                                               ‘                 \|/°            \|/                              ‘   \|/                                                    //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FDR is ERC1155Creator {
    constructor() ERC1155Creator("Motion", "FDR") {}
}
