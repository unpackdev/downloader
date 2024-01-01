// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The pixlmoji Contract
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//           ;:::::::::::::::-;.             -:::::::-.     .-::::::::-.      -::::::::-.      ;::::::::;                         //
//         ;QMMMMMMMMMMMMMMMMMMMNQ?:       -HMMMMMMMMMN7   !NMMMMMMMMMMNC   !HMMMMMMMMMMN7   .QMMMMMMMMMMO                        //
//         !MMN>>>>>>>>>>>>>>>7?OHMMH>     7MMH>>>>!OMMH   !MMMO>!>>>>$MMQ:CMMN?>>>>>OMMM7   :MMM7>>>>7MMM;                       //
//         !MMN!!!!!!>>>>>>>!::!:!7HMMO    7MMH!!!!:CMMQ    ;$MMH7:!!!!CMMMMM$!:!!:>QMMQ-    :MMM>!!!!7MMM;                       //
//         !MMN!!!!!?MMMMMMMN$>!!!!!NMM!   7MMH!!!!:CMMQ      >NMMO!:!!:7HMN?!!!!!OMMN7      :MMM>!!!!7MMM;                       //
//         !MMN!!!!!?MMN>>>HMMO:!!!:QMMC   7MMH!!!!:CMMQ       .OMMH?!!!!!C>:!!!7HMMO;       :MMM>!!!!7MMM;                       //
//         !MMN!!!!!?MMMNNNMMH7!!!!!NMM>   7MMH!!!!!CMMQ         !HMM$>!!!!!!!>$MMH!         :MMM>!!!!7MMM;                       //
//         !MMN>!>>!>???????7!!!!!>$MMQ.   7MMH>>>>!OMMQ          ;NMMH>>>>>>>$MMM:          :MMM7>>>>?MMM;                       //
//         !MMN>>>>>>>>>>>>>>>7?C$MMMO.    7MMH>>>>>OMMQ         !HMM$7>>>>>>>7OMMM?         :MMM7>77>?MMM;                       //
//         !MMN7777>CNNNNNNNMMMMMN$7;      7MMH7777>OMMQ       ;OMMNC77777O?7777?QMMQ:       :MMM?7777CMMM:;;;;;;;;;;;            //
//         !MMN77777OMMM?7777>!-;          7MMH77777$MMQ      7NMM$?7777CNMNO77?77ONMMC.     :MMM????7CMMMMMMMMMMMMMMMH7          //
//         !MMN????7OMMN                   7MMN????7$MMQ    -QMMHC7????QMMMMMQ????7?QMMH!    :MMM??????CCCCCCCCCCCCC$MMN.         //
//         !MMN????7OMMN                   7MMN????7$MMH   ?MMNO?????CNMMO-OMMNC????7CNMMO.  :MMM??????????????????7OMMN.         //
//         -NMMNNNNNMMM$                   !MMMNNNNNMMMC   QMMMNNNNNNMMN>   >NMMNNNNNNMMMN-  ;NMMNNNNNNNNNNNNNNNNNNNMMM$          //
//          .!7777777>:                     ;!7777777>-     :>7777777>!.     .!777777777!.    .!777777777777777777777>:           //
//             ........;;        .;;;;;;;;;.             .;-:!!>>>!!-;.                        ........       ........            //
//          :QNMMMMMMMMMMNC.   7HMMMMMMMMMMNQ!       .!CQNMMMMMMMMMMMMMN$?-                  ?HMMMMMMMMHC   7HMMMMMMMMNC.         //
//          $MMHOOOOOOOONMM?  !MMMOOOOOOOOQMMH     -CNMMNQOOCC?????CCO$QNMMH7.              ;MMM$OOOOOMMM: .MMM$OOOOOMMM:         //
//          $MMQ????????OMMM; HMMQ????????$MMH   .CMMM$C?????CCOOCCC?????OQMMN>             ;MMMC????CMMM: .NMMO????CMMM:         //
//          $MMQ????CO???HMMO7MMNC??CC?CC?$MMH  .QMMHC??C?C$NMMMMMMMH$C?C??ONMMC            ;MMMO?CCCCMMM: .NMMO?CCCCMMM:         //
//          $MMQ?CCCCHCCCCMMMMMM$?CCHOCCC?$MMH  OMMHCCCCCOMMMC!-;->QMMHCCCCCCMMM>           ;MMMOCCCCCMMM: .NMMOCCCCCMMM:         //
//          $MMQCCCCCM$CCCQMMMMHCCCOMOCCCC$MMH ;MMMOCCCCCMMM>       $MMHCCCCCQMMQ           ;MMMOCCCCCMMM: .NMM$CCCCCMMM:         //
//          $MMQCCCCOMMCCCCNMMMOCCCNMOCCCC$MMH !MMMCCCCC$MMN.       !MMMCCCCC$MMN..;-;;;-;; .MMMOCCCCOMMM: .NMM$CCCCCMMM:         //
//          $MMQCCCCOMMQCCC$MMHCCC$MMOCCCCQMMH :MMMOCCCCOMMM;       7MMNCCCCC$MMMONMMMMMMMMH?MMMOCCCCOMMM: .NMM$CCCCOMMM:         //
//          $MMHCCCCOMMMOCCCNMOCCOMMM$CCCCQMMH .NMM$CCCCCHMM$;     :NMMQCOOOCHMMNMMM$$$$OHMMMMMM$COOOOMMM: .NMM$COOOOMMM:         //
//          $MMHCOOOOMMMHCOO$QCOCQMMM$OOOCQMMH  >MMM$COOOOHMMM$CCOQMMN$OOOOCQMMN:NMM$COOC$MMMMMMOOOOOOMMM- .NMM$OOOOOMMM:         //
//          $MMHOOOOOMMMM$OOOOOOOMMMM$OOOOQMMH   >MMMQOOOOOO$HNNNNNQ$OOOOOOHMMH- CMMNOOOOOQHNNHQOOOOOHMMH  .NMM$OOOOOMMM:         //
//          $MMHOOOOOMMMMNOOOOOOHMMMM$OOOOQMMH    -OMMMH$OOOOOOOOOOOOOOO$HMMN?.   $MMN$OOOOOOOOOOOO$HMMH-  .NMM$OOOOOMMM!         //
//          CMMMNNNNNMMMMMNNNNNNMMMMMNNNNNMMM$      -?HMMMNNHQQQQQQHHNMMMMQ>.      >QMMMNHHQQQQHHNMMMH7.    HMMNNNNNNMMM-         //
//           >COOOOOOO?:7OOOOOOOO7:7OOOOOOOC>.         ;!?OQHNNNNNNHH$C7:.           ->C$QHNNNNHQ$C>-       ;7OOOOOOOO?-          //
//                                                             ...                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PIXLMOJI is ERC1155Creator {
    constructor() ERC1155Creator("The pixlmoji Contract", "PIXLMOJI") {}
}
