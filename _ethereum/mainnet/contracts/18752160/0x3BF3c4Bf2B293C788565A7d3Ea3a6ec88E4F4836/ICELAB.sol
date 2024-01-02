// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ICELAB
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//    IIIIIIIIII      CCCCCCCCCCCCCEEEEEEEEEEEEEEEEEEEEEELLLLLLLLLLL                            AAA               BBBBBBBBBBBBBBBBB       //
//    I::::::::I   CCC::::::::::::CE::::::::::::::::::::EL:::::::::L                           A:::A              B::::::::::::::::B      //
//    I::::::::I CC:::::::::::::::CE::::::::::::::::::::EL:::::::::L                          A:::::A             B::::::BBBBBB:::::B     //
//    II::::::IIC:::::CCCCCCCC::::CEE::::::EEEEEEEEE::::ELL:::::::LL                         A:::::::A            BB:::::B     B:::::B    //
//      I::::I C:::::C       CCCCCC  E:::::E       EEEEEE  L:::::L                          A:::::::::A             B::::B     B:::::B    //
//      I::::IC:::::C                E:::::E               L:::::L                         A:::::A:::::A            B::::B     B:::::B    //
//      I::::IC:::::C                E::::::EEEEEEEEEE     L:::::L                        A:::::A A:::::A           B::::BBBBBB:::::B     //
//      I::::IC:::::C                E:::::::::::::::E     L:::::L                       A:::::A   A:::::A          B:::::::::::::BB      //
//      I::::IC:::::C                E:::::::::::::::E     L:::::L                      A:::::A     A:::::A         B::::BBBBBB:::::B     //
//      I::::IC:::::C                E::::::EEEEEEEEEE     L:::::L                     A:::::AAAAAAAAA:::::A        B::::B     B:::::B    //
//      I::::IC:::::C                E:::::E               L:::::L                    A:::::::::::::::::::::A       B::::B     B:::::B    //
//      I::::I C:::::C       CCCCCC  E:::::E       EEEEEE  L:::::L         LLLLLL    A:::::AAAAAAAAAAAAA:::::A      B::::B     B:::::B    //
//    II::::::IIC:::::CCCCCCCC::::CEE::::::EEEEEEEE:::::ELL:::::::LLLLLLLLL:::::L   A:::::A             A:::::A   BB:::::BBBBBB::::::B    //
//    I::::::::I CC:::::::::::::::CE::::::::::::::::::::EL::::::::::::::::::::::L  A:::::A               A:::::A  B:::::::::::::::::B     //
//    I::::::::I   CCC::::::::::::CE::::::::::::::::::::EL::::::::::::::::::::::L A:::::A                 A:::::A B::::::::::::::::B      //
//    IIIIIIIIII      CCCCCCCCCCCCCEEEEEEEEEEEEEEEEEEEEEELLLLLLLLLLLLLLLLLLLLLLLLAAAAAAA                   AAAAAAABBBBBBBBBBBBBBBBB       //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ICELAB is ERC721Creator {
    constructor() ERC721Creator("ICELAB", "ICELAB") {}
}
