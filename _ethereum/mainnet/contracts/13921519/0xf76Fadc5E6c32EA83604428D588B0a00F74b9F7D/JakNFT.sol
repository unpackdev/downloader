
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JakNFT Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                    ````.`......... `.`.-.--.                                                   //
//                              /:                   -NMMMMNMMMMMMMMMNmMNMMMMMMNNN:                                               //
//                             `MMo                 .NMMMMMMMMMMMMMMMMMMMMMMMMMMMm`-..hdhhyyyys+/+++++ooooossssssssymNmhs.        //
//                           ``.MMN.               -hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm.       //
//                          -mmmMMMmoyo.         -dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy       //
//                          sMMMMMMMMMMdo+o/o/o+sNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm       //
//                          yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.      //
//                          yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.      //
//                          yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`      //
//                         `hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN       //
//                        :hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm       //
//                       /NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd       //
//                      :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMs       //
//                     .NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh        //
//                     hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo        //
//                    -MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM/        //
//                    +MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM:        //
//                    oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.        //
//                    +MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN         //
//                    /MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd         //
//                    .NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy         //
//                     oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm..dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM+         //
//                      sMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMs  /MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM:         //
//                      `yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo:`  /MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`         //
//                        dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm`    +MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN          //
//                        oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM/     +MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh          //
//                        .NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmMMMMMMMMMMN`     oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMs          //
//                         oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMhMMMMMMMMMMm      /NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM+          //
//                          sMMMMMMMMMMMMMMMMMMMMNMmNdNMMMMMMMMMMMmMMMMMMMMMMN        yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM-          //
//                           /mMMMMMMMMMNNmddss/+.-`` +MMMMMMMMMMMNMMMMMMMMMMM:       hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNh           //
//                            `++ooh/o-:.``           `NMMMMMMMMMhNMMMMMMMMMMMh       hMMMMMMMMMMMMMMMMMMMMMMMMms+/:.`            //
//                                                     sMMMMMMMMdyMMMMMMMMMMMMM.      mMMMMMMMMMMMMMMMMMNmhs/-`                   //
//                                               .oo/  .MMMMMMMy+/MMMMMMMMMMMMM+      NMMMMMMMMMMMMMMMMm.                         //
//              hs  /     /+   : .y/  +m`` ./ooodNMMm   dMMMMMMy.`yMMMMMMMMMMMMy     `MMMMMMMMMMMMMy`-:`                          //
//             :Mm .M+    dd  +m oMy  hM:mdNMMMMMMMMd   oMMMMMMh` :hMMMMMMMMMMMd     `MMMMMMMMMMMMMo                              //
//             +Md :Mh   .MN -Ny hMh  mM/MMMMMMMMMMMM`  :MMMMMMd. `sMMMMMMMMMMMm     :MMMMMMMMMMMMM+                              //
//             sMy +Md   /Mm`mMd mMd  NM:MMMMMMMMMMMm-  `NMMMMMM/ `yMMMMMMMMMMMm     /MMMMMMMMMMMMM:                              //
//             hMo yMm   yMhyMMh`MMm `Mm/MMMmNMMMMh/.    dMMMMMMo .sMMMMMMMMMMMM`    oMMMMMMMMMMMMM.                              //
//             NM: mMN   mMmMMN.-MMM -Mh+Mm-`sMdMM-      oMMMMMMy  -NMMMMMMMMMMM:    yMMMMMMMMMMMMM                               //
//            `MM.`MMM  `MMMMMo +MMM`/MssMs  `:.MM`      :MMMMMMh`` mMMMMMMMMMMM+    dMMMMMMMMMMMMm                               //
//            -MN :MMM` :MMMMd  sMNM-+M+hM+    :MN       `NMMMMMN.` hMMMMMMMMMMMo    MMMMMMMMMMMMMh                               //
//            +Md oMMM` oMMMN-  dMyM/yM:mM/`   +Mh        dMMMMMM/  oMMMMMMMMMMMs   .MMMMMMMMMMMMMs                               //
//            yMy hMdM:/hMMMh   NM/MsdM-MMmy   yMo        oMMMMMMy  +MMMMMMMMMMMy   /MMMMMMMMMMMMM+                               //
//            dM+ NMsMMMMMMMh  .Md.MhNM-MMMm`  mM/        :MMMMMMd  +MMMMMMMMMMMy   sMMMMMMMMMMMMM-                               //
//        /: `MM-:MMmMMMMMMMd  /My`MNMm/MMMM+ `MM.        `MMMMMMN. :NMMMMMMMMMMh   dMMMMMMMMMMMMM`                               //
//       .ds -MM`oMMMMMMMMyMm  oM+ mMMhsMMMm. -MN          dMMMMMM- omMMMMMMMMMMd  `MMMMMMMMMMMMMm                                //
//       :My oMm dMMMMNdMN`MN  hM: hMMshMMh`  +Md          sMMMMMMo.omMMMMMMMMMMd  :MMMMMMMMMMMMMy                                //
//       /Ms hMs`MMMMMhhMo NM` mM` sMM/NM+    yMs          :MMMMMMd/oNMMMMMMMMMMd  oMMMMMMMMMMMMM+                                //
//       +Mo`NM//MMN:MdmM: dM.`MN  /MM/MM.    dM/          `MMMMMMNohMMMMMMMMMMMy  dMMMMMMMMMMMMM-                                //
//       oMo:MM`yMN- NNMM` hM--Mh  -MM/MN     NM-           mMMMMMMomMMMMMMMMMMMo `NMMMMMMMMMMMMM`                                //
//       oM+sMd NMo  dMMd  yM-/Ms  .MNoMh    .MM`           yMMMMMMmMMMMMMMMMMMM/ :MMMMMMMMMMMMMd                                 //
//       sMsNMo.MM.  hMMo  sM:+M+  -MdyMs    :Mm            :MMMMMMMMMMMMMMMMMms` oMMMMMMMMMMMMMs                                 //
//       oMNMM-.Mm   yMM-  oM/sM:  /MydM/    +My             yMMMMMMMMMMMMNdy/.   hMMMMMMMMMMMMM/                                 //
//       /MMMm  ms   sMd   :M+oM-  /MoNM.    oMo             `+dNMMMMNdyo:.`      NMMMMMMMMMMMMM.                                 //
//       .MMM+  +:   /Ms   `N/-d-  .m+MN     oM/               `-/o+/-`          -MMMMMMMMMMMMMm                                  //
//        hNy   `    `y/    -  ``   `.Nh     .M.                                 +MMMMMMMMMMMMMy                                  //
//        `-`         `.              -/      o                                  -NMMMMMMMMMMMM+                                  //
//                                                                                ./ymNMMMMMMMM-                                  //
//                                                                                   `:odNMMMMN                                   //
//                                                                                       ./oo+:                                   //
//                                                                                                                                //
//    JAKNFT EDITIONS                                                                                                             //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JakNFT is ERC721Creator {
    constructor() ERC721Creator("JakNFT Editions", "JakNFT") {}
}
