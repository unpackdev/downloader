// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑                                   ↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ //
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑     ↑↑↑   ↑↑↑↑↑↑↑↑↑   ↑↑↑     ↑↑↑↑    ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ //
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑   ↑↑   ↑↑↑↑↑ ↑↑↑↑↑  ↑↑    ↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ //
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑    ↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑      ↑↑↑↑   ↑↑↑↑      ↑↑↑↑↑   ↑↑↑↑↑↑↑↑                       ↑↑↑↑↑↑ //
// ↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑     ↑↑↑↑↑ ↑↑↑↑↑    ↑↑↑↑↑    ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑ //
//   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑    ↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑    ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑  //
//     ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑            ↑↑↑↑↑    ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑    //
//       ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑         ↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑      //
//         ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑     ↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑        //
//           ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑   ↑↑↑↑  ↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑          //
//            ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑    ↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑            //
//              ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑    ↑↑↑   ↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑             //
//                ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑       ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑               //
//    ↑↑↑           ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑           ↑↑    //
//    ↑↑↑↑            ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑            ↑↑↑    //
//    ↑↑↑↑              ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑              ↑↑↑    //
//    ↑↑↑↑               ↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑      ↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑               ↑↑↑    //
//                         ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑         ↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑      ↑↑↑↑↑↑     ↑↑↑    //
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑             ↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑      ↑↑↑↑↑↑↑↑↑↑   ↑↑↑    //
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑   ↑↑↑                 ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑        ↑↑↑    ↑↑↑   ↑↑↑    //
//              ↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑  ↑                ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑          ↑↑↑    ↑↑↑   ↑↑↑    //
//                ↑↑↑↑↑↑           ↑↑↑↑↑↑↑↑               ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑            ↑↑↑↑↑↑↑↑↑↑   ↑↑↑    //
//                  ↑↑↑↑↑↑           ↑↑↑↑↑↑↑↑           ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑               ↑↑↑↑↑↑     ↑↑↑    //
//   ↑↑↑↑↑↑           ↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑        ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑                            ↑↑↑    //
// ↑↑↑↑↑↑↑↑↑↑     ↑↑↑↑  ↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑     ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑                 ↑↑      ↑↑   ↑↑↑    //
// ↑↑↑    ↑↑↑     ↑↑↑↑    ↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑           ↑↑↑↑    ↑↑↑    ↑↑↑   ↑↑↑    //
// ↑↑↑    ↑↑↑      ↑↑     ↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑            ↑↑  ↑↑   ↑↑↑    ↑↑↑   ↑↑↑    //
// ↑↑↑↑↑↑↑↑↑↑     ↑↑↑↑       ↑↑          ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑    ↑↑↑↑↑↑↑↑           ↑↑↑↑    ↑↑↑    ↑↑↑   ↑↑↑    //
//   ↑↑↑↑↑↑       ↑↑↑↑                 ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑      ↑↑↑↑↑↑↑↑                 ↑↑↑    ↑↑↑   ↑↑↑    //
//                 ↑↑                ↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑        ↑↑↑↑    ↑↑↑    ↑↑↑   ↑↑↑    //
//     ↑↑↑        ↑↑↑↑              ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑             ↑↑↑↑↑↑↑↑↑    ↑↑  ↑↑          ↑↑↑          //
//    ↑↑↑↑       ↑↑  ↑↑           ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                ↑↑↑↑↑↑↑↑↑   ↑↑↑↑           ↑↑↑          //
//    ↑↑↑↑        ↑↑↑↑          ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                ↑↑  ↑↑↑↑↑↑↑↑          ↑↑↑    ↑↑↑          //
//    ↑↑↑↑                    ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                 ↑↑↑↑   ↑↑↑↑↑↑↑↑        ↑↑↑    ↑↑↑   ↑↑↑    //
//    ↑↑↑↑   ↑↑↑↑           ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑            ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑      ↑↑↑    ↑↑↑   ↑↑↑    //
//    ↑↑↑↑   ↑↑↑↑         ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑        ↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑    ↑↑↑    ↑↑↑   ↑↑↑    //
//    ↑↑↑↑   ↑↑↑↑        ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑    ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑    ↑↑↑   ↑↑↑    //
//    ↑↑↑↑   ↑↑↑↑      ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑       ↑↑↑          //
//    ↑↑↑↑   ↑↑↑↑    ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑ ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑     ↑↑↑          //
//    ↑↑↑↑   ↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑     ↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑    ↑↑↑          //
//    ↑↑↑↑   ↑   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑        ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑   ↑↑   ↑↑↑    //
//    ↑↑↑↑     ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑            ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑      ↑↑↑    //
//    ↑↑↑↑    ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑                ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑    ↑↑↑    //
//    ↑↑↑   ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑                   ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑   ↑↑    //
//        ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑                      ↑↑↑↑↑↑↑↑    ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑       //
//      ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑            ↑↑            ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑      //
//    ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑            ↑↑↑↑↑↑            ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑    //
//  ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑           ↑↑↑↑↑↑↑↑↑↑            ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑  //
// ↑↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑            ↑↑↑↑↑   ↑↑↑↑↑            ↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑ //
// ↑↑↑↑↑↑                       ↑↑↑↑↑↑↑↑            ↑↑↑↑↑       ↑↑↑↑↑           ↑↑↑↑↑↑↑↑↑                       ↑↑↑↑↑ //
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑            ↑↑↑↑↑          ↑↑↑↑↑↑           ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ //
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑            ↑↑↑↑↑    ↑↑↑↑↑↑    ↑↑↑              ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ //
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑           ↑↑↑↑↑      ↑↑↑↑↑↑↑        ↑↑            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ //
//                                          ↑↑↑↑↑↑       ↑↑↑↑↑↑        ↑↑↑↑↑                                          //
//                                         ↑↑↑↑↑  ↑↑↑              ↑↑↑   ↑↑↑↑↑                                        //
//                                       ↑↑↑↑↑    ↑↑↑              ↑↑↑     ↑↑↑↑↑                                      //
//                                        ↑↑                                 ↑↑                                       //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract XchangePFP is ERC721Enumerable, ERC721URIStorage, ReentrancyGuard, Ownable {

    uint256 public setupFee = 0.0025 ether;
    uint256 public xchangeFee = 0.001 ether;
    address payable public teamAddress;

    uint256 private _nextTokenId = 1;

    error InsufficientFunds();
    error InvalidOwner();
    error InvalidSender();

    event Xchanged(uint256 tokenId);
    event ReceivedTip(address indexed sender, uint256 amount);

    constructor(address payable _teamAddress)
    ERC721("XchangePFP", "XPFP")
    Ownable(msg.sender)
    {
        teamAddress = _teamAddress;
    }

    function mint() external payable nonReentrant {
        if (msg.value < setupFee) revert InsufficientFunds();
        _safeMint(msg.sender, _nextTokenId++);
    }

    function xchangeURI(uint256 tokenId, string memory newURI) external payable nonReentrant {
        if (msg.value < xchangeFee) revert InsufficientFunds();
        _xchange(tokenId, newURI);
    }

    function xchangeMETA(uint256 tokenId, string memory name, string memory description, string memory imageURI) external payable nonReentrant {
        if (msg.value < xchangeFee) revert InsufficientFunds();
        _xchange(tokenId, _generateMetadata(name, description, imageURI));
    }

    function _xchange(uint256 tokenId, string memory newURI) private {
        if (ownerOf(tokenId) != msg.sender) revert InvalidOwner();
        _setTokenURI(tokenId, newURI);
        emit Xchanged(tokenId);
    }

    function _generateMetadata(string memory name, string memory description, string memory imageURL) private pure returns (string memory) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "', name, '", "description": "', description, '", "image": "', imageURL, '"}'
        ))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function withdraw() external nonReentrant {
        if(msg.sender != owner() && msg.sender != teamAddress) revert InvalidSender();
        payable(teamAddress).transfer(address(this).balance);
    }

    function setTeamAddress(address payable newAddress) external onlyOwner {
        teamAddress = newAddress;
    }

    function changeSetupFee(uint256 newFee) external onlyOwner {
        setupFee= newFee;
    }

    function changeXchangeFee(uint256 newFee) external onlyOwner {
        xchangeFee = newFee;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }
    
    receive() external payable {
        emit ReceivedTip(msg.sender, msg.value);
    }
}
