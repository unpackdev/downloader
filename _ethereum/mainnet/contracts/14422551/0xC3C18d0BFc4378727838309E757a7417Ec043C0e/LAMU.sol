
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lamu Life
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//    LLLLLLLLLLL                                 AAA                    MMMMMMMM               MMMMMMMM     UUUUUUUU     UUUUUUUU    //
//    L:::::::::L                                A:::A                   M:::::::M             M:::::::M     U::::::U     U::::::U    //
//    L:::::::::L                               A:::::A                  M::::::::M           M::::::::M     U::::::U     U::::::U    //
//    LL:::::::LL                              A:::::::A                 M:::::::::M         M:::::::::M     UU:::::U     U:::::UU    //
//      L:::::L                               A:::::::::A                M::::::::::M       M::::::::::M      U:::::U     U:::::U     //
//      L:::::L                              A:::::A:::::A               M:::::::::::M     M:::::::::::M      U:::::D     D:::::U     //
//      L:::::L                             A:::::A A:::::A              M:::::::M::::M   M::::M:::::::M      U:::::D     D:::::U     //
//      L:::::L                            A:::::A   A:::::A             M::::::M M::::M M::::M M::::::M      U:::::D     D:::::U     //
//      L:::::L                           A:::::A     A:::::A            M::::::M  M::::M::::M  M::::::M      U:::::D     D:::::U     //
//      L:::::L                          A:::::AAAAAAAAA:::::A           M::::::M   M:::::::M   M::::::M      U:::::D     D:::::U     //
//      L:::::L                         A:::::::::::::::::::::A          M::::::M    M:::::M    M::::::M      U:::::D     D:::::U     //
//      L:::::L         LLLLLL         A:::::AAAAAAAAAAAAA:::::A         M::::::M     MMMMM     M::::::M      U::::::U   U::::::U     //
//    LL:::::::LLLLLLLLL:::::L        A:::::A             A:::::A        M::::::M               M::::::M      U:::::::UUU:::::::U     //
//    L::::::::::::::::::::::L       A:::::A               A:::::A       M::::::M               M::::::M       UU:::::::::::::UU      //
//    L::::::::::::::::::::::L      A:::::A                 A:::::A      M::::::M               M::::::M         UU:::::::::UU        //
//    LLLLLLLLLLLLLLLLLLLLLLLL     AAAAAAA                   AAAAAAA     MMMMMMMM               MMMMMMMM           UUUUUUUUU          //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                   LLLLLLLLLLL                  IIIIIIIIII     FFFFFFFFFFFFFFFFFFFFFF     EEEEEEEEEEEEEEEEEEEEEE                    //
//                   L:::::::::L                  I::::::::I     F::::::::::::::::::::F     E::::::::::::::::::::E                    //
//                   L:::::::::L                  I::::::::I     F::::::::::::::::::::F     E::::::::::::::::::::E                    //
//                   LL:::::::LL                  II::::::II     FF::::::FFFFFFFFF::::F     EE::::::EEEEEEEEE::::E                    //
//                     L:::::L                      I::::I         F:::::F       FFFFFF       E:::::E       EEEEEE                    //
//                     L:::::L                      I::::I         F:::::F                    E:::::E                                 //
//                     L:::::L                      I::::I         F::::::FFFFFFFFFF          E::::::EEEEEEEEEE                       //
//                     L:::::L                      I::::I         F:::::::::::::::F          E:::::::::::::::E                       //
//                     L:::::L                      I::::I         F:::::::::::::::F          E:::::::::::::::E                       //
//                     L:::::L                      I::::I         F::::::FFFFFFFFFF          E::::::EEEEEEEEEE                       //
//                     L:::::L                      I::::I         F:::::F                    E:::::E                                 //
//                     L:::::L         LLLLLL       I::::I         F:::::F                    E:::::E       EEEEEE                    //
//                   LL:::::::LLLLLLLLL:::::L     II::::::II     FF:::::::FF                EE::::::EEEEEEEE:::::E                    //
//                   L::::::::::::::::::::::L     I::::::::I     F::::::::FF                E::::::::::::::::::::E                    //
//                   L::::::::::::::::::::::L     I::::::::I     F::::::::FF                E::::::::::::::::::::E                    //
//                   LLLLLLLLLLLLLLLLLLLLLLLL     IIIIIIIIII     FFFFFFFFFFF                EEEEEEEEEEEEEEEEEEEEEE                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LAMU is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
