
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Momentos: A Memoir
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                        ##   ##  ####  #    # ###### #    # #####  ####   ####                              //
//                        # # # # #    # ##  ## #      ##   #   #   #    # #                                  //
//                  ✮     #  #  # #    # # ## # #####  # #  #   #   #    #  ####     ✮                        //
//                        #     # #    # #    # #      #  # #   #   #    #      #                             //
//                        #     # #    # #    # #      #   ##   #   #    # #    #                             //
//                        #     #  ####  #    # ###### #    #   #    ####   ####                              //
//                                                                                                            //
//                                                                                                            //
//                             #                                                                              //
//                            # #      ##   ## ###### #    #  ####  # #####                                   //
//                           #   #     # # # # #      ##  ## #    # # #    #                                  //
//                          #     #    #  #  # #####  # ## # #    # # #    #                                  //
//                          #######    #     # #      #    # #    # # #####                                   //
//                          #     #    #     # #      #    # #    # # #   #                                   //
//                          #     #    #     # ###### #    #  ####  # #    #                                  //
//                                                                                                            //
//                                                                                                            //
//    `-//ohh:.-o`````yo``-:/````````.+syo`:  ``..y+ho  smsh:-/`  -   :```--.-    ````.syh----.--::+/o-.:/    //
//    -:/:/so/:hms+oyyyh//..`````````./oo+:/.``   oh+h. so+-+sy- `.  `.`.`-/::         yydss::yo/.++/+::ho    //
//    ++oossyooyhhsymmdNh+o:../:--..-oyhdddddhyo/--dysd:os+ohdNds.`   ` ` `...`  --.-:::-:`.--:/.`/`:+::--    //
//    ooyhmys/ssdNds+ossyyhysssy:/ooydddmdmmmdmmddy//o+syhdmddmdNs  `.::-.-:/-``:::-++::/:..---```.-+y-:`:    //
//    oo/+o:+::ysmNh::://////:://hhdmmdmmmmmNmNNmdmd/-:osmNNNdmNNmhyyddddyyoooos++oosyo+/o+:..``.`--.+shdm    //
//    o.``:````ohyNm-..`.ohhhhhmhdmNNmmmNNNNmmmmNNmmo/:ssdddyyyhhso++ooosoyysssyyho+oyys//h-../s++oso+sshm    //
//    .`:..`  `./syh::-.`-mmdNMMdhmmNNMNNMNNNNNMNdysy+/symhssdddddddddhs+ooooossoo+/+/+yyyo::-++-:oyys:-::    //
//    /.:..`  ``yos+/////-hmdNMMmydNNNNNNNMMMMNmho:sdohddmhmNNmmmmmNNmmdhsoo++++///:::+o++:::-------------    //
//    mhho+:/::.omy/hhhhy/+oo++++odNMMMMMMMMmhyso/:y+ohsodNMMNNNNNNNNNNmdh:---............``.```.......--:    //
//    mmN+:-+/-/-o+/hhmmdsooo++/omNMMMMMMMMNmyoo+/:d::+h-yMMMNNNNNMMNNNNmds---................`........-..    //
//    oos+:.+::ho+//+yo//::::::+mMMMMMMMMMMmyyhyo:+y::/o/yMMMNMNNMMMMMMNNmh:.--------:-----::::::/::::::::    //
//    /////.//+hh//:/+:::---::/mNNNMMMMMMMMMNNNdy+:::--:-oNMMMMNMMMMMMMNNNd+:///////////////////////////:/    //
//    ////+++s+sh/:::::::::-:/sNNNNNMMMMMMMMMMMMMN+:::///oNMMMMMMMMMMMMMNmmo//////////////////////::::::::    //
//    ////++/d+/s//////:::::::hNNNNNNNNNNMMMNNNNNs///////oMMMMNMMMMMMMMNNmdh/::::----::-.:::::::::::::::::    //
//    +//+++/yyshy+++++//:/+//mNMNNNNNMNNmdhyssss+///////hMNNNMMMMMMMMNmNNddy+:---..-------:::::::://////:    //
//    +//++.-:/+////::---os+:/mMMMMMMNdysoooooooo++o::---dNmNMMMMMNNNNNNmNmddhhy//////////////////////////    //
//    ::://:////:::::---/sy/++yNNmNdyssoooosoosyosoysh:..hmdNNNNNNNNNNNmmNmdddhdy::::://////::/:::::::::::    //
//    :::::::::--------.+syo+oossysooooososoyyhsshyodym-.ymNNNNNNmNNNNNNNmmddddhhs:////////////::::-------    //
//    ```` ```````......+ysoossssossoooosoohdyshdhyoyydy:dMMMMNNNmMNNNNNNdmmdmdhhh...----:::::::::::::::::    //
//    :::------....````.:/os+ooo/+s+ooosssyNsydhyyyyyyymoNMMMMMMMNNMNNNMNmmNmdmdhh:--:::---.....``....-...    //
//    ```````.....-...`..-:os++/:+:-/+ossshNydhyhhhhhhymyMMMMMMMMMMMMNNMMNdmmmdddd/---...`````.------:::::    //
//    :::::--......-.``-:+smm//:++..-:/oosdMhhyhhhhhhhhdmMMMMMMMMMMMMMMMMMNmmmdddh:......------:::::::::::    //
//    ------:::---:::.``-/ooso:oo:``..-:/odMyyhhyhdhhyhhMMMMMMMMMMMMMMMMMMMMNNmdmh+::/::---...```.```````     //
//    :----.....``````.----omm:+:-.````.-omMdyyyhddhhyhhNMMMMMMMMMMMMMMMMMMMMNNmds+///::--.``      ```....    //
//    ``             `.-::+dNd:-.--.````-hNNMy+shhhhhyhymMMMMMMMMMMMMMMMMMMMMNNh-..``    `````.--:://////:    //
//    ..````           `.:+hdo/`.:-.```.:ymNMNosyssyhhhydMMMMMMMMMMMMMMMMMMMMNmy````......----:::::----..`    //
//    -.````              .:o/-.----.`../dNNdNysssohhhdyhMMMMMMMMMMMMMMMMMMMNNNd:///:::----:--------..``      //
//    ````````...------.------:-.-------odyohNyo++ohhhhydMMMMMMMMMMMMMMMMMMMNNmh/+++//:-...`````     ````.    //
//    .--:://///////////::--...`````....:::ymdy///ydhsshhMMMMMMMMMMMMMMMMMMMMNds----..```   `````.--::///+    //
//    ---..............````   `.````` ```.:ommm+/ssssyhhydMMMMMMMMMMMMMMMMMMMNdd/.`.```.--:://////////::::    //
//    ---..````         ```..-`....`````.-sdmNNmsshdyhhhhyMMMMMMMMMMMMMMMMMMMMmmm+://+++++++///::::::::::/    //
//            ```...----:::::-.-:::----::/oshddyhhdhyhhddymMMMMMMMMMMMMMMMMMMMNmmmo//++/://:::::-+so+::--.    //
//       `````......```````````-:++///////+sdmmmNyyyhdddhyhMMMMMMMMMMMMMMNNMMMMNmmh::///////..:/oyyo/..--.    //
//    ..........````......----..-///++ossyhdmmNmmNsyddhhhyymMMMMMMMMMMMMNNNNNNMMMmd:::::-..` -.:soo/+:/hdd    //
//    ...................```  /so/+/++osyhhddmmNmNdsyhhddhhdMMMMMMMMMMMNNNNMMMMMMN+..`  -.   `..-.`-ohmMNN    //
//    ....``````              -:shhysoosyhhddmdNNNNyshhhhyyyNMMMMMMMMMNNMMMMMMmhs:            `.::/so/osyd    //
//    `                   ````++ooshmddddddmmdmNNNMNhhddddhhmMMMMMMMMMMMNmmmho/:-```````..:-::::::/-:+////    //
//                ````````````:hhhhhmdhddmNNNNMMMMMMyoyhyyhhdMMMMMMNNmhy+shso+/-...--:::::----.....:ys+:::    //
//       ``````````````....--./hddmmNMNssydmNNMMMMMM+/dyhhdhdNNdhysoo+//yyso+/:--::-------...``````:yyys:-    //
//    :....`.``.......--.-....:hdmmNMMMoshhmmNNMMMMh`/mhhhdhyyhso+///::/yso+/:-.````````````..`````-yyyyy+    //
//    ........--------.......`:yhdmNMMM+shdmNNMMMMN- `-+syyosydo///:--:oyo++/:-`...----::---........:oyyhh    //
//    --:::////+++/++++/+/::-./yhdmNMMM+oydmNNMMMMo   `-:+/sssyo////:-:oyso+/:-::///////::::::--.---::/oyh    //
//    ++ooossoooooooo++/:-.`  +shdmNMMN/+shdmMMMMd-`.`.``.//-:/++////:+shs+//:..-------:-------:--.`-/::/+    //
//    sossoooo++/:-..`       .oyhdmNMMy++shdmMMMN/.```````s+..--:///:/oooo++/-.`......```     ``..` `o:.-:    //
//    +//::-..```````       `/shdmNMMd-+oyhdNMMMs......```s/....-//::oos+++/:--```                  ./.`.:    //
//     `   ``......``       -shdmNMMh--osyhdNMMN:..```````+/...-:-::+:yyo/:/:-.               ``   `./-:::    //
//                      ```.oyddNMMN-`/yhhddNMMm.....`````-:.-::--:/--syso///:.                `..-::/:///    //
//                `````````:yhdmNMM/..+dddmmNMN+.`````````.o.-.`....-/yys+/++/.           `..---:::::::://    //
//          ```````........+hdmmMMm...dmmmNMMMs...`...---.+.`.````.--/yyys+//:-      `..-::::::::::::::://    //
//    ```.....`........``.`ohdmNMMs..ommmNNMMN:///:-..````+```````---+hsso+//:-`.--/////++//++++////+s////    //
//    ..........``````````.syhNMMM+.-hdmNNNMMs---......```/-``.`..---shsss+//:-/++++++++++o+ooooooodmmyssy    //
//    ....`````.`.........:ssymMMm//+yhdmNNNN---:------..`-:.---..---shsso+/:-.-::////++++oooosssssyddyssy    //
//    .......----:::///+/++yshMMMd:-+yhdmmNNs-.....````   `/.------:-shyso+/:-.:/+oooooosssossosssssysssso    //
//    -------:::///+++++///hddmMMy``ohhddNNm-```           //....---.ohyso++:-.osssosooooo+++//:::://+ooss    //
//    .---.---:--:::---.``.ydmNNNm-`hdddmNMo```  `     ``..//.```.:-.+yhys++/-.+o+++/:::::::-://+ossyyyyhy    //
//    ............``      `dddNNMN+smmmNMMN-``  ```.--:://+-```  .:--+sshs++/-.+++++//+//++oossyyyyyyyyyyy    //
//    .....```         ````ydmNMMsoNNNNMMMs--:://+ossyyyyyy.``   `:--:ooos+//:-+ooooossssyyyyyyyssyyyhyyso    //
//    ``               ````++mmddohNNNNMMMyyyyyyhyyyyyyssoo-..`` `-.--sho+++/:-/ssyyyyyyyyyyhyyysyyyso/:::    //
//    ...```` `   ``   ````:/dhdssmNNMMMMNhhyyysssoo++++os+:```` ```-:dhho/::::+yyyyyyyyyyyyyyyso//:::----    //
//    ----:------.:/-.````.+ommddmNNNNNMNmmds++++++sossshNs.``````-::sMdyo+/:-.yyyyyyyyyyysso++::-----...-    //
//    -::-:-------::-::-::/ssdNmdddmNNNNmddmdh+ososhyhhhmNm+---....-oNMMNds+/:-yhyyyyyoso/:-...`..-.......    //
//    ----------::-://ssyhddddhsy-/osydhyyyydhssyhdhhhhhdNdyo:.`` `-+mmNNMNdhyhhysys+/-.```````````--...-.    //
//    ------:://oosyhhhhhhdhddds.`.-/+oyyys+oyydmmdyssssoososoo:..-+ydddddddhhyo/:-````````````..``..--..-    //
//    :::://ooyyhhhhhhhhhhhhdddh/+ooydmNNmhhhhys+::::/:://///:/:---:--:::::::::::--:::::::/:::::----.-`-.`    //
//    +ssyhhhhhyhhhhhhhhhhhhdddmNNNNddy+/:---------...`.......--::///+++++++ooooossssssssssoooo++///::///:    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("Momentos: A Memoir", "MM") {}
}
