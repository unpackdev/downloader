
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: X Domains Group
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                       `sdmNNNMMNh-                                                                                                                           //
//                       oMMMMMMMMMMN`                                       `                                                                                  //
//                       dMMMMMMMMMMM+                                  `/ohmm`                                                                                 //
//                       NMMMMMMMMMMMN`                               `oNMMMMMmddddd:                                                                           //
//                      `MMMMMMMMMMMMM+                              .dMMMMMhMhoMMMd                                                                            //
//                      `MMMMMMMMMMMMmd                             :mMMMMM+`+` hMN-                                                                            //
//                      -MMMMMMMMmhMMyo.                          `oNMMMMN/    .mM+                                                                             //
//                      -MMMMMMMMN.NMo `                         .hMMMMNo.    :mM+                                                                              //
//                      -MMMMMMMMM:oy`                          /mMMMMM/    `+NN/                                                                               //
//                      .MMMMMMMMMs                           `sMMMMMMm    .yMm:                                                                                //
//                      `MMMMMMMMMm`+/`                      -dMMMMNh/`   -mMh.                                                                                 //
//                      `MMMMMMMMMM-MM+                    `+NMMMMm:     +NNo                                                                                   //
//                       NMMMMMMMMM+hMh                   .hMMMMMh`    `yMm:                                                                                    //
//                       dMMMMMMMMMhsMM-                 :NMMMMMo     -mMh`                                                                                     //
//                       yMMMMMMMMMMMMMh                sMMMMMM/     +NMo                                                                                       //
//                       oMMMMMMMMMMMMMM`             .dMMMMMN-    `yMN:                                                                                        //
//                       :MMMMMMMMMMMhMM+            +NMMMMMy.    .dMd.      `                                                                      `           //
//                       `MMMMMMMMMMMy+Md          `yMMMMMMMddhhyyNMy`  -sdNNNNmho.  +hhhhhhs  /hhhhhhh    yhhhhhhh.   -hhhhho yhhhhh/ :hhhhh  `+hmNNNNmy/`     //
//                        dMMMMMMMMMMMosN         -dMMMMMMMMMMMMMMMMo  oNMMMMMMMMMN- sMMMMMMN  yMMMMMMN   `MMMMMMMM/   :MMMMMh NMMMMMh :MMMMM .mMMMMMMMMMMm-    //
//                        oMMMMMMMMMMMMd+        +NMMMNmMMMMMMMMMMMMM:-MMMMMMMMMMMMm sMMMMMMM` dMMMMMMN   :MMMMMMMMs   :MMMMMh NMMMMMN :MMMMM sMMMMMMMMMMMMd    //
//                        .MMMMMMMMMMMMMN:     `yMMMMMs`mMMMMMMMMMMMMs/MMMMMy:mMMMMM`sMMMMMMM: NMMMMMMN   oMMMMMMMMd   :MMMMMh NMMMMMM--MMMMM hMMMMMy:NMMMMM    //
//                         dMMMMMMMMMMMMN:    -dMMMMMN.`mMMMMMMhMMMMMs/MMMMM: yMMMMM.sMMMMMMM+.MMMMMMMN   hMMMMMMMMN   :MMMMMh NMMMMMM+-MMMMM hMMMMM+ mMMMMM    //
//                         /MMMMMMMMMMMdNN-  +NMMMMNy+`hMMMMMM+-MMMMMs/MMMMM: sMMMMM.sMMMMMMMs:MMMMMMMN   NMMMMmMMMM-  :MMMMMh NMMMMMMh.MMMMM hMMMMM+ dMMMMM    //
//                         `NMMMMMMMMMMm:Mm-yMMMMMm/dhdymMMMMN .MMMMMs/MMMMM: sMMMMM.sMMMMMMMh+MMMMMMMN  .MMMMNhMMMM+  :MMMMMh NMMMMMMN.MMMMM hMMMMM+ hMMMMM    //
//                          oMMMMMMMMMMM:dMNMMMMMM+mMMM+NMMMMN .MMMMMs/MMMMM: sMMMMM.sMMMMMMMmsMMMMMMMN  /MMMMdsMMMMy  :MMMMMh NMMMMMMM-MMMMM hMMMMMo yNNNNN    //
//                          `NMMMMMMMMMMdNMMMMMMMNmMNdMMMMMMMN .MMMMMs/MMMMM: sMMMMM.sMMMMMMMMdMMMMMMMN  sMMMMh+MMMMm  :MMMMMh NMMMMMMM+MMMMM +MMMMMNo/-....    //
//                           +MMMMMMMMMMMMMMMMMMMMMM+-MMMMMMMN `MMMMMs/MMMMM: sMMMMM.sMMMMMMMMMMMMMMMMN  dMMMMs/MMMMM` :MMMMMh NMMMMNMMhNMMMM  yMMMMMMMms-      //
//                            mMMMMMMMMMMMMMMMMMMMMo.mMmNMMMMN `MMMMMs+MMMMM: sMMMMM.sMMMMdMMMMMMmMMMMN `MMMMMo-MMMMM: :MMMMMh NMMMMhMMNmMMMM   :hNMMMMMMMy`    //
//                            -MMMMMMMMMMMMMMMMMMMy`dMy`mMMMMN `MMMMMsoMMMMM: sMMMMM.sMMMMhMMMMMMyMMMMN -MMMMM/`MMMMMo :MMMMMh NMMMMsMMMMMMMM     `:oNMMMMMy    //
//                             sMMMMMMMMMMMMMMMMMh`hM+  mMMMMN `MMMMMsoMMMMM: sMMMMM.sMMMMymMMMMMoMMMMN +MMMMM- NMMMMh :MMMMMh NMMMM/MMMMMMMM hNNNNm .MMMMMM    //
//                             `mMMMMMMMMMMMMMMMMmdm-   mMMMMN .MMMMMsoMMMMM: sMMMMM.sMMMMyyMMMMM/MMMMN yMMMMMMMMMMMMN :MMMMMh NMMMM:mMMMMMMM hMMMMN `MMMMMM    //
//                              sMMMMMMMMMMMMMMMMMh`    mMMMMN .MMMMMooMMMMM: sMMMMM.sMMMMyoMMMMd/MMMMN mMMMMMMMMMMMMM.:MMMMMh NMMMM:yMMMMMMM dMMMMN `MMMMMM    //
//                             .mMMMMMMMMMMMMMMMMo      mMMMMN .MMMMMooMMMMM: sMMMMM.sMMMMh:MMMMs/MMMMN`MMMMMNmmNMMMMM/:MMMMMh NMMMM//MMMMMMM dMMMMN `MMMMMM    //
//                            :mMMMMMMMMMMMMMMMN/       mMMMMN:oMMMMMo+MMMMMo.dMMMMM`sMMMMh`MMMM/+MMMMN:MMMMMs``:MMMMMs:MMMMMh NMMMM+.MMMMMMM hMMMMM:/MMMMMM    //
//                          `oNMMMMMMMMMMMMMMMm-        mMMMMMNMMMMMM/-MMMMMMNMMMMMm sMMMMh +ooo.oMMMMNoMMMMM:  `MMMMMd:MMMMMh NMMMMo mMMMMMM sMMMMMMNMMMMMm    //
//                         .hMMMMMMMMMMMMMMMMMo         mMMMMMMMMMMMh` yMMMMMMMMMMN/ sMMMMh      oMMMMNhMMMMM`   mMMMMN:MMMMMh NMMMMo yMMMMMM .mMMMMMMMMMMN/    //
//                        /mMMMMMMMMMMMMMMMMMMy         hmmmmmmmmdy:`  `+hmNNNNmdy:  ommmmy      /mmmmddmmmmh    smmmmm/mmmmms dmmmm+ /mmmmmm  .odmNNNNmds-     //
//                      `sMMMMMMMMMMMMMMMMMMMMM:        `.......``        ..--..`    ``````      ````````````    `.....`.....` ``````  ......     ..---.`       //
//                     -dMMMMMMMMMMMMMMMMMMMMMMm`                                     `......`    `````````         ..---.`    ``````  `````` `````````         //
//                    /NMMMMMMMMMmhhMMMMMMMMMMMMy                                   :ymNNNNNmdo`  dddddddddhy/`  `/hmNMMMNdy-  yddddd `mmmmms dddmmmmddhs:`     //
//                  `sMMMMMMMMMMM.  yMMMMMMMMMMMM:                                 oMMMMMMMMMMMd``MMMMMMMMMMMMd.`hMMMMMMMMMMN/ dMMMMM``MMMMMh MMMMMMMMMMMMy`    //
//                 .dMMMMMMMMMMNh.  sNMMMMMMMMMMMm`                               `MMMMMMNMMMMMM:`MMMMMMMMMMMMMy/MMMMMMNMMMMMm dMMMMM``MMMMMh MMMMMMMMMMMMM+    //
//                /NMMMMMMMMMMMs   .-.yMMMMMMMMMMMy                               .MMMMMh./MMMMM+`MMMMMd:sMMMMMdoMMMMM+.mMMMMN dMMMMM``MMMMMh MMMMMd:oMMMMMy    //
//               sMMMMMMMMMmhhs.       +MMMMMMMMMMM/                              -MMMMMo .MMMMMs`MMMMMh :MMMMMdoMMMMM: yMMMMM dMMMMM``MMMMMh MMMMMh .MMMMMh    //
//             .dMMMMMMMMMd`            /MMMMMMMMMMN.                             -MMMMMo .MMMMMs`MMMMMh :MMMMMdoMMMMM- yMMMMM dMMMMM``MMMMMh MMMMMh `MMMMMh    //
//            :NMMMMMMMMMMMd`            :NMMMMMMMMMm`                            -MMMMMo .MMMMMy`MMMMMh :MMMMMdoMMMMM. yMMMMM dMMMMM``MMMMMh MMMMMh `MMMMMh    //
//           oMMMMMMMMMMMm:/-             -NMMMMMMMMMy                            -MMMMMo `-----.`MMMMMh :MMMMMdoMMMMM. yMMMMM dMMMMM``MMMMMh MMMMMh `MMMMMh    //
//         `yMMMMMMMMMMMho                 .mMMMMMMMMMo                           -MMMMMo.::::::.`MMMMMh`+MMMMMhoMMMMM- yMMMMM`dMMMMM``MMMMMh MMMMMh -MMMMMy    //
//        .dMMMMMMMMMMMM:                   .dMMMMMMMMM+                          -MMMMMo+MMMMMM+`MMMMMMNNMMMMm-oMMMMM- yMMMMM.dMMMMM``MMMMMh MMMMMNdNMMMMMs    //
//       .mMMMMMMMMMMMy-                     `hMMMMMMMMN/                         -MMMMMo+MMMMMMo`MMMMMMMMMMMy. oMMMMM. yMMMMM.dMMMMM``MMMMMh MMMMMMMMMMMMm.    //
//      .mMMMMMMMMMMm:                        `yMMMMMMMMNo`                       -MMMMMo.+MMMMMo`MMMMMNmMMMMNh oMMMMM. yMMMMM.dMMMMM``MMMMMh MMMMMMMMMNds.     //
//     `dMMMMMMMMMMN-  `:                      `oMMMMMMMMMd:                -o    -MMMMMo .MMMMMo`MMMMMh.hMMMMM-oMMMMM. yMMMMM.dMMMMM``MMMMMh MMMMMd---.`       //
//     sMMMMMMMMMMMs .+dy                        +NMMMMMMMMNh:             /No    -MMMMMo .MMMMMo`MMMMMh sMMMMM:oMMMMM. yMMMMM.dMMMMM``MMMMMh MMMMMh            //
//    -MMMMMMMMMMMMosmN+                          :mMMMMMMMMMNy:`        .yMM.    -MMMMMo .MMMMMo`MMMMMh sMMMMM/oMMMMM. yMMMMM.dMMMMM``MMMMMh MMMMMh            //
//    sMMMMMMMMMMMMMMh.                            .yNMMMMMMMMMMh:````.-smMMs     .MMMMMo .MMMMMo`MMMMMh sMMMMM/oMMMMM. yMMMMM dMMMMM``MMMMMh MMMMMh            //
//    mMMMMMMMMMMMMN+                                :hNMMMMMMMMMMmdhdmMMMNs`     .MMMMMd:oMMMMMo`MMMMMh sMMMMM/oMMMMMo:mMMMMM yMMMMM/+MMMMMy MMMMMh            //
//    MMMMMMMMMMMMh.                                   -smMMMMMMMMMMMMMMNh:        dMMMMMMMMMMMMo`MMMMMh sMMMMM/:MMMMMMMMMMMMh +MMMMMMMMMMMM/ MMMMMh            //
//    mMMMMMMMMMN+                                       `/smNMMMMMMNNh+.          -mMMMMMMMdMMMo`MMMMMh sMMMMM+ sMMMMMMMMMMm- `hMMMMMMMMMMh` MMMMMh            //
//    /NMMMMMMMd.                                            `-////:.               `odNMNms-hhh/ hhhhho +hhhhh/  :sdNNNNmh+`    /ymNNNNmy/   hhhhho            //
//     .ohNMMd+                                                                         `                                                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XDs is ERC721Creator {
    constructor() ERC721Creator("X Domains Group", "XDs") {}
}
