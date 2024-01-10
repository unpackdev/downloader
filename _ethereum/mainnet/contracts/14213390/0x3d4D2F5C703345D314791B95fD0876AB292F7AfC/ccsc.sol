
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: devastatindave.eth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                        //
//                                                                                                                                                        //
//    NWWWNNNNNNNNNNNNNNKxc;;;;;;;;;;;;;;;;;;;;;;;::::::;;;;;;;;:ccl:;;;;;,,;;;;;cc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cxKNNNNNNNNNNNNNNNNNNW    //
//    NWNNNNNNNNNNNNNNXkl;;;;;;;;;;;;;;;;;;;;;coxkOOOOOkkkxdlc;:lc;;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lkXNNNNNNNNNNNNNNNKX    //
//    NNNNNNNNNNNNNNN0o;;;;;;;;;;;;;;;;;;;;;ck0Oxolcc:cccodxkkkxdc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:o0NNNNNNNNNNNXOxcd    //
//    NNNNNNNNNNNNNXxc;;;;;;;;;;;;;;;;;;;;;o00o:;;;;;;;;;;;;;:coxkkxoc;;;;;;;;;;;;;;;;;;;;;lo:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ckXNNNNNNX0xl::;d    //
//    NNNNNNNNNNNN0o:;;;;;;;;;;;;;;;;;;;;;l0Ol;;;;;;;;;;;;;;;;;;;;cdkkkdc;;;;;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:dKNNXOxl:;;;;;d    //
//    NNNNNNNNNWNOl;;;;;;;;;;;;;;;;;;;;;;:k0o;;;;;:lc;;;;:lc;;;;;;;;;cokOkoc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lxdl:;;;;;;;;d    //
//    NNNNNNNNNXkc;;;;;;;;;;;;;;;;;;;;;;;l0Oc;;;;;:c:::;:oOxc;;;;;;;;;;;cokOxlc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;:;;;;;;:ck    //
//    NNNNNNNNXx:;;;;;;;;;;;;;;;;;;;;;;;;o0kc;;;;;;;;cc;;:c:;;;;;;;;;;;;;;;lxO0Od:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::;;;;;;;cd0N    //
//    NNNNNNNXx:;;;;;;;;;;;;;;;;;;;;;;;;;o0Oc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:ldOOxc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;:;;:::;;:;:cd0XNW    //
//    NNNNNNXx:;;;;;;;;;;;;;;;;;;;;;;;;;;l00c;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:ok0kl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::;:;;:::lxKNNNNW    //
//    NNNNNXk:;;;;;;;;;;;;;;;;;;;;;;;;;;;:k0o;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lk0kl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::;;::;;:xXNNNNNW    //
//    NNNNNOc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;dKk:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lk0xc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::;;;:::;;;;;;cONNNNNW    //
//    NNNNKl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cO0l;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lkOd:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;oKNNNNW    //
//    NNNXd:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;dKk:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:oOOd:;;;;;;;;;;;;;;:::::::;;:;;;;;;;;;;;;;:;;;;;;;;;;;:xXNNNW    //
//    NNNOc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ckKd;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:dOOo:;;;;;;;;;:::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;cONNNW    //
//    NNKd;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;l00l;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cx0kl:;;:;;:;;:::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;dXNNW    //
//    NNOc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;dKOc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lk0xc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cONNW    //
//    NXd:;;;;;;;;;;;;;:codxxkkOOkkxxdolc;;;;:xKk:;;;;;;;:lodxkkOOOkkxxdol:;;;;;;;;;;;:loddddddx0X0xdddddddddddl:;;;;;:codxxkkkkkkxxddoc:;;;;;;;;:xXNW    //
//    N0l;;;;;;;;;;;cdk0XNNNNNNNNNNNNNNXKOxl:;:kKx:;;:cdOKXNWWWWWNNNNNNNNXKOdlc:;;;;cx0XNNNNNNNWWWWNNNNNNNNNNNW0c;;:ox0KNNNNNNNNNNNNNNNX0ko:;;;;;;oKNW    //
//    NOc;;;;;;;;:oOKNNNNNNNNNNNNNNNNNNNNNNXOo;ckKxldOXNWNNNNWWNNNNNNNNNNNNNNXKOl:;l0NNNNNNNNNNNNWNNNNNNNNNNNNW0llkKNNNNNNNNNNNNNNNNNNNNNNNKd:;;;;cONW    //
//    Xx:;;;;;;:d0NWNNNNNNNNNNNNNNNNNNNNNNNXkl;;ckXXNWNWWWWNWWNNNNNNNNNNNNNNNX0kc;ckNNNNNNNNNNNWNNNNNNNNNNNNNNWX0XWWWNNNNNNWNNNNNNNNNNNNNNN0o;;;;;:ONW    //
//    Xd;;;;;;cONWNNNNNNNNNNNNNNNNNNNNNNNXOl;;;;l0NWNNNNWNNWWWNNNNNNNNNNNNNXOl:::;l0WNNNNNNNNNNNNNNNWNNWNNNWNNNNNNNWNWWNNNWWWNNNNNNNNNNNN0d:;;;;;;:xXW    //
//    Xd;;;;;cONNNNNNNNNNNXOxdolloodkKNN0o:;;;;l0NNNNNNNNNNNXOxdoooodxOKNNOo:;;;;;cONNNNNNNNNNNNWX0OOOO0XNKO0XNNNWWWWWWNNN0kdolllodx0XNKxc;;;;;;;;;oKW    //
//    Ko;;;;:xNNNNNNNNNNXkl;;;;;;;;;;:oo:;;;;;:kNNNNNNNNNNXkl:;;;;;;;;;coo:;;;;;;;;oXNNNNNNNNNNNW0o:;:::oOOloKWNNNNWNNWN0o:;;;;;;;;;:loc;;;;;;;;;;;oKW    //
//    Ko;;;;l0WNNNNNNNNXx:;;;;;;;;;;;;;;;;;;;;oKWNNNNNNNNXd:;;;;;;;;;;;;;;;;;;;;;;;;dKNNNNNNNNNNNNKkl:;;;ck00NWNNWWWNNNOc;;;;;;;;;;;;;;;;;;;;;;;;;;oKW    //
//    Xd;;;;oKWNNNNNNNN0l;;;;;;;;;;;;;;;::::::dXNNNNNNNNW0c;;;;;;;;;;;;;;;;;;;;;;;;;;lONWNNNNNNNNWNNXkl;;;ckXWWWNNNNNWXd;;;;;;;;;;;;;;;;;;;;;;;;;;;oXW    //
//    Xd;;;;oKWNNNNNNNWKl;;;;;;;;::::::;;:;;;;dXNNNNNNNNNXkc;;;;;;;;;;;;;;;;;;;;;;;;;;:dKNWNNNNNWWNWNNXx:;;l0NNNNNWNNWXd;;;;;;;;;;;;;;;;;;;;;;;;;;:xXW    //
//    Nx:;;;c0WNWNNWNNWNx:;::::::::;;;;;;;;;;;lKNNNNNNNNNNN0o:;;;;;;;;;;;;;;;;;;;;;;;;;;cxKNWNNNWWWWNNWNOc;:kNNNWNNNNNN0l;;;;;;;;;;;;;;;;;;;;;;;;;cONW    //
//    NOc;;;:xNWNNNNNNNNXOoc:;;;;;;;;cddc;;;;;:kNNNNNNNNNNNNXkl;;;;;;;;cdd:;;;;;;;;;;;;;;;:xXWNNNNNWNNNWNOc;oKWNNNNWWNNN0dc;;;;;;;;;:odl;;;;;;;;;;c0NW    //
//    WKl;;;;cONWWWNNNWNNNX0kxdooodxOKNN0d:;;;;cONNNNNNNNNNNNNKkdooodxOXNN0xddddddddxxxxxdxOXWNWNNNNNNNWWNx;;dXWNNWNNWWNNNKOxdooodxk0XNXkc;;;;;;;;oKWW    //
//    WXx:;;;;ckXWNNWNWNNWNNWWNNNNNWNNNNNNOo:;;;cOXNNNNNNNNNNNWWNNNNWWNWNWNWWWWWWWNNNWWWWWWWWNNNNWWWWWWWWWOc;:dKNNNNWWWWNNWWWNNNNNNNNNNNNKxc;;;;;:xNNW    //
//    NKxc;;;;;:o0NWNNWNNNWNNNNNNNNNNNNNNNNXOl;;;:o0NNNNNNNNNNNNNNNWWNNNWNNNNNNNNNNNNNNNWNWNNNNNNWWWWWWWNNO:;;;lONWWWNNWWNNNNNNNNNNNNNNNNNN0o:;;;l0NNW    //
//    xxxo:;;;;;;:okKNWNNNNNNNNNNNNNNNNNNNNXkl;;;;;:okKNWNNNNNNNWNNNNWWNNNNNNNNNNNNNNNNNNWWWWWNNWWWNNNNWWKl;;;;;cOKKXNNNNWWNWNNNNNNNNNNWWNX0d:;;:dXNNW    //
//    XNNOc;;;;;;;;;:oxOKXNNNNNNNNNNNNXX0kdc;;;;;;;;;;cok0XXNWWWWWNWWWWWWWWWWWWWNNNNNNNNNWWWWWWWWWWWWNNKxc;;;;;;;dOoldOKXNNWWWWNNNNNNNXKOxl:;;;;l0NNNW    //
//    NNWXx:;;;;;;;;;;;;clodxxkkkkxxdolc:;;;;;;;;;;;;;;;;:clodxkkkkkk0NNKOkkkkkkkkkkkkkkkkkkkkkkkkkkxdl:;;;;;;;;:dOx:;;:lok0Okkkk0XKkolc:;;;;;;:xNWNWW    //
//    WNNWKo;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:o0NXOdc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cdOOc;;;;;co:;;;;:oo:;;;;;;;;;;oKNNWNW    //
//    NWWNNOc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ckXNNKklc:;;;;;;;;;;;;;;;;;;;;;;;;;;;cc;;;;;dkl;;;;;;;;;;;;;;;cl:;;;;;;;l0NNNWNW    //
//    NNNNWNkc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lo:;;;;;;;;;;;;;;;;;:oOXNNXKOl;;;;;;;;;;;;;;;;;;;;;;;;;;cc;;;loxOo;;;;;;;;;;;:lc:ll:;;;;;;cONWWWWWW    //
//    NNWWNWXx:;;;;;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;:c:;;;;;;;;;;;;;;;;;;;:ok0XXKd:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:cdOo;;;;;;;;;;;;::;;;;;;;;;ckNWWWWWWW    //
//    WWWWNWWXx:;;;;;;;;;cl:;;;;:oo:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:ccc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:xOl;;;;;;;;;;;;;;;;;;;;;;ckNWWWWWWWW    //
//    WWWNWNNWXx:;;;;;;;;::;;;;;:::;;;;;;;;;cc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cc;;;;lOk:;;;;;coc;;;;;;;;;;;;;ckNWWWWWWWWW    //
//    WWWWWWNNWXkc;;;;;;;;;;;;;;cl:;;;;;;;;;cc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cc;;;lOkc;;;;;;:loc;:::;;;;;;;cONWWWWWWWWWW    //
//    WWWWWWWWWWNOl;;;;;;;;;;;;;;;:ol;;;;;;;;;;;;;;;;;;col;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lc;;;;:cllcc:;;;;;;;;;:okOxc;;;;;;;:oOxccoc;;;;;;l0NNNWWWWWWWWW    //
//    NWWWWWWWNNWNKo:;;;;;;;;;;;;;;::;;;;;::;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::;;;;;;:cclllllodddddxxdc;;;;;;;;;;:c:;;;;;;;;:dKNNNWWWWWWWWWW    //
//    NNWWWWWWWWWNNXkc;;;;;;;;;;;;;;;;;;::;;;;;;;c:;;;;;;;;;;;;;;;;;;;;;cc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;:cccc:;;;;;;;;;;;;;;;;;;;;;;;;ckXWWWNNWWWWWWWWW    //
//                                                                                                                                                        //
//                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ccsc is ERC721Creator {
    constructor() ERC721Creator("devastatindave.eth", "ccsc") {}
}
