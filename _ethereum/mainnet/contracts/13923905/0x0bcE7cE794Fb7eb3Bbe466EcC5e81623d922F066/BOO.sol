
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bomani X
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                   `-:/+osssyhdmd/                                                                                                     //
//                                                                odmdhssoyNMMdmMNo`                                                                                                     //
//                                                 `````      `   .--``./sNMMMNmMh` `                                                                                                    //
//                                                `odmssy-   omh:     +ddhs/oo-`smmso`       ``.                                                                                         //
//                                                :dmhddNN/-yNMMNh/.`` ``-yy:   ./o+yhy/      `/.          `-/`                                         ..-/`                            //
//                                                 -oshhNMmmmNMNmMMm+s/:``-dN+ --````.//``    `..``````` -::/.                                     `..--.``:. `-`                        //
//                                                     `oso-.-oyhddNMMMMh--:++.//ssssso:-.`.`         `-`..`                                   `.-+o/..-  :-osdhs                        //
//                                                             -ohmNMMMMd-.:oyhNMMNNMMMmdh/ .:.        `-....--/:`                         `.:////:. .-- `o+dmhh+.                       //
//                                                            `smNmmMMMMMNNMmmNMMNmmmNdss/`  `.   --      .shhyssoso:`                  `.-:::`      od: .h/mmho+`                       //
//                                        ```.`  ::--.--::--/:+ohmmNMMMMMdMMMMMmo//oshhhd/       `NN.  `.``.+mMMMMMMMms:             `. ```:++       .-  .++s::-`                        //
//                                        /dmNh:-sMMMNMMMMMNNdNMMMMNdydMNhMMMMMNNNNmmmMMMm:      .NMmysyNmysyyyhmMMNhdmm-           :--+: :dd- /`. ``    //s-                            //
//                                         `-/+syymNddNMMMMMMMMMNdhy/+oNMMMMMMMMMMMNmmMMMMh/o/`  -NMMMMMMo/ydNMMMMmhhy-````        -h``o: -.+ `/``    -` sss:+++/:-.                     //
//                                               .ymMNmMMMMMMMMmshdNmNMMMMMMNNMMMMMMMMMNMMMMMMd:.hMMMMMMMMMhshdddhhdMMo `.`-`    ..:/:/+`   -.`-`  .o/`  yhyhhdy+o.`                     //
//                                       `    `-hNMMMMMMMMMMMMMNmNMhhdMMMMMMMMMMMMMMMMm+:yMMMMMMdodMMMMMMMNyNMMMho..mMm:.:.:+   .-``  //-:   -:+-. -d/. `hs.  ```                        //
//                                       dMddNMNMMMMMMMMMMMMMNMMMMmyyhMMMMMMMMMMMMMNsyMy:ohMMMMMMMhyMMNyyNMhohMMMms/+md`    /-  /..   /+y- .-+`+o`  :` :`y+                              //
//                                       .ohNMMNMMMMMMMMMNNMMMMMMMNNmMMMMNMMMMMMMMMmNMMMmMMMMMMm/sNNdMMMh/dNMNNmNy````.-.       ``.  -.`-/` .:-/:  .y`---d/                              //
//                                       yNNhNMNomMMMMMMMsNMMMMMNNMNNMMM++NMMNNNMmNNMMMMMMMMMMMMNNMMMMMMMNsdh.`.d:      `...-`    ` `  `+//o/./.-  /o ` sy`                              //
//                                        ``.ohNNMMMMMMMMNMMMMMmyNNMMMMh-hNMMMMMMMMMMMMMMMMMMMMMMMMMMMNNMMMMNdyNMm:  ``.`   `::....--  `..``````   .`  `m+     .-`                       //
//                                       `:ymNmMMMMMMMMMMMMMMMNmmMMMMMN-.sdMMMMMMMMMMmNMMMMMMMMMMMMMMMMNMMMMNMMMMMm``/:/---.-.``..`.+..`   .+::` -::.  oh`   .//+++.                     //
//                                    .:smMMNNMMMMMMMMMMMMMMMMMMMMMMMMd`-odMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNhy. `..   ``   `.`yody     ```  /y-:  oo   -.h+-`o+                     //
//                                   .hNNmdhy+sdNMMMMMMMMMMMMMMMMMMMMMs-+dMMMMMMMMMMMMMmMMMMMMMMMMMMMMMMMMMMNhhmNNNo:-.         -.-h+m:   `````  `.o.`.s:  `::/o/++`                     //
//                                    .-.`.:-`./dMMMMMMMMMMMMMMMMMMMMMsshNMMMmhydMMMMMMNMMMMMMMMNMMMMNMMMMMMMd-.o/+hmh/--``-``  - -oyy  :`.-:oo   /o `.``:ss+  .-.                       //
//                                      .odhydmNMMNMMMMMMMMMMMMMMMMMMMMNMMMMMh-/oMMMMMMMMMNmdhmNhydMMNNMMMMMmMm+y::`:oss+` ``-:.  ///+ `o -:-Ny  `d.`` /yy+.                             //
//                                    :hNMNmyosNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMhoymMMMMyyMNmdddmNMMMMMMMMMMMMMNMMMMNmdy:        ./  /o-o``+ -.-mo  +o`+:++-`                               //
//                                    /yhs-`  /hMMMMhdMMMMMMMMMMMMMMMMMMMMMMdNNMMMMMd:-/:-:hdddMmNMMMMMMNddMNNNMNdNMh.         .- :+-::.+ .`:N: `y-o+                                    //
//                                          .yNMMMMMdMMMMMMMMMMMMMMMMMMMMMMN+mMMMMMMMm:sshdmmhmMNMMMMMMMNh/os..No-/yNms-        :.-o:/``-   ys```h-s`                                    //
//                                         -mMNdMMMMMmdMMMMMMMMMMMMMMMMMMMMMmMNMMMMMMmhoommNMMMMMNMMNMMMNddy- `od+ .-+ymo.       :-::..     - .``m..                                     //
//                                        .mMmyNMMNMNMMMMMMMMMMNNMMMMMMMMMMMMMMMMMMMMMMdsyymNNmNNNmyo+/yhddo-odMm/     `          ``o-.         -s                                       //
//                                        sMm/NMM+`.sMMMMMMMMMdsmmmMMMMMMMMMMMMMMMMMMMMmhyhhdds/.`     -- `oNMMN:                  :so:/+/s//-:`o.                                       //
//                                       `mM+oNNMosmNdNMMMMMMMmdMMMMMMMMMMMMMMMMMMMMMMmo---/++oo++/:odhNhhMMMMMMd/`              `+/+osssso+o-.`+`                                       //
//                                        yN-  :NMmh.omMMMMMMMMMMMMMMMMMMhohMMMMMMMNmdsdNMMMMMMMMMmNMNmhymysMmNN+`               :NdyNMMMMmNmy---                                        //
//                                        `.  .dMMMmNNMMMMMMMMMMMMMMMMNmM+/NMMMMMMd`::odNmyhmmmMMNhMMMy..NMMMdo+                 yMMMMMMMMMMMy-:                                         //
//                                             /sssshNMMMMMMMMMNMMMMMMMdNNmMMMMMs:/  ``.`yNNMmdMmmMMMMm. /NMMMMs                -NMMMMMMMMMMN:o`                                         //
//                                                `shhMMMMMMMNmNMMmymMMNMMMMMMMMh--..-///mNNNmdMMNMMMMm`  +NMMM+               -hMMMMMMMMMMMd++                                          //
//                                                  `:NMMMMMdysmMm--hMMMMMMMMMMMMs`  .o/:://-:-/dmMMMMs    yMMM.               `dNMMMMMMMMMMdd.                                          //
//                                                   sNMMMNy+./NMm:hdMMMMMMMMMMMMm/            .dMMMMd.    +MMN                /Noydmdyydmddms                                           //
//                                                   .sMNh/    sdo`-dNdMMMMMMMMMMMN+..        :yMMMMM/     .hMs                hhss+s++o++/+h-                                           //
//                                                `.+hds:`      ``:dd+hMMMMMMMMMMMMNds.     .sNMMMMMMh/+/``.sM/               -N--/o//+:+yh/o`                                           //
//                                                +hh/`          `++`/MNhMMMMMMMMMMMMMh+-::sNMMMMMMNMMMMMddNMM+               yh/sMMmmmmNMys.                                            //
//                                                                   oMN+NMMMMMMMMMMMMMNMMNdNMMMNMMMNMNMNNNNdNmo.            .mdMMMMMMMMMm-+                                             //
//                                                                   hMmsMMMMMMMMMMMMMMMMNhNhMsosmNhhy/+:-:osyhN/ `          /NmMMMMMMMMM++`                                             //
//                                                                   mmyyMMMMMMMMMMMMMMMMMMMsMm/`.:/-/ssyo..`.omo-          `ddMMMMMMMMMN/o``                                            //
//                                                                  `hy/hMMMMMMMMMMMMMMMMMMMNNMMdo-`````` `-syMMmd+.`       /hyMMMMMNdyddh-``                                            //
//                                                                  .sy/ymhhNMMMMMMMMMMMMMMMMMMMMMMmyoydNmNMMNyMMMMNmy+/.`--hsmMdo/o/:` .+ .-`                                           //
//                                                                +dNNd:/hsomMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNy-..-+++s+/:---:-shmMMNmyhs`                                      //
//                                                                +MNmd/.-+dNMMMMMMMMMMMMMMMMMMMMMMNhyyNMMMMMMMMMMMMMMmddo o-+mMNdo/-sddddMMMMMMMMmo/.                                   //
//                                                                sMMMMhoyssyNMMMMMMMMMMMMMMdhMMMMmddmNMMMMmyhMMMMMMMMMMM/-yymMMMMNNmMMMMMMMMMMMMMMMMNdho:.`                             //
//                                                             ./hMMMMMMNdd/yysoNNNMMMMMMMMMMMMMMMMMMhMMNysodMMMMMMMMMMMd`ymMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNms/                           //
//                                                         .:sdNMMMMshMMMMNhhhddNN:hMMNdddMMMMMMMMMMMMMMNmNMMMMMMMmMMMMMm-mMMMMMMMMMMMNMMMMMMMMNMMMMMMMMMMMMMMh:.                        //
//                                                    `.-+hmMMMMMMMMNNMmNMMMMMMMNMh:NMdyddMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMy:NMMMMMMMMMMNhMMMMMMMymMMMMMMMMMMMMMMMNNh+`                     //
//                                           `.--/osydmNNMMMMMMMMMMMMMMmhMMMMMMMMMMNMMNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM+-mMMNMMMMNmMdNMMMMMMNhMMMMMMMMMMMMMMMdmMMMh`                    //
//                                     `-:+shdmNNMMMMMMMMMMMMNhmMMMMMMMMMMMMMMMMMMMMNoyyhMMMMMMMMMMMMMMMMMMNMMMMMMMMMMMMo/oso/++oy+-/oMMMMMMMMMMMMMMMmMMMMMMMMMmsohMh.                   //
//                                 `./shNMMMMMMymMMMMMNNmmmhsssmMMMMMMMMMMMMMMMMMMMMmsyyo/smMMMMMMMMMMMMMNsNMdNNMMMMMMMdo/////////:-/yMMMMMNMMMMNMMMMmMMMMhhNMMMNs-sMh`                  //
//                             ``-oydNMMMMMMddMMMMMMMMNmdmNNMMMMdNMMMMMMMMMMMMMMMmmMMMMMmo``dMMMMMMMMMMMMmyMNyNMMMMMMMMo//osds:o:...:dMMMMMMMMMNmMMMMMMsMmmmdhNMMMN/yMy`                 //
//                         `-+yhdNmhydMMMMMmNMMMMMMMMMMMMNMMMMMdhsMMMMMMMMMMMMMMMMMMMMMMNNy:smMmMMMMMMMMMMMMMMMMMMMMMMN/oNMMMNMMmdhmhNMMMMMMMMMMMMMMMMs-MMNshshMMMMh.dM+                 //
//                        /hNMMMh/:oNMMdoMNyyNMMMMMMMMMNdmNMmhNhmmNMNNMMMMMMMMMMMMMMMMMMMMMMM+MhdMMMMMMMMMMMMMMMMMMMMMd+hMMMMMMMMMMNMMMMMMMMMMMMMMMMMmhNMMhsdo/NMNNMo/Md`                //
//                      `yMMMMMMhdMMMMm/-NMMmdMMMMMMMmmmMMMMmMMNNd+mMMNMMMMMMMMMMMMMMMMMMMMMm+NMMMMMMMMMMMMMMMMMMMMMMMsyMMMMMMMMMNs/mMMMMMNhdMMMMdMMMMMMmsyMMo`hM/.hMoNN`                //
//                   `-+dMMMMMMMMMMMMdsooNMMMMMMyoodNMMMddhNMmhshMNMMNyNNsNMMMMMMMMMMMMMMMMMMdNMMMMMMMMMMMMMMMMMMMMMMN-sMMNMMMMMMy-:NMMMMMdsMMMMMMMMmsNMd+mMMm-sM: `dMdo                 //
//                   sMMMMMMMMMmMMMMMhmmohMMMMMNdmNMMMNNmMMMMMMMMMMMMMMd+ dMMMMMMMMMMMdNMMMMMMMMMMMMMMMMMMNMMMMMMMMMMd:/o+omh+++:.`+MMMMMMNmsMMMMMy+-+NMMMMMN. +Ms  -Nh`                 //
//                  `+MMMMMMMMMMMMMMMd+/sNMMMMMMMNNMMMMMmhNMmyyNMMMMMMMMNohmMMMMMMMMMNo+MMMMMMMMMMMMMMMMMsyMMMMMMMMmMs-:yNd//////+/mMMMMMMMNoMMMMMMNNMMMMMMMy``/Mh   +M-                 //
//                `+mMMMMMMNMMMMMMMdNmNMmsmMMMMMNmNNNMmMMMNmmNMMMMMMMMMMMMm+MMMMMMMMMMMNysMMMMMMMMMMMNyMM+sMMMMMMMy.oymhMMmMm--..-oNMdMMMMMMMMMMNMo` /MMMMMMo `+s+   .mo                 //
//              `+mhyMMMNMMMMMMMNdMNMMMh` /MMMMMMMMNMMmMMMMNhyymMMMMMMMMMN-`sMMMMMMMMMMModMMMMMMMMMMMMMMm:NMMMMMMm- ./MMMMMMMNMssh+odmMMMMMMMMMM:hm- :MMMMyM/         /:                 //
//            `/dh:`hMMMMMymMMMMNMMNhmMMm:.NMMMMMo+ydmNNMMddNNdmMMMMMMMMMN- `MMMMMMMMMMm/NMMMMMNNMMMMNMMhmMMMMMmMm. `sNMMMMMMMMMMMNdyhMMMMMMMMMMmmmmyhMMMhsd-                            //
//          `+dh/` -NMMyMMMMMMMMMMmmNMMNmm:dMMMMMo/dNMNNNNMMNhNMMMMMMMMMMMs `NMMMMMMMMMNNMMMMMMdyMMMMMMMmMMMMMMMMm-..odMMMMMMMMMMMMMMNMNMMMMMMMMNyoymNMMMhym.                            //
//        `:mh+/++.dMMdmMMMNmdMMMNMMMMhsyMdhMMMMMh.:+shmmdys//mMMMMNMMMMMMm`-MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmmoydMMMMMMMMMMMMMMMMMMMMMMMMMMysmhyMNhmNN-`                           //
//      `/dNds+-./hMMMoMMNNNNMMNdNMMNysNMMMMMMMdMMmNNMMMNNNNmo+mMMmhMMMMdsMo/MMMMMMMMNdMMMMMMMMdNMNMMMMMMMMMMMMMMMMNMNMMMMMMMMMMmMMMMmMMMMMMMMMMdomy-yMy-MMN:`.---....```                //
//     `smd+.` `:/yMMMmMMNNMMMMMNmmdNNMMNosMMMMdMMMMMMMNMMMy-.:dMmmMMNMN-`dNdMMMMMMMMNNMMMMMmdMNMmmMMMMMMMMMMMMMMMMMMMMNMMMMMMMNdMMMMmMMMMMdNMMMdNmomMMd/NMM/.......----:.               //
//      .-`  `-.` /MMMMMMMMmMNymoshdMMMMMdmMMMmdMMMMMhsmMd+/ydds:+mNyhMo  -mMMNMMMMMMMMMNNMMooMMMsNMMNMMMMMMMMMNNMMMMMMmdhydMMMMMMMMMMMMMMMmMMMMMm/dNMMd`yMM-````...-...`                //
//         `::``./ymdNMMNom:dMsyNNMMMMhNMMMMMMMMMMMm++mMmhmMNo` `.sddNN`  `+MMMMMMMMMMMh/mMm-/MMm:dmy:/hdhhMMMMNNMMMMMMMNhhMMMMMNdMMMMMMMMNMMMMMMymy:NMN +MM-                            //
//        /y++/+mN+-.+MMM+NmNMMMMMMMMMMMMMMMMMMMMm+..dMMMMNh:`-:hNNdsh+ .+dMMMMMMMMMMMh``dNh -MMy `.      hMMMMMMMMMMMMMMMMMMMMMssMMMMMMMMhNMMMMMm/ `dMM`.NM/                            //
//        oho:`:yddydhNMMdmNNmMMMMMMMMMMNh/sMMMNs/+hmddNNd/:smNMNs-    :dMMMMMMMNshMMh.  --. .mm/        `NMMMMMMMMMMMMMMMMMMMMM:NMMMMMMMMmMMMMMm.   oMM/`sy/                            //
//                  -mMMMMMN+dNMMMMMMMMMd-`sNNsodNho/hMhhyNMMNh/`       /mMMMmy:. hMy`                   .MMMMMMMMMMMMMMMMMMMMMhsMMMMMMMMh/hMMMMy    :Mm-                                //
//                   :NMMMMMNhymMdhMMMMNNMNMNmmd+-omNMNmMMNh+.        .omMNy:`   sMh`                    `NMMMMMMMMMMNMMMMMMNyNN+NMMMMMMM:`dMMMMo    `mm                                 //
//                    -mMMMMMMMMMMmNMNhMMMMMMd-`+dMMMMMMd+.          -hds-`    `hMy`                      :dMMMMmyMMhyMMMMMN: :m/MMMMMMMm-hmMMNs.     dM`                                //
//                     .mMMMMMMMMMMMMMMMMMNhMMNNMMMMMd+.                      `hMs                         .hMMMN:mMM/:hMMMy   ydMMMMNMMsdh`NMd       oM/                                //
//                      :MMMMMMMMMMMMMMMMMMMMMMMMMdo-                         /mo                         :dMMMMMNNMMmo++o+-...dMMMMNyMMmd.oMo-       /Mh                                //
//                      `NMMNmNMMMMMMMMMhMMMMMMdhNd:                           `                         /NdsMMMMMMMMMMMMMNNNNNMMMMMMMMMd.-Ny         `NN.                               //
//                      `hMMo`-dMMNyNMMMdshNMMMy/:sNy-                                                   +dhmMMMMMMMMMMMdo:-/mMMMMNysMMN::mm`          sMo                               //
//                       ohy-  `sNMMMMMMM+``-/shmNddMNh/.                                                 `.mMMMMMMh+sshdmNmNMMMMMd+yMMysms.           -Mm`                              //
//                        `      :hMMMMMMMy.    ./ymMMMMNhs:                                               .NMMMMMMmddddmNMMMMMMMMdsNMMmm/              hM+ :                            //
//                                `/dMmNmMMm/      .:shNMds:                                         -/oshdmMMNMMMMMMMMMMMMMMMMMMN//My/:.               -Nmom`                           //
//                                  `+dNyMMMNs.       `.:/.                                       `-oNMMMMMMMMmMMMMMMMMMMNNMMMMMMs-yN/                   :dh+                            //
//                                    `/hNMMMMd-                                                  -hmhs++mMMMNNNMMMMMMMMMMMMMMMMN` ..                     `                              //
//                                       -oddy/.                                                   ``  :ydds//odMMMMMMMMMNdddmMMd                                                        //
//                                          `                                                                                                                                            //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOO is ERC721Creator {
    constructor() ERC721Creator("Bomani X", "BOO") {}
}
