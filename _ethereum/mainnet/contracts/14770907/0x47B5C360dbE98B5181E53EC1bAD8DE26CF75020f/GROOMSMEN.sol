
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Glorious Wedding of Taylor & Ben
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                        :^~!?JJYYY55YYYY55Y5Y??7!~:.                                        //
//                                  .^!7JY55YJJJ?77??7!777??7777?JYYYYYJ?~^.                                  //
//                              .~?J55J????JYYYYYYJJJ??????JJJYYYYYJJ???JY55J7~:                              //
//                          .^7YP5J??JY55JJJ???JJYJYYYJJJJJYYYYJJ????JY55YJ??Y5P57^                           //
//                        :?PPY??J5PYJ?7?J55YJJ?!~~^:::::::^^^~!?JY55YJ???Y55Y??J5P57:                        //
//                     .!5P5?7JP5J?7J55Y?7^.                       .:^!J555J7?J55J7?5GY!.                     //
//                   ^?PGJ7J55J7?5P5?~.                                  .^?5P5??YPPJ?JPP?.                   //
//                 .?GP??YP57?5P57:                                          :75G5??5G5??PP7.                 //
//                7GP?75GJ?JPP?:                                                ^JPPJ75G57?GP!                //
//              ^YBJ!YGY7JGP!.                                                    .!PGJ7JGY!JGY^              //
//             7GP!?G5!?GP!                                                         .7PG?7PG7!PG!             //
//            ?BY~5GJ~5G?.                                   .:::^^::::::^:::.        .JG5!JGY~YBJ            //
//          .YB?~PG!?GP~    7555555555555555555555J.         YGPPPPPPPGGGGGPPP5J!.      ~PG7!G5~JBJ.          //
//          JB?~GP~?BY.    ?BBGBGGGPPPPPGGP5PPGGGB5.         YGPPPPGGP5555PPGPPGGP7      :YB?!PP^?BY          //
//         JG?^PP^JBJ.    :77!!!!^~5PPPPGG^ ..:^~~.          JGPPP5P5^  ...:YPP5PPG?      .JB?^GP~JB7         //
//        !B5:5G~7BJ               YGPPPPY.                  7G55PPP7       ^P55PPP5.       JG!!GP:YG~        //
//       :PG^?B7~GP.               YPPPPGY         .:^:.     7GPPPPG~       .PPPPPGP:       .PG~JB?^GP.       //
//       ?B?^GP:PG~                JGPPPGY       ~YPYYY7     !GPPPPG^       .5PPP5GP.        ~G5^PG:JB?       //
//      .5G^JB!!BY                 !GGPGG7      ~GGP.        ^GPPPPP:       ^PPPPPG?          5B!!B?^GP.      //
//      ~GY.PP:5G~                 ?GGPPG7      ?GGP.        ^GPPPP5.    ..^YGPPPG?           !GJ:GP.YP:      //
//      7B!^GY.PP.                 7GPPPG?      :GGG^        .5PPPPP.~JY555PPPPP5~            .PP:5G:7B!      //
//      7B~~B7^G5.                 !GPPGG!       JGG5.       .PPPPP5JGBGGGGPPP5PJ:            .PP ?G^!B7      //
//      ?B~:G?^BJ                  7GGPPG7       !GGGJ  .!~  .PPPPP5~^~~~!7JPPPPGP7.          .PP ?B^~B7      //
//      ?B~^GJ.P5                  7GGPPG7     .JGJGGG! 7G^  ^PPPPPP.       7G5PPPGJ           PP.JB^~B7      //
//      !B?^G5 5G:                 7GPPPG7    .YGP.7GGP!P?   ^PPPPPP.       .55555PP^         :G5.5P:?B!      //
//      ^G5.PG:JB!                 5GPPPGJ    ~GG5. JGGG5.   ^GPPPG5.       .5P55PPG!         ?B?^G5.PP:      //
//       5G^7BJ~G5                 JPPPPG5    7GGP. :PGGY    :PP5PPP.       .5P555PG~        .5G^JB7~G5       //
//       !BJ^GG^JG~                JGPPPGY    7GGP.  7GGG7   ^PPP5PP:       :PPP55PG!        ?BJ^GP:5G~       //
//        YB!7BJ.PG~              .5PPPPGJ    .5BG7.:JPGGG~  ~GP55PP~       ~P555PPP:       ^GP:YB!!BY        //
//        ^GP^JB!~GP:             .PPPPPGY     .7Y5YY7.7Y5?  7P555PP7.    .!5PPPPPG?       ^PG^?B?^GP:        //
//         !G5:YG7!GP:            .5GPPPGP:       ..         JGP55PPPPYYY55GP5PPGGJ       ^PG!!BY:5G~         //
//          7BJ:5B7~GP~           .PGGGGG5.                 .5GGGPGPGGGGGGGGPPP5?~       !PP~?BJ^5B!          //
//           !G5~JBJ~YG?.          :^^~^^:                   ^~~!!!!!~~~!!!~^^:        .JBY~JBY^PG7           //
//            ~GP~?G5~?G5~                                                            !PG?!PP7!PG~            //
//             ^5G?!YG?!YGY^                                                        ^YGY!JG5~JBY:             //
//               ?GP!7PP775G5~                                                    !5G5!?GP775G7               //
//                ^5B5~7PP?7JG57:                                              ^75GJ!?PP7~5B5^                //
//             .~J55YJ!.!PBPY!75G57:                                       .:!5G577YGB5!:~Y5P5?~.             //
//           ~YP5J?7JYY5YJ?7?^ .^75G5?~:.                              .:!JPG5?:  ~?7JJY5YY?77J5PJ~           //
//         !5GY7?55Y?7?JYYYYYYYYJJ5PPPPPY.                            :YPGGGPYJJYYYJJYYYJ77?5P5?7YG5~         //
//       .YBY!?P5?7Y55Y7~::::...::::.....                              ....::...:::..:^~7YPPY?J5PJ7YGJ:       //
//      ^PG77PP7?PGY~.                                                                    .~YG57?PP7!GP^      //
//     ^GP^?BY~5GJ^          .~7JY5Y?~.     :!?Y5YJ!:      ^!JY5Y?!:     ^!JY5YJ!:           ^YGY~YG7~GP:     //
//    .5G~7BJ^PG!           !PGJ!~!!JGP!  .?GP?~!!?5G?   ^5GY7!!!?PG7  :YG57!!~75GY.           !GP^YB!~GY.    //
//    ?BJ^GP:5G!           !BB!      ~GG^.5BJ.      JBJ :GBJ      :PG! 5B5      .PB?            7BY:GP^YG!    //
//    JG^!B7^G5            :7!       7GG^~GP:       :PB!.77:      ^PB! !?^      :5B?             5G.?B7~GY    //
//    5G:~B~!B?                  .^!5GY^ YGP.       .PGY       .!5GP!        .~YGP?              JG:!B!:G5    //
//    YG^!B?:GY               .~?PPY?^   ?GP.       .PB7    ^J5P5?^.      ^?YPPJ~.              .5G^?B~~GY    //
//    7BJ^GP:YG~            :JPPJ~.      :PG!       !GP: .75PJ~.        !5GY!:                  7BJ:PP:5G!    //
//    .5G~7BJ:PG!          ^PBY^::::::::  ^PG?^...:?GP~ :5BP!:::::^:: .YBG7::::::::.           !G5:YB!~G5.    //
//     ^GG~7BJ~5GJ:        JPPPPPPPPPPPJ.  .75P555P5!.  7PPP5PPPPPPP5:^PPP5PPPPP5PP~         ^YGY~YB7~GP^     //
//      ~PG7!PP7?PPJ~.      ...........        .:..      ............  ......:.....       .~YGP77GP77GP:      //
//       :YGY~JGP??YPPY?!~:.........................................................::^~7YP5J??5P?!YGJ:       //
//         ~YPJ7?55YJ??JYYY5YYYYYYYYYYYYJYYYYYYYJYYYYJYYJYYYYYJYYYYJYYJYYYYJYYYYYYYYYYYJ????5P5?7JG5~         //
//           ~YP5J7?JYYJJJ??JJ????JJJ????JJJ????JJJ????JJ????JJJ????JJJ????JJJ????JJ??JY5YYJ??JPPJ~           //
//             .~J55YJ????777!!77777!77777!!77777!!77777!!77777!!7777!!77777!!77777!!7????J55YJ~.             //
//                 .^7J5Y5YYYYY55YYYY55YYYYY55YYYY55YYYYYY55YYYY55YYYYY55YYYY55YYYYYY55YYJ7~.                 //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GROOMSMEN is ERC721Creator {
    constructor() ERC721Creator("The Glorious Wedding of Taylor & Ben", "GROOMSMEN") {}
}
