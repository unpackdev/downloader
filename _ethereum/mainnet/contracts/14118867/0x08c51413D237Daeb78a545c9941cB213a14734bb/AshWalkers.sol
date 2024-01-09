
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ash walkers by Mwan
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                          ``                                                                                              ``              //
//              yddd.    .sdmmmh:  ddd`   odd/    `hdd.   ydd`  `hdd.  `hddd`    +dd+    :dds  :ddd/ `dddddd+ odddddh+`  `+dmmmd+           //
//             oMMMMh    dMMy/os`  NMM`   sMM+     oMMy  +MMMy  +MMy   sMMMMy    oMMo    /MMh`sNMh-  .MMNooo: yMMy+hMMy  oMMd/+y.           //
//            :NMdsMMo   dMMds+:`  NMMssssmMM+     `mMM-.NMNMM-`NMN.  /MMhyMM+   oMMo    /MMmdMN+`   .MMNooo. yMMs-sMMh  sMMNyo:`           //
//           `mMM/-NMM:  .+ydmMMh` NMMddddNMM+      :MMhyMN-NMdsMM+  .NMM:-NMN-  oMMo    /MMNNMN/    .MMMddd- yMMNNMNo.  `/shmMMm-          //
//           hMMNmmNMMm` :/../MMM. NMM`   sMM+       hMMMM+ /MMMMd  `dMMNmmNMMd` oMMs--- /MMh-hMMy-  .MMN---` yMMshMNo`  .+-.:mMM/          //
//          +NNh----sNNy.dNNmNNm+  NNN`   sNN+       -NNNh   hNNN-  oNNy----yNNo oNNNNNN./NNy `oNNm+ .NNNNNN+ sNN+`sNNh- yNNmNMNy`          //
//          ---`    `--- `-:/:-`   ---    .--.        ---.   .---   ---`    `--- .------ `--.   .---` ------. .--`  ---- `-://:.            //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                       `                          `                                                       //
//                                                     /mNo`                      `oNd/                                                     //
//                                                   /dMMMMm+`                  `oNMMMMd/                                                   //
//                                                 /dMMMMMMMMm+`              `+mMMMMMMMMd:                                                 //
//                                               :dMMMMMMMMMMMMm+`          `+mMMMMMMMMMMMNh:                                               //
//                                             :hMMMMMMMMMMMMMMMMd/`      `+mMMMMMMMMMMMMMMMNh:                                             //
//                                           :hNMMMMMMMMMMMMMMMMMMMd/`  `/dMMMMMMMMMMMMMMMMMMMNy-                                           //
//                                         -yNMMMMMMMMMMMMMMMMMMMMMMMd:/dMMMMMMMMMMMMMMMMMMMMMMMNy-                                         //
//                                        .hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh`                                        //
//                                         `/mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd/`                                         //
//                                           `+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm/`                                           //
//                                             `+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm+`                                             //
//                                               `oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm+`                                               //
//                                                 `oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo`                                                 //
//                                                   `oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo`                                                   //
//                                                     -NMMMMMMMMMMMMMMMMMMMMMMMMMMMMN.                                                     //
//                                                   .sNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo`                                                   //
//                                                 `oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo`                                                 //
//                                               `oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo`                                               //
//                                             `omMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm+`                                             //
//                                           `+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm+`                                           //
//                                         `+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm/`                                         //
//                                        .dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh`                                        //
//                                         -yNMMMMMMMMMMMMMMMMMMMMMMMh::dMMMMMMMMMMMMMMMMMMMMMMMNy-                                         //
//                                           -yNMMMMMMMMMMMMMMMMMMMd:`  `/dMMMMMMMMMMMMMMMMMMMNy-                                           //
//                                             :hNMMMMMMMMMMMMMMMd/`      `/dMMMMMMMMMMMMMMMNy-                                             //
//                                               :hNMMMMMMMMMMMd/`          `+mMMMMMMMMMMMNh-                                               //
//                                                 :dMMMMMMMMm+`              `+mMMMMMMMNh:                                                 //
//                                                   /dMMMMm+`                  `+mMMMMd:                                                   //
//                                                     /dm+`                      `oNd:                                                     //
//                                                       `                          `                                                       //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                              -yy/  `yys `yy/  .yy.  /yy`  syy:   `yyo`  `yy:                                             //
//                                              sMMN- yMMM` sMN` hMMh `NMs  +MNMm`  .MMMd: `MM+                                             //
//                                              mMdMdoMmMM/ `NMo/MmNM:sMm` -NM/dMh  .MMymNs.MM+                                             //
//                                             -MM-yMMN-dMy  +MNNM:+MmNM/ `mMNshMM+ .MM:.yMmMM+                                             //
//                                             sMm `mN/ oMN  `dMMy  dMMh  yMm+++sMN-.MM:  /mMM/                                             //
//                                             -:-  .-  .::   .::`  .::.  ::.    ::.`::`   .::.                                             //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AshWalkers is ERC721Creator {
    constructor() ERC721Creator("Ash walkers by Mwan", "AshWalkers") {}
}
