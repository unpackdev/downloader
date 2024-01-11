
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIND POLICE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::lddoolllcccc:::::::::::::::::::::::::::::::::::::::::::::::::::cc::::::::::::::loolcc:::::::::::::::::::::::::::::    //
//    :::::::::::::::::::::::::::::::::::cOWWWNNNXXXKOdc:::::::::::::::::::::::::::::::::::lkkxolc:::::lkXKxl::::::::::::o0NNXKOxoc:::::::::::::::::::::::::    //
//    :::::::::::::::codddoollc::::::::::cOWMMMMMMMMKdc::::::::::::::::::::::::::::::::::::dXMWNXKOkxdkXWMMWXOdc::::::::::xNMMMMMNKdc:::::::::::::::::::::::    //
//    :::::::::::::::coOXNNNNXK0Okdlc::::cOWMMMMMMMWOc:::::::::::::::::::::::::::::::::::::dXMMMMMMX0OKWMMMMMMNOl:::::::::l0WMMMMMMNx::::::ccc::::::::::::::    //
//    :::::::::::::::::cokXWMMMMMMWX0xl::cOWMMMMMMMWOc:::::::::::::::::::::::::::::::::::::dXMMMMMWkc:xNMMMMMW0o:::::::::::kWMMMMMMNx:::::lkK0dl::::::::::::    //
//    ::::::::::::::::::::lkXMMMMMMMMWXxccOWMMMMMMMWOc:::::::::::::::::::::::::::::::::::::oXMMMMMWOc:dNMMMMMWOc:::::::::::oOXNWWN0dc::::o0WMMWKkl::::::::::    //
//    ::::::::::::::::::::::oONMMMMMMMMNklOWMMMMMMMWOc:::::::::::::::::::::::::::::::::::::oXMMMMMWOc:dNMMMMMW0xkOOOOOOOOkOOO0XXXKOOOOOO0XWMMMMMWXkc::::::::    //
//    :::::::::::::::::::::::cdKWMMMMMMM0oOWMMMMMMMWOc:::::::::::::::::::::::::::::::::::::oXMMMMMWOc:dNMMMMMWOdxxxxxxxxxxxxxxxxxO0Okxxxxxxxxxxxxxoc::::::::    //
//    :::::::::::::::::::::::::l0WMMMMMNklOWMMMMMMMWOc:::::::::::::::::::::::::::::::::::::oXMMMMMWOc:dNMMMMMWOc::::::::::::::::l0NXK0kxdlc:::::::::::::::::    //
//    ::::::::::::coxxxxxddolcc:lkKXXK0xccOWMMMMMMMWkc:::::::::::::::::::::::::::::::::::::oXMMMMMW0ookNMMMMMWOcclllcccdOxl:::::dXMMMMMWKko:::::::::::::::::    //
//    ::::::::::::cokKWMMWWNNX0Oxocclc:::cOMMMMMMMMWk::::::::::::::::::::::::::::::::::::::oXMMMMMWX00KWMMMMMWOcdXNXXXKXNNXOoc:ckWMMMMMKkO0OOkkkxdl:::::::::    //
//    :::::::::::::::lxKWMMMMMMMWN0xc::::l0MMMMMMMMNx::::::::::::::::::::::::::::::::::::::oXMMMMMWOlcxNMMMMMWOcxNMMMMMW0ONWN0ooKMMMMMNxkWMMMMMWKxl:::::::::    //
//    :::::::::::::::::cdKWMMMMMMMMW0l:::lKMMMMMMMMXd::::::::::::::::::::::::::::::::::::::oXMMMMMWOc:dNMMMMMWOcxNMMMMMWklkNMMNXWMMMMWOlkWMMMMMWk:::::::::::    //
//    :::::::::::::::::::cxXWMMMMMMMWkc::oXMMMMMMMMKo::::::::::::::::::::::::::::::::::::::oXMMMMMWkc:dNMMMMMWOcxNMMMMMWkcckWMMMMMMMW0l:kWMMMMMWk:::::::::::    //
//    :::::::::::::::::::::lOWMMMMMMWkc::xNMMMMMMMM0l:::::::::cdxoc::::::::::::::::::::::::dXMMMMMWkc:dNMMMMMWOcxNMMMMMWkc:lOWMMMMMMKo::kWMMMMMWk:::::::::::    //
//    ::::::::::::::::::::::ckNWMMWNOl::cOWMMMMMMMWkc::::::::o0WWN0dl::::::::::::::::::::::dXMMMMMWkc:dNMMMMMWOcxNMMMMMWkc::l0MMMMMWOc::kWMMMMMWk:::::::::::    //
//    :::::::::::::::::::::::coxkkxoc:::oKMMMMMMMMXo:::::::cxXWMMMMWXkoc:::::::::::::::::::dXMMMMMWkc:xNMMMMMWOcxNMMMMMWkc::ckWMMMMMNkc:kWMMMMMWk:::::::::::    //
//    :::::::::oxxxxxxxxxxxxxxxxxxxxxxxk0WMMMMMMMMXkxxxxxxkKWMMMMMMMMWN0dc:::::::::::::::::dXMMMMMWX00KWMMMMMWOcxNMMMMMWkc::dXMMMMMMMNxckWMMMMMWk:::::::::::    //
//    :::::::::okkkkkkkkkkkkkkkkkkkkkkkKWMMMMMMMMXOkkkkkkkkkkkkkkkkkkkkkdc:::::::::::::::::dXMMMMMNkooONMMMMMWOcxNMMMMMWOc:l0WMMMMMMMMXdkWMMMMMWk:::::::::::    //
//    ::::::::::::::::::::::::::::::::o0WMMMMMMMXd:::::::::::::::::::::::::::::::::::::::::dNMMMMMXo::dNMMMMMWOcxNMMMMMWkccOWMWNWMMMMMWOkWMMMMMWk:::::::::::    //
//    :::::::::::::::::::::::::::::::l0WMMMMMMMW0xoollc::::::::::::::::::::::::::::::::::::xNMMMMM0l::dNMMMMMWOcxNMMMMMWklxNMNkd0MMMMMMK0WMMMMMWk:::::::::::    //
//    ::::::::::::::::::::::::::::::oKWMMMMMMWX0XWWNNXK0Okxdoc:::::::::::::::::::::::::::::kWMMMMWk:::dNMMMMMWOcxNMMMMMWOkNWKdc:xWMMMMMKOWMMMMMWk:::::::::::    //
//    ::::::::::::::::::::::::::::lkXMMMMMMMNOl:lx0NWMMMMMMWNX0kdlc:::::::::::::::::::::::cOWMMMMKo:::dNMMMMMWOcxNMMMMMWNNXkl:::dXMMMMNkkWMMMMMWk:::::::::::    //
//    ::::::::::::::::::::::::::cdKWMMMMMMNOoc:::::lxKNMMMMMMMMMWN0xlc::::::::::::::::::::c0MMMMNkc:::dNMMMMMWOcxNMMMMMMNOo:::::cd0KX0xckWMMMMMWk:::::::::::    //
//    ::::::::::::::::::::::::lxKWMMMMMWKkoc:::::::::coOXWMMMMMMMMMWNOo:::::::::::::::::::oKMMMW0l::::dNMMMMMWOcxNMMMMMWOc:::::::::ccc::kWMMMMMWk:::::::::::    //
//    :::::::::::::::::::::cdOXWMMMMWKOdl:::::::::::::::lkXWMMMMMMMMMWXxc:::::::::::::::::xNMMWKolddddOWMMMMMWOcxNMMMMMWkc::::::::::::::kWMMMMMWk:::::::::::    //
//    ::::::::::::::::::ldkKWMMMNX0koc::::::::::::::::::::lxKWMMMMMMMMMXd::::::::::::::::cOWMWKo:cdkKWMMMMMMMW0kXWMMMMMWXOOOOOOOOOOOOOOOXWMMMMMWk:::::::::::    //
//    ::::::::::::::coxOXWWNX0Oxoc::::::::::::::::::::::::::lkXWMMMMMMMNx::::::::::::::::oKMW0l:::::oKMMMMMMMNxok0NWMMMW0xdddddddddddddd0WMMMMMWk:::::::::::    //
//    :::::::::cldkO0KK0Oxdoc:::::::::::::::::::::::::::::::::oONMMMMMNOl:::::::::::::::ckNXxc:::::::xNMMMMWNkc::clxOKXkc:::::::::::::::kWMMMMMWk:::::::::::    //
//    :::::::::oxxxdolc::::::::::::::::::::::::::::::::::::::::cdkO0Okdc::::::::::::::::oOOl:::::::::dKNXK0xoc:::::::clc::::::::::::::::xNWNNX0xl:::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cc:::::::::::cllcc::::::::::::::::::::::::::::::looolc::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::MIND POLICE:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::         //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::a kefan404 project::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::     //
//    :::::::::::::::::::cdddddooollc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::lxxkkkxdol:::::::::::::::::::::::::::::::::::    //
//    :::::::::::::::::::oKWWWWWNX0xlcooc:::::::::::::::::::::oO0xl::::::::::::::::::::::::::::::::::::::::::::lONMMMMWNX0dc::::::::::::::::::::::::::::::::    //
//    :::::::::::::::::::oXMMMMMMXd:lkNNKkl::::ccc:c:::cccccoONMMWXOoc::::::::::::::::::::::::::ll::::::::::::::cxXMMMMMMMNd:::::::::::::::ldoc:::::::::::::    //
//    :::::::::::::::::::oXMMMMMMNkdKWMMMWXOdxO000OOOOOOOO00NMMMMMMMN0dc:::::::::::::::::::::::dK0l::::::::::::::ckNMMMMMMXd:::::::::::::lkXWNOoc:::::::::::    //
//    :::::::::::::::::::oXMMMMMMWK0KKKKXNNKOdodKKxooooooookNMMMMMMMWKkl:::::::::::::::::::cldONMN0xxxxxxxxxxxxxxxONMMMMMWKkxxxxxxxxxxxxOXWMMMMN0dc:::::::::    //
//    :::::::::::::::::::oXMMMMMMXdcccco0NNOdc::xX0l::::::cOWMMMMMMWOl:::::::::::::::::::lk0XWMMMMXOO0K0OOkkkkkkkkkkkkkOOkkkkkkkkkkkkkkk0NMMMMMMMN0o::::::::    //
//    :::::::::ccccccccccdXMMMMMMXdcccxXWMMMN0xllOWKxc:::ckNMMMMMMW0l:::::::::::::::::::oKWMMMMMMWkco0NXK0Okxdoc:cll::::odc::::::::::::oONMMMMMNKkxl::::::::    //
//    ::::::::cxOOOOO00OOKNMMMMMMWKO00XNNNNNNNXOooKMW0dccxNMMMMMMWOl::::::::::::::::::::xNMMMMMMMXol0WMMMMMWXOdox0NXkoc:o0kc:::::::::oONMMMMNKkoc:::::::::::    //
//    :::::::::loook0Oxdoo0WMMMMMWKOOkxdooooooolc:dXMMWK0NMMMMMMXxc:::::::::::::::::::::lONMMMMWKdo0WMMMMMMNOxkKWMMMMN0dlkXK0OOOOOOO0XWMMMMMNkl:::::::::::::    //
//    ::::::::::::l0WWNKOkKMMMMMMW0ONWNX0kdc:::::::dXMMMMMMMMMN0o::::::::::::::::::::::::cokkOkdlo0WMMMMNKOOO0NMMMMMMMWNOxKWNOxdddddONMMMMMMWXOl::::::::::::    //
//    :::::::::::ckNMMMMMNNMMMMMMWklkWMMMMWKxc:::::cxNMMMMMMMMNOdlc::::::::::::::::::::::::::::cxXWMMMMWKxlccxNMMMMMMWKdlcdXWNOoc::lOWMMMMN0xlc:::::::::::::    //
//    :::::::::::dXMMMMW0x0WMMMMMWOcl0WMMMMMNk::::cxKWMMMMMMMMMMWNX0Okxol:::::::::::::::::::::lONMMWKKWMMWNOkXMMMMMMWOl:::cxXMMN0dlxNMMWKkoc::::::::::::::::    //
//    ::::::::::oKMMMWKxccOWMMMMMWOc:dXMMMMMWkc:lkKWMMWNXWMMMMMMMMMMMWKkoc::::::::::::::::::lkXWWXOdcl0WMMMWWMMMMMMXxc:::::cxXMMMWXNWXkoc:::::::::::::::::::    //
//    :::::::::oKWWN0xc::cOWMMMMMWkc:cxKNNXKkdxOXWWNKOxlld0NWMMMMMMW0dc:::::::::::::::::::lk0KOOXNK0kddxk0NMMMMMMN0o:::::::ccdKWMMMMWN0kdoc:::::::::::::::::    //
//    ::::::::oKNKkoc:::ld0WMMMWWXx::::cldxk0KXK0kxoc::cdkxdkKNMMMNkc::::::::::::::::::::codoc::xXMMMWOoxXWMMMMWKdc::::::cx0OddONMMMMMMMWNX0Oxdolcc:::::::::    //
//    :::::::coxoc::::::xNWMMWKOdlc::::ldxkkxdlc:::::cd0WMWKkddk0Kkc::::::::::::::::::::::::::::cOWMMMNXWMMMMWKxlcccccccdKWMMWXOOKNMMMMMMMMMMMWNXKOdc:::::::    //
//    ::::::::::::::::::xNMMMMWNX0OOOOOOOOOOOOOOOOOOO0NMMMMMMN0xllc::::::::::::::::::::::::::::::ldOXWMMMMWXKK00000000O0XNNNNNNNXOxOXWMMMMMMMMMWKxoc::::::::    //
//    ::::::::::::::::::xNMMMMMMWKxxxxxxxxxxxxxxxxxxxONMMMMMMMWKdc::::::::::::::::::::::::::::::cokKWMMWXOdcclooooooooooooooooooolccdOKNMMMMMMXxc:::::::::::    //
//    ::::::::::::::::::xNMMMMMMWOc::::::::::::::::::oXMMMMMMMXd:::::::::::::::::::::::::::::clx0NWWX0koc:::::::::::::::::::::::::cxKXK0O0XNWXd:::::::::::::    //
//    ::::::::::::::::::xNMMMMMMW0ollllllllllllllllllxXMMMMMMMXo::::::::::::::::::::::::::ldk0KXKOkdoccccccccccccccccccccccccccccd0WMMMWX0xxxoc:::::::::::::    //
//    ::::::::::::::::::xNMMMMMMMX0OO000000000000000OKWMMMMMMMXo::::::::::::::::::::::::coxkxdolcdO00000000O000000KKKKKKKKK0OO000KNNNNNNNNXOl:::::::::::::::    //
//    ::::::::::::::::::xNMMMMMMWOlccccccccccccccccccdXMMMMMMMXo:::::::::::::::::::::::::::::::::cllloOX0kdollllokNMMMMMMMKdloooollllllloollc:::::::::::::::    //
//    ::::::::::::::::::xNMMMMMMWOc::::::::::::::::::oXMMMMMMMXo::::::::::::::::::::::::::::::::::::ckNMMWKOdl:::xNMMMMMMM0lok0OOOkkxdocc:::::::::::::::::::    //
//    ::::::::::::::::::xNMMMMMMMKkkkkkkkkkkkkkkkkkkk0NMMMMMMMXo:::::::::::::::::::::::::::::::::::lOWMMMMMMWX0xlxNMMMMMMM0lcokXWMMMMWNX0kdc::::::::::::::::    //
//    ::::::::::::::::::xNMMMMMMMKkkkkkkkkkkkkkkkkkkkONMMMMMMMXo:::::::::::::::::::::::::::::::::cxXWMMMMMMWN0kdlxNMMMMMMM0l:::lxKWMMMMMMMWKkl::::::::::::::    //
//    ::::::::::::::::::xNMMMMMMWOc::::::::::::::::::oXMMMMMMMXo::::::::::::::::::::::::::::::::o0NMMMMMMNK0Oxxdx0WMMMMMMM0l:::::cdKWMMMMMMMWKd:::::::::::::    //
//    ::::::::::::::::::xNMMMMMMWOc::c:::::::::::::::dXMMMMMMMXo::::::::::::::::::::::::::::::oONMMMMWX0xocldx0NWMMMMMMMMWOc:::::::cxKWMMMMMMM0l::::::::::::    //
//    ::::::::::::::::::xNMMMMMMMX0O00OOOOOOOOOOOOOOOKWMMMMMMMXo:::::::::::::::::::::::::::coOXWWWX0kdl:::::::ckNMMMMMMMMNd::::::::::lONMMMMMMKl::::::::::::    //
//    ::::::::::::::::::xNMMMMMMNOoooooooooooooooooookXMMMMMMW0o:::::::::::::::::::::::::coOKK0kxoc::::::::::::lKMMMMMMWKxc:::::::::::cdKWWWN0o:::::::::::::    //
//    ::::::::::::::::::xXWNNX0kdc:::::::::::::::::::lOKKK0Oxdl::::::::::::::::::::::::::clolc:::::::::::::::::cONNXX0Odl:::::::::::::::loddlc::::::::::::::    //
//    ::::::::::::::::::cooolc::::::::::::::::::::::::cccc::::::::::::::::::::::::::::::::::::::::::::::::::::::lollc:::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MiPo404 is ERC721Creator {
    constructor() ERC721Creator("MIND POLICE", "MiPo404") {}
}
