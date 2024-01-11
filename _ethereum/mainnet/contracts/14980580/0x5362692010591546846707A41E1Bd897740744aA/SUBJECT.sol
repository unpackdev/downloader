
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SUBJECT V.2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//       SSSSSSSSSSSSSSS UUUUUUUU     UUUUUUUUBBBBBBBBBBBBBBBBB             JJJJJJJJJJJEEEEEEEEEEEEEEEEEEEEEE       CCCCCCCCCCCCCTTTTTTTTTTTTTTTTTTTTTTT     VVVVVVVV           VVVVVVVV         222222222222222        //
//     SS:::::::::::::::SU::::::U     U::::::UB::::::::::::::::B            J:::::::::JE::::::::::::::::::::E    CCC::::::::::::CT:::::::::::::::::::::T     V::::::V           V::::::V        2:::::::::::::::22      //
//    S:::::SSSSSS::::::SU::::::U     U::::::UB::::::BBBBBB:::::B           J:::::::::JE::::::::::::::::::::E  CC:::::::::::::::CT:::::::::::::::::::::T     V::::::V           V::::::V        2::::::222222:::::2     //
//    S:::::S     SSSSSSSUU:::::U     U:::::UUBB:::::B     B:::::B          JJ:::::::JJEE::::::EEEEEEEEE::::E C:::::CCCCCCCC::::CT:::::TT:::::::TT:::::T     V::::::V           V::::::V        2222222     2:::::2     //
//    S:::::S             U:::::U     U:::::U   B::::B     B:::::B            J:::::J    E:::::E       EEEEEEC:::::C       CCCCCCTTTTTT  T:::::T  TTTTTT      V:::::V           V:::::V                     2:::::2     //
//    S:::::S             U:::::D     D:::::U   B::::B     B:::::B            J:::::J    E:::::E            C:::::C                      T:::::T               V:::::V         V:::::V                      2:::::2     //
//     S::::SSSS          U:::::D     D:::::U   B::::BBBBBB:::::B             J:::::J    E::::::EEEEEEEEEE  C:::::C                      T:::::T                V:::::V       V:::::V                    2222::::2      //
//      SS::::::SSSSS     U:::::D     D:::::U   B:::::::::::::BB              J:::::j    E:::::::::::::::E  C:::::C                      T:::::T                 V:::::V     V:::::V                22222::::::22       //
//        SSS::::::::SS   U:::::D     D:::::U   B::::BBBBBB:::::B             J:::::J    E:::::::::::::::E  C:::::C                      T:::::T                  V:::::V   V:::::V               22::::::::222         //
//           SSSSSS::::S  U:::::D     D:::::U   B::::B     B:::::BJJJJJJJ     J:::::J    E::::::EEEEEEEEEE  C:::::C                      T:::::T                   V:::::V V:::::V               2:::::22222            //
//                S:::::S U:::::D     D:::::U   B::::B     B:::::BJ:::::J     J:::::J    E:::::E            C:::::C                      T:::::T                    V:::::V:::::V               2:::::2                 //
//                S:::::S U::::::U   U::::::U   B::::B     B:::::BJ::::::J   J::::::J    E:::::E       EEEEEEC:::::C       CCCCCC        T:::::T                     V:::::::::V                2:::::2                 //
//    SSSSSSS     S:::::S U:::::::UUU:::::::U BB:::::BBBBBB::::::BJ:::::::JJJ:::::::J  EE::::::EEEEEEEE:::::E C:::::CCCCCCCC::::C      TT:::::::TT                    V:::::::V                 2:::::2       222222    //
//    S::::::SSSSSS:::::S  UU:::::::::::::UU  B:::::::::::::::::B  JJ:::::::::::::JJ   E::::::::::::::::::::E  CC:::::::::::::::C      T:::::::::T                     V:::::V           ...... 2::::::2222222:::::2    //
//    S:::::::::::::::SS     UU:::::::::UU    B::::::::::::::::B     JJ:::::::::JJ     E::::::::::::::::::::E    CCC::::::::::::C      T:::::::::T                      V:::V            .::::. 2::::::::::::::::::2    //
//     SSSSSSSSSSSSSSS         UUUUUUUUU      BBBBBBBBBBBBBBBBB        JJJJJJJJJ       EEEEEEEEEEEEEEEEEEEEEE       CCCCCCCCCCCCC      TTTTTTTTTTT                       VVV             ...... 22222222222222222222    //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SUBJECT is ERC721Creator {
    constructor() ERC721Creator("SUBJECT V.2", "SUBJECT") {}
}
