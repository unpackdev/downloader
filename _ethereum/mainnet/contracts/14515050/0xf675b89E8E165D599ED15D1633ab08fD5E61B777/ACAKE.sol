
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alpha Birthday Cakes 🥳🎂
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//            CCCCCCCCCCCCC                AAA                KKKKKKKKK    KKKKKKK EEEEEEEEEEEEEEEEEEEEEE    //
//         CCC::::::::::::C               A:::A               K:::::::K    K:::::K E::::::::::::::::::::E    //
//       CC:::::::::::::::C              A:::::A              K:::::::K    K:::::K E::::::::::::::::::::E    //
//      C:::::CCCCCCCC::::C             A:::::::A             K:::::::K   K::::::K EE::::::EEEEEEEEE::::E    //
//     C:::::C       CCCCCC            A:::::::::A            KK::::::K  K:::::KKK   E:::::E       EEEEEE    //
//    C:::::C                         A:::::A:::::A             K:::::K K:::::K      E:::::E                 //
//    C:::::C                        A:::::A A:::::A            K::::::K:::::K       E::::::EEEEEEEEEE       //
//    C:::::C                       A:::::A   A:::::A           K:::::::::::K        E:::::::::::::::E       //
//    C:::::C                      A:::::A     A:::::A          K:::::::::::K        E:::::::::::::::E       //
//    C:::::C                     A:::::AAAAAAAAA:::::A         K::::::K:::::K       E::::::EEEEEEEEEE       //
//    C:::::C                    A:::::::::::::::::::::A        K:::::K K:::::K      E:::::E                 //
//     C:::::C       CCCCCC     A:::::AAAAAAAAAAAAA:::::A     KK::::::K  K:::::KKK   E:::::E       EEEEEE    //
//      C:::::CCCCCCCC::::C    A:::::A             A:::::A    K:::::::K   K::::::K EE::::::EEEEEEEE:::::E    //
//       CC:::::::::::::::C   A:::::A               A:::::A   K:::::::K    K:::::K E::::::::::::::::::::E    //
//         CCC::::::::::::C  A:::::A                 A:::::A  K:::::::K    K:::::K E::::::::::::::::::::E    //
//            CCCCCCCCCCCCC AAAAAAA                   AAAAAAA KKKKKKKKK    KKKKKKK EEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ACAKE is ERC721Creator {
    constructor() ERC721Creator(unicode"Alpha Birthday Cakes 🥳🎂", "ACAKE") {}
}
