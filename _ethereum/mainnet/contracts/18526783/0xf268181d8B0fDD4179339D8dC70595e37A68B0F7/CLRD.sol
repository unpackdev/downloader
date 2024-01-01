// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COLORIDɅ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                    ..::...            ...::..        . . :                ..::...        ^::::::::..        ....    ::.::::::..            ^.::::.:.                   //
//                 ??YJYYYYYYJ?!      ~?JYYYYYYJY??.    #^#:&             ??YJYYYYYYJ?~    ^#~PJJYYYYYYJJ^    75J?P!  .&~PJJYYYYYYJJ!        ?P5YYYJPJP                   //
//                B~P75?~~~J?JJYY    ?5?Y?Y!~~?57P~B    B^#:#            B!P7Y?~~!Y?Y?5J   ^G~P~P!77?57P!G~   7YJ?5!  .#:#^G!77?Y?Y?5Y       G7B7Y?JG7#                   //
//               !P7YJY     B:#:&    #:#:#     ?YJJY?   B^#:#           75?YJJ     #:#:#   ^G!5?Y    :B^B^B   7YJ?5!  .#:B~B    .#:#:&       #75P: G?YB:                  //
//               ?YY7P~     P~G^#.   #:#^B     :B~P75   B^#:#           J?Y!G^     B~B:#.  ^G!5?Y     &:#:#   7YJ?5!  .#:B~B     B^B:#.     ^G57B  G!GY?                  //
//               JJY7G^     G~B^#.   #:B^B     :B^G!P   B^#:#           J?5~G^     G~B^#.  ^G!5?Y     &:#:#   7YJ?5!  .#:B~B     G~B:#.     Y?B~G  5!B!G                  //
//               JJ5!G^     . . :   .#:B^G     .#^G!G   B^#:#           Y7P~B:     G!G^#.  ^G!5?Y     #:#:#   7YJ?5!  .#:B~B     G~B^#.     B~B7Y  !JG!#                  //
//               JJ5!G^             .#:B^G     .#^B~G   B^#:#           Y7P~B:     G!G~B:  ^G!5?Y    .#:#:#   7YJ?5!  .#:B~B     G~B^#.    .#!PY~  .G?JG^                 //
//               Y?5!G^             .#:B^G     .#^B~G   B^#:#           Y7P~B:     G7G~B:  ^G!5!P^~~~Y?Y?YY   7YJ?5!  .#:B~B     G~B^#.    ~PY7B.   B~G?Y                 //
//               J?5!G^             .#:B^G     .#^B~G   B^#:#           Y7P~B:     G!G^B.  ^G~#!JYY?GY7J??    7YJ?5!  .#:B~B     G~B^#.    P7B~#    G~#~B                 //
//               JJ5!G^     ~~!^?:   #:B^G     :#^G!P   B^#:#           Y75~G:     G!G^#.  ^G!5!P^!P~G:&      7YJ?5!  .#:B~B     G~B^#.    #^#~G    J?G~#.                //
//               ?JY!P~     JJ57G~   #:B^B     :B~G75   B^#:#           J?5!G^     B~B^#.  ^G!5?Y  57P!P7     7YJ?5!  .#:B~B     G^B:#.   .B!PJJ    ~PJJP~                //
//               ?YJ7P~     J?5!G^   #:#:#     ^B~P?Y   B^#:#           JJY!G~     B^B:#.  ^G!5?Y   #^#:&     7YJ?5!  .#:B~G     B^B:#    75Y7G^    .#~B75                //
//               ^B~G!P    .G^B:#.   #^B^G^    575!G~   B^#:&.          ~G~P!P    :B^B:#   ^G!5?Y   !5?Y7P    7YJ?5!  .#:B^B    ^G^B:#    G~B^#      #^#^#                //
//                YJYJJY??JYJY?57    :G75?YJ??YJJY?5    #:B~YJJJJJJJ7    5JYJJY??JY?57G^   ^G!5?Y    B~B^#:   75J?P!  .#:#~5JJJJY?57G^    #^#^#      G!B~#.               //
//                 :!7?JJJJ??7~.       ~7?JJJJJ?7!:     G??YJJJJJJJJ7     :!?JJJJJ??!~     :5~J!?    :P^5^P   !J7!J~   B!JJJJJJJJ?7!.    .P^5~Y      !J?7Y~               //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLRD is ERC721Creator {
    constructor() ERC721Creator(unicode"COLORIDɅ", "CLRD") {}
}
