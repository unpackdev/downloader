
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black Wixa
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                             .                                                //
//                                   iir.                                                                                       //
//                                .tIrWtIrw.                                                                                    //
//                                iR rWWARiTE.      .                                                                           //
//                                AT.TRiTER.TW.   rrIri                                                                         //
//                               TW rRTr.TAR iW iWiAAarIr.                                                                      //
//                  i.          iW..RwT..iaWT W.RT WRWR EW                                                                      //
//                iwTITT       .Wi.RaT...irEW. Rt IRrWW TR                                                                      //
//              IErTREiiR.     .R iWEri...rTRA.Ir RITaR wW                                                                      //
//              WW RWaETiE.r.irR..WWri i...TtR.. RETrRW TR                                                                      //
//              AW.TRTrwRTtTITIr  RTr...i.irRWi RWI.TAR tW      rrti.                                                           //
//               TW.iRtr.IARERAWTwWWrr...irEW. rWRrirRW TR    TtiAtTTI                                                          //
//        rTI.    iTirEAtii . irIARWEri .iIWT rWRiirWW iR   TrAiaWRr Ww                                                         //
//     .raTEiTA.     i.TrTWw.. . rTRWWr..aERIWET...wAR rIriITItWrwWw Rr                                                         //
//     iR wWWrwrTrTrr.TAt tWEi. . rrWWWTRWRaAi. . irRI .wTAARwT.TWR.tA.                                                         //
//     iWr.RAAIATAtEtwirTt rWEri...rTRWRAT.. . . rTRWAwRaWwi.rrAAAiri  i                                                        //
//      .ETiWattATtrwARAWri wWAii...rTREIi. ....rwRWWTI.. ..EWA.T.i...TTtr.                                                     //
//         riTiIrATr.. .rRWWrRIw...irAWRTr.. ..aERWt.. . iTRTriTrr.TrtwRETrR                                                    //
//          tEI.rrArRIi . rTRWRrr . irEWRrr irRWRTr.....TARr.AR.rrAaWtIWR tW.                                                   //
//       rrTr.iE .rrrRWt.. iiAWRIT.. rTRWRrTIRWWri ....TAR.iITiAARwr.wWE AA                                                     //
//     .RiTERI.iE  rI aWEi. . rTRWWri .iAERWRwr.......rwRr...wRTi ..IWI ET                                                      //
//     TW TRrIatrT..TW TWWi..TwWIRWRaT  .IWRTr ..i..iaAREi .EWi. .iAWT Ri                                                       //
//      Ww.IRirTRatrrrI rWRTTwRWArTwRWAiTARtT...i..iIARwWW.TRri ..TTRi WT.TrT.                                                  //
//      .RiiWRii.TARaErT iTrwtrWAt...EWRIRAIi..i.. rTWWarWWRri . irREi riwTITwTT                                                //
//        ErTwRIi ..TrREREErWWRTWWAi..tARWRTr.... irWWWrTIRat.. irRW. tIWwEaRWtrRT                                              //
//          .TiTWWi. . .iriETIERAREIi. rtRWEri . rTRWWrTwRIw.. irRAriRATiTtRTtTw..                                              //
//          irW.TARwi . . . . irAtRAai. irWWWriiWWRAT irWWAii.wWRTAAWi.iaWr Ar.                                                 //
//       TTwriiTi..EWEi. ..... .iIERwT...TwREIARWEi. irAEETAERWREWTi ..TER rW                                                   //
//     .RWRERtITwri .WRTr...i.i..iAERwT...TtRERTi . ..tIRWRWRITii.. ..TAR .W.                                                   //
//       tTTrRWITEAA. WRTi ..i.. rTRWEri irAWWTr ....TwRAIir.. . . . TAR..Wi                                                    //
//         Ta AWw.iTRatTRwr.... rTRWWTi...TwRAIi..i.rTWWAri ..... rraEA..iEri                                                   //
//          TA IWAi..wAWTAIT.. rTRWRrr.. .iaWWTr ...iIIRtw.... .iWWRTi rTwrwrwr.                                                //
//           IW EWAi. rTEwRWIiIWRAT.....rrEAREAii ..TTWWAri ..wAWr. TARtItRWRArAR                                               //
//           EA IRTr.. .iAARIaWRTr ..i.iTEWRTWWEri ..TwREI.irWaw.rwRtr.rTErwTATT.                                               //
//           ER RWIi..i...tARERwT...i.i.TtRETrRWWTr ..TTRAAWRWAERAA...aWI.ATw.                                                  //
//           rEi.RaT...i...TIRWAri i.i.irAWRTirRWRTi .iAWRWRITri.. .iWWT Ri                                                     //
//            IW rRIT...i...TtRWIi. ....TTRWaiirEWRTTARWAir.. . . irRWi.R.                                                      //
//             wW.iRaT...i...rTRWRTi . irEWRTr .iAWRWRTi . ... . itREriR.                                                       //
//              iWr.RWw...... ..wAREt.irEWRTr.. irAWWri ..... .iEWETtri                                                         //
//               .TTrEEWi... . ..wERWRARWRTr . ..TIRAIi. . iiTARtITr                                                            //
//                  rrITRERTtrtrtwRWRTaww.. . ..rIREAii i.aERAATT.                                                              //
//                    .TTaTRAWaWIArwwArIii.r.IIWEW AIaTAERaITtr.                                                                //
//                      .rTTITtTIrTrtTATWERERIETtrwrAwAwITIi.                                                                   //
//                                  .TTwraTITwTri. irwrw.i                                                                      //
//                                      ....i                                                                                   //
//                                                                                                                              //
//                                                                   Tatewari                                                   //
//                                                                   @WixarikaNFT                                               //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BWIXA is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
