
      // SPDX-License-Identifier: MIT
      pragma solidity ^0.8.18;
      import "./SevenArtProxy.sol";
      
       
// 
// 
//                                                                                                                                                                                                                                                                                                                
//                                                                                                                                                                                                                                                                                                                
// 77777777777777777777   AAA               RRRRRRRRRRRRRRRRR   TTTTTTTTTTTTTTTTTTTTTTT     PPPPPPPPPPPPPPPPP   HHHHHHHHH     HHHHHHHHH     OOOOOOOOO     TTTTTTTTTTTTTTTTTTTTTTT     OOOOOOOOO     VVVVVVVV           VVVVVVVVEEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRR      SSSSSSSSSSSSSSS EEEEEEEEEEEEEEEEEEEEEE
// 7::::::::::::::::::7  A:::A              R::::::::::::::::R  T:::::::::::::::::::::T     P::::::::::::::::P  H:::::::H     H:::::::H   OO:::::::::OO   T:::::::::::::::::::::T   OO:::::::::OO   V::::::V           V::::::VE::::::::::::::::::::ER::::::::::::::::R   SS:::::::::::::::SE::::::::::::::::::::E
// 7::::::::::::::::::7 A:::::A             R::::::RRRRRR:::::R T:::::::::::::::::::::T     P::::::PPPPPP:::::P H:::::::H     H:::::::H OO:::::::::::::OO T:::::::::::::::::::::T OO:::::::::::::OO V::::::V           V::::::VE::::::::::::::::::::ER::::::RRRRRR:::::R S:::::SSSSSS::::::SE::::::::::::::::::::E
// 777777777777:::::::7A:::::::A            RR:::::R     R:::::RT:::::TT:::::::TT:::::T     PP:::::P     P:::::PHH::::::H     H::::::HHO:::::::OOO:::::::OT:::::TT:::::::TT:::::TO:::::::OOO:::::::OV::::::V           V::::::VEE::::::EEEEEEEEE::::ERR:::::R     R:::::RS:::::S     SSSSSSSEE::::::EEEEEEEEE::::E
//            7::::::7A:::::::::A             R::::R     R:::::RTTTTTT  T:::::T  TTTTTT       P::::P     P:::::P  H:::::H     H:::::H  O::::::O   O::::::OTTTTTT  T:::::T  TTTTTTO::::::O   O::::::O V:::::V           V:::::V   E:::::E       EEEEEE  R::::R     R:::::RS:::::S              E:::::E       EEEEEE
//           7::::::7A:::::A:::::A            R::::R     R:::::R        T:::::T               P::::P     P:::::P  H:::::H     H:::::H  O:::::O     O:::::O        T:::::T        O:::::O     O:::::O  V:::::V         V:::::V    E:::::E               R::::R     R:::::RS:::::S              E:::::E             
//          7::::::7A:::::A A:::::A           R::::RRRRRR:::::R         T:::::T               P::::PPPPPP:::::P   H::::::HHHHH::::::H  O:::::O     O:::::O        T:::::T        O:::::O     O:::::O   V:::::V       V:::::V     E::::::EEEEEEEEEE     R::::RRRRRR:::::R  S::::SSSS           E::::::EEEEEEEEEE   
//         7::::::7A:::::A   A:::::A          R:::::::::::::RR          T:::::T               P:::::::::::::PP    H:::::::::::::::::H  O:::::O     O:::::O        T:::::T        O:::::O     O:::::O    V:::::V     V:::::V      E:::::::::::::::E     R:::::::::::::RR    SS::::::SSSSS      E:::::::::::::::E   
//        7::::::7A:::::A     A:::::A         R::::RRRRRR:::::R         T:::::T               P::::PPPPPPPPP      H:::::::::::::::::H  O:::::O     O:::::O        T:::::T        O:::::O     O:::::O     V:::::V   V:::::V       E:::::::::::::::E     R::::RRRRRR:::::R     SSS::::::::SS    E:::::::::::::::E   
//       7::::::7A:::::AAAAAAAAA:::::A        R::::R     R:::::R        T:::::T               P::::P              H::::::HHHHH::::::H  O:::::O     O:::::O        T:::::T        O:::::O     O:::::O      V:::::V V:::::V        E::::::EEEEEEEEEE     R::::R     R:::::R       SSSSSS::::S   E::::::EEEEEEEEEE   
//      7::::::7A:::::::::::::::::::::A       R::::R     R:::::R        T:::::T               P::::P              H:::::H     H:::::H  O:::::O     O:::::O        T:::::T        O:::::O     O:::::O       V:::::V:::::V         E:::::E               R::::R     R:::::R            S:::::S  E:::::E             
//     7::::::7A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R        T:::::T               P::::P              H:::::H     H:::::H  O::::::O   O::::::O        T:::::T        O::::::O   O::::::O        V:::::::::V          E:::::E       EEEEEE  R::::R     R:::::R            S:::::S  E:::::E       EEEEEE
//    7::::::7A:::::A             A:::::A   RR:::::R     R:::::R      TT:::::::TT           PP::::::PP          HH::::::H     H::::::HHO:::::::OOO:::::::O      TT:::::::TT      O:::::::OOO:::::::O         V:::::::V         EE::::::EEEEEEEE:::::ERR:::::R     R:::::RSSSSSSS     S:::::SEE::::::EEEEEEEE:::::E
//   7::::::7A:::::A               A:::::A  R::::::R     R:::::R      T:::::::::T           P::::::::P          H:::::::H     H:::::::H OO:::::::::::::OO       T:::::::::T       OO:::::::::::::OO           V:::::V          E::::::::::::::::::::ER::::::R     R:::::RS::::::SSSSSS:::::SE::::::::::::::::::::E
//  7::::::7A:::::A                 A:::::A R::::::R     R:::::R      T:::::::::T           P::::::::P          H:::::::H     H:::::::H   OO:::::::::OO         T:::::::::T         OO:::::::::OO              V:::V           E::::::::::::::::::::ER::::::R     R:::::RS:::::::::::::::SS E::::::::::::::::::::E
// 77777777AAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR      TTTTTTTTTTT           PPPPPPPPPP          HHHHHHHHH     HHHHHHHHH     OOOOOOOOO           TTTTTTTTTTT           OOOOOOOOO                 VVV            EEEEEEEEEEEEEEEEEEEEEERRRRRRRR     RRRRRRR SSSSSSSSSSSSSSS   EEEEEEEEEEEEEEEEEEEEEE
//                                                                                                                                                                                                                                                                                                                
//                                                                                                                                                                                                                                                                                                                
//                                                                                                                                                                                                                                                                                                                
//                                                                                                                                                                                                                                                                                                                
//                                                                                                                                                                                                                                                                                                                
//                                                                                                                                                                                                                                                                                                                
//                                                                                                                                                                                                                                                                                                                
// 
// 
// 
      
      contract SevenARTPhotoverse is SevenArtProxy {
        constructor(
            address _sevenArtBase1155Slim,
            address sevenArt
        ) SevenArtProxy(_sevenArtBase1155Slim, sevenArt) {}
      }
      