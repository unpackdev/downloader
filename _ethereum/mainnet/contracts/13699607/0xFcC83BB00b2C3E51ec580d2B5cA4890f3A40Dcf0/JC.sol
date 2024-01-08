
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CARDELUCCI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ````````````````````````````````````````````````````````````````````````````````````````````````````    //
//    ````````````````````````````````````````````````````````````````.````````````.-.```````````````````.    //
//    ````````````````````````````````````````````````````````````````+y````.:/++oshsy+:.```````````````..    //
//    ``````````````````````````````````````````....``````````````````/Nhoo+hddhmNNmy++::-....`.`````...-.    //
//    ```````````````````````````/.`o+..::///+oo++++--.````````````````yNNNNNNNNNNNNmhhsso+:---::--:::-...    //
//    ```````````````````````````oy/sdsyhhhhsyhshyoooo+--``````````````/NNNNNNNNNNNNNNNNNNNmmdddddhhs+-...    //
//    ```````````````````````````-mNmmddmmNNNNNmNmmmmhhs+--.`````````./mNNNNNNNmNNNNNNNNNNNNNNNNmdyo//-..`    //
//    ````````````````````````````oNNNNmNNNNNNNNNNNNNNNdyo:..``````./smNNmmmmmdmNNNNNNNNNNNNNNNNmdyo++:--:    //
//    ```````````````````````````-yNNNMNNNNNNNNNNMMNNNNNNNddhhyssoohdmmdddmmmmmNNNNNNNNNNNNNNNNNNNmmmdhyys    //
//    `````````````````````````.+hNNNNNNNNNNNNNNMMMNNNMNNNNNNNNNNNmmmmmmdmmmmmNNmmmNNNNNNNNNNNNNNNNNNNNNNN    //
//    ..........-------::::::-+hmmNNNNNNNNNNNNNNNNNNMMMMMNMNNNNNNNmNNmmmmdmmmNmmmNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    :::::::///////+++++++++odNNmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    ///////++++++++oooooooohmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    /////+++++oooo++oo+++ohdmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMNNNNNNNNNNNNNmmhsymNNNNNNNNNNNNNNNNNNNNNNN    //
//    o++++++++oo+++++++++sdmNmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmmmmddhsssmNNNNNNNNNNNNNNNNNNNNNN    //
//    ooooooossssso++++++ommmmmNNNNNNNNNNNmdNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNdddddhho/dNNNNNNNNNNNNNNNNNNNNN    //
//    +++++oosssssso++++ommmmmNNNNNNNNmhys++odNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmddhyhy+sNNNNNNNNNNNNmdhhyyyss    //
//    ++++++oosssssso++smmmmmNNNNNNmhs+++oo+o+yNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmdyyyyssssssoooo+++++osyhd    //
//    +++++++oosssoooo+smmmmmNNNhyo+++++ooo+ooosmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmhhhyssossssyysssyyydmmNNN    //
//    +++++++ooooooooo+/+yhdmmds/////::///+:++ooomNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmmmddmdmmddddddmmNNNNNNN    //
//    /////+++oooooooo++//////////::-.:/:/:-//+++omNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmNNNNNNNNNNN    //
//    ///////+++++++++++/::::::::.....---/.-::/++/yNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    ////////++++////////:::::-.``.....-:-.:.://:hNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    :///:////////:-::////::::.````.`...-:.-.-:::dmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    ::::::::::::::--:::::::::-...`````.....--:::hmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    ::::::..-::::::---:::::::-...````````....:::ymmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    ::::::--..--::::---::::::-..`````````````---/mmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    .--::----....-::::--::::::-...```````````.--.smmmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    ...--------...----:-----:---.`````````````...-dmmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    ......------.`..--------.---..````````````.-+hmmmmmNNNNNNNNNNNmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    .`````...--..``..-----...-....`````````.-/shmmmmmNNNNNNNNNNNNNNNmmmmNNNNNNNNNNNNNNNNNNNNNNNNNNmmNNNN    //
//    ````````..-........---.......```````.-+ydmmmmmmmmmNNNNmsommNNNmyohmmmmmNNNNNNNNNNNNNNNNNNmmdysoomNNN    //
//    .``````...-........---........````.+hmmmmmmmmmddyoo+++:`ommmNNd-/dmmh+ydmmNNNNNNNNNmmmdyo/::+++-+hmN    //
//    ..```.....-.........----.........+hmmmmmddys+:-.```````.hmmmmm/-hmmm+`.-/++osssmmmo/:-.....:+/:.../s    //
//    ..........-..........----.......+mmmmms/.`````````.````:mmmmmo.-dmmm:..---....-mmh........-//-......    //
//    ..........-...........----....-smmmy:...`````..........ymmmmy..sdmd/...--.....ommo.......-//-.......    //
//    ........................-----+dmmm+...................:dmmmd-./dddd/...--.....hmm:......-::-........    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JC is ERC721Creator {
    constructor() ERC721Creator("CARDELUCCI", "JC") {}
}
