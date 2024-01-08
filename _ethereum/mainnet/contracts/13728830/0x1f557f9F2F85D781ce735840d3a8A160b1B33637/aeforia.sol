
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: aeforia X/X
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                  .---.                                                                             //
//                                                               :yNdyymN+                                    `::.                                    //
//                                                              yMM+`  .y`                                   -mNMN.                                   //
//                                                             oMMs                                          :dmdo                                    //
//                                                            `NMM.                                           `.`                                     //
//                  -/oyhddddhy+-           .:oyhdddhs:`    +shMMNssss    -/shddddyo:`       `/yhdy`/ydddh-`/shhh`       -:+shdddddyo:                //
//                 +Nds/----:oNMN+       `:ymmy+:--:sMMh`   ..mMM/.... `/hNmy/---:+hNm+`       dMMhyo/:+dm`  yMMy       .Nmy+:---:+dMMy               //
//                 /:`        oMMd      -hMm/`      `NMN.    :MMm     .hMNo.       `+MMy`     .MMMo`    `.  `NMM-       :+`        -MMM               //
//                   `.-:/ossymMMo     /NMh`     `./dMd:     yMMo    .mMN/           yMM/     sMMh          /MMd          `..:/+osydMMh               //
//                ./ydddhs+/:/MMN`    -NMN-.--/+shdds:`     `NMN`    hMMo            oMMs    `NMM-          dMM/       `:shddhs+/::mMM:               //
//              -yNms:.      oMMy     yMMmyysso+:-.         +MMy     MMM.            hMM+    /MMd          -MMm      `omNy/.`     -MMm                //
//             :NMh.         mMM-     dMMh                  mMM-     NMM`           :MMd`    dMM/          yMMo     .mMm-         yMM+                //
//             mMM:        .sMMd      +MMM/           `    :MMd      sMMs          /NMd.    -MMN          `MMM`     yMMo        `+MMN`                //
//             hMMh.    `/ydNMMo  .`   oNMMy:`    ``:yy    yMM/       sNMy-`    `:hMm+`     yMMo          /MMm  `-  oMMm-`   `:sdmMMd  `.             //
//             `omMMdhhdmy/ /NMNhys.    .odNMNdhhhdNmy-   `MMN         .smMmdhhdNms/`      `NNN.          .dMMdhy/   /dMMmhhdmy+`-mMMdhy:             //
//                `-:-.`      -:.           .-::-.`       +MM+            `.-:-.`                           .:-`       `-:--`      .:-`               //
//           /++++++++++++++++++++++++++++++++++++++++++++NMh+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/           //
//                                                      `ym+                                                                                          //
//                                                      `-`                                                                                           //
//               `-:///:-.`                                               ____                                               `.-:://:-.               //
//             +dNNMMMMMNNNmhs/-.                                       -yNMMNy-                                       `-/oydNNNMMMMMNNms`            //
//            :MMMMMMMMMMMMMMMMNNdy+:.`                               /mNMMMMMMNm\                                .-/sdmNMMMMMMMMMMMMMMMMo            //
//            `hMMMMMMMMMMMMMMMMMMMMMNmhs+/:-.``                      hMMMMMMMMMMd                       `.-::+shmNNMMMMMMMMMMMMMMMMMMMMm-            //
//             `+mMMMMMMMMMMMMMMMMMMMMMMMMMMNNmmdhyo+/:-.``           :dmmmddmmmd:            `.-:/+osyddmmNNMMMMMMMMMMMMMMMMMMMMMMMMMNs.             //
//               `/hNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNmdhyo/-.      `..::::..`      `-:+shdmmNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNdo.               //
//                  ./ymNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmds:`  `/hmNNmh/`   -ohmNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmh+-`                 //
//                     `-/ydNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh` yMMMMMMMMy  oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmy+-.                     //
//                          -/sdNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM:`MMMMMMMMMM` NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmy+-`                         //
//                              ./sdNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh``MMMMMMMMMM. oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmy/-`                             //
//                                  `:+shmNNNNNNNNNNNNNNNNNNNNmdhys/` `MMMMMMMMMM.  :oyhdmNNNNNNNNNNNNNNNNNNNNmdy+:.                                  //
//                                        `..---:::::------..-/+shddh-`MMMMMMMMMM``yddhyo/:..------:::::----.`                                        //
//                                                ```.-/oyhmNMMMMMMMM/ dMMMMMMMMb .MMMMMMMMMmdyo/:.```                                                //
//                              `.-:/+ossyyyhhhddmmNMMMMMMMMMMMMMMMMN` -NMMMMMMN-  yMMMMMMMMMMMMMMMMNmmdddhhhyysso++/:-`                              //
//                        `:oydNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMs   -dMMMMd-   :MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmhs/.                        //
//                      :hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMs     -//-     :MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd+                      //
//                     +MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN`   `+hh+`    hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh                     //
//                     /NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm`  .mMMMMm.   yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNs                     //
//                      `:shmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNy.   yMMMMMMy   `omMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNds/.                      //
//                          `.:+syhdmNMMMMMMMMMMMMMMMMMMMMMMMMmhs/.     dMMMMMMd     `:ohmNMMMMMMMMMMMMMMMMMMMMMMMNNmdhs+/.``                         //
//                                ```..--::+syhhdddddhhyyso/:.``        oMMMMMMo         `.-/+osyhhhddddhhyso/:--..```                                //
//                                             ```````                  `hMMMMh`                   ``````                                             //
//                                                                       `NMMN.                                                                       //
//                                                                        dMMb                                                                        //
//                                                                       `NMMN`                                                                       //
//                                                                       sMMMMs                                                                       //
//                                                                      +MMMMMM+                                                                      //
//                                                                      hMMMMMMd                                                                      //
//                                                                      yMMMMMMh                                                                      //
//                                                                      -NMMMMN-                                                                      //
//                                                                       :MMMM/                                                                       //
//                                                                        mMMm                                                                        //
//                                                                        mMMm                                                                        //
//                                                                       :MMMM:                                                                       //
//                                                                      -NMMMMN-                                                                      //
//                                                                      yMMMMMMh                                                                      //
//                                                                      dMMMMMMd                                                                      //
//                                                                      +MMMMMM+                                                                      //
//                                                                       yMMMMy                                                                       //
//                                                                       `NMMN`                                                                       //
//                                                                        dMMm                                                                        //
//                                                                       `NMMN`                                                                       //
//                                                                      `yMMMMh`                                                                      //
//                                                                      oMMMMMMo                                                                      //
//                                                                      dMMMMMMd                                                                      //
//                                                                      yMMMMMMy                                                                      //
//                                                                      .mMMMMm.                                                                      //
//                                                                       .ohho.                                                                       //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  
contract aeforia is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
