
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pillheads
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                              ```..------..```                                              //
//                                         `./oydmNMMMMNNNMMMNmdyo/.`                                         //
//                                      .+ymMMMmhyyyyyyyyyyyyyyhmNMMmy+.                                      //
//                                   .odMMNhssyhmMMMMMMMMMMMMMMmhyssyNMMdo.                                   //
//                                 :hMMmysymMMMMMMMMMMMMMMMMMMMMMMMMNyssmMMh:                                 //
//                               /dMMhsyNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNysyMMd/                               //
//                             -hMMhodNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdoyMMh-                             //
//                            +NMmohMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdodMN+                            //
//                          `yMMysNMMMMMMMMMMMMMMMMMMMMMMMMmdmNMMMMMMMMMMMMMMNssMMy`                          //
//                         `hMMoyMMMMMMMMMMMMMMMMMMMMMMMmo+osso+sNMMMMMMdsNMMMMhoNMh`                         //
//                         yMMohMMMMMMMMMMMMMMMMMMMMMMMh:hNMMMMNs:mMMMMM/ -mMMMMd+NMy                         //
//                        +MMsyMMMMMMMMMMMMMMMMMMMMMMMM.hMMMMMMMM++MMMMMNo .dMMMMhoMM+                        //
//                       .NMd+MMMMMMMMMMMMMMMMMMMMMMMMM.hMMMMMMMM/oMMMMMMMo .mMMMMohMN.                       //
//                       sMM/mMMMMMMMMMMMMMMMMMMMMMMMMMd:yNMMMNmo:NMMMMMMMM/ /MMMMN:MMs                       //
//                       NMN/MMMMMMMMMMMMMMMMMMMMMMMMMMMNs++++++hMMMMMMMMMMm  dMMMM+dMN                       //
//                      .MMyyMMMMMMMMMMMMMNdhyhmMMMMMMMMMMMMNMMMMMMMMMMMMMMM: oMMMMhoMM.                      //
//                      -MModMMMMMMMMMMMm//shdho:sMMMMMMMMMMMMMMMMMMMMMMMMMM+ :MMMMm/MM-                      //
//                      -MModMMMMMMMMMMm.dMMMMMMM//MMMMMMMMMMMMMMMMMMMMMMMMMo :MMMMm/MM-                      //
//                      .MMyyMMMMMMMMMM++MMMMMMMMN NMMMMMMMMMMMMMMMMMMMMMMMM: +MMMMhoMM.                      //
//                       NMm/MMMMMMMMMMh-NMMMMMMMy-MMMMMMMMMMMMMMMMMMMMMMMMm` dMMMModMN                       //
//                       sMM/NMMMMMMMMMMs/ymNMNd+/mMMMMMMMMMMMMMMMMMMMMMMMM/ :MMMMN:MMs                       //
//                       .NMd+MMMMMMMMMMMNhso+osdNMMMMMMMMMMMMMMMMMMMMMMMMs `mMMMMshMN.                       //
//                        +MMoyMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMs``dMMMMd+MM+                        //
//                         yMM+hMMMMMMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm/ -dMMMMd+NMy                         //
//                         `hMNohMMMMMm:-yNMMMMMMMMMMMMMMMMMMMMMMMMMMNs.`+NMMMMd+NMh`                         //
//                          `yMMssNMMMMh:`-smNMMMMMMMMMMMMMMMMMMMMNmo.`:dMMMMNysNMy`                          //
//                            +NMdodMMMMMh+.`:odNNMMMMMMMMMMMMNNho-`.+dMMMMMdohMN+                            //
//                             -hMMyodMMMMMNh+-`.-/osyhhhhys+/-``-ohNMMMMMmsyNMh-                             //
//                               /dMMyohNMMMMMMNhs+/:-....-:/oyhNMMMMMMNhoyNMd/                               //
//                                 :hMMmssyNMMMMMMMMMMMMMMMMMMMMMMMMNhssdMMh:                                 //
//                                   .odMMmysyydNMMMMMMMMMMMMMMNdyysymMMdo.                                   //
//                                      .+ymMMNdyyyyyyyyyyyyyyyydNMMmy+.                                      //
//                                         `./oydmNNMNNNNNNMNNmdyo/.`                                         //
//                                              ```..------..```                                              //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PLHDS is ERC721Creator {
    constructor() ERC721Creator("Pillheads", "PLHDS") {}
}
