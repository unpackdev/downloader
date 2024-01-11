
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EbicJo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                  ....                                  //
//                           .^^^^^~~!77!~^^:.                            //
//                        .:^^^::^~!7?JJY?7!77~.                          //
//                      .~~77777777!?J55555YJ?7?:                         //
//                     ^7JJ?7!~^:::!_EBICJO.ETH_7:                        //
//                    .?!75!.      ..::^~!7J55P5J7.                       //
//                    .JY!:.          ....:^!?YJ?7.                       //
//                    ^J?:              ....::^77?:                       //
//                    ^!~.                  ....^J:                       //
//                    :~^.                      :J:                       //
//    ...****#########~?7:.3::33::.8888.::^^:..:J:BBBBBB+++++~~~.. ..     //
//       .~~+++#######7Y?~~~!!!!88!~!~~77!7777!~7J!^^::::^^^^^:.... .     //
//    ...~~~++#######?77~!~~~~!!7!!99997769!777?7~~^::####+++++~~         //
//          '' '    .PB~.8888888..:....:::^~^^^^^^~::::.###'''' ...       //
//                 .5B#5     ...     ............                         //
//                .PBGGB7               ..                                //
//                5BBBBBB^            .....                               //
//               ~BBBBBBBP.           .....   7?                          //
//               ~BBBBBBBBP:      ....:.... .7BB^                         //
//               .GBBBBBBBBG.       ........YBBBY                         //
//                ?BBBBBBBBBY.        .....7BBBBG~                        //
//               .!GGBBBBBBGB5~...........7GBBBBBBPJ7~:                   //
//            .~YGGPGGBBBBBBGBGJ^.......^JGBBBBBBBBBBBB5!^.               //
//          ^JPBBBGGPPPGBBBBBBBBG5J??JYPGBBBBBBBBBBBGGBBBBG5^             //
//        ^YBBBGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBGGBBBBBBGY^           //
//       !GBBBBBGGGGGBBBBBGGGGBBBBBBBBBBBBBBBBBBBBBBGBBBBBBBBBGY:         //
//    .^JGGGBBBGGGGGBBBBGGBGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG~.       //
//    YPGGGGBBGGGGGGBBBBGGGGGG EBICJO.ART BBBBBBBBBBBBBBBBBBBBBBBBJ:.     //
//                                                                        //
//                 Exploring interactive NFT Use Cases                    //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract EBIC is ERC721Creator {
    constructor() ERC721Creator("EbicJo", "EBIC") {}
}
