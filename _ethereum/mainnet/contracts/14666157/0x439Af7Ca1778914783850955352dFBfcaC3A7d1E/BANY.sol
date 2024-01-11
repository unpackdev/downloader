
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Being Anything
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxllllkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MNKKKKKKKKKKXNMMMMMMMMMMMMMMMMMMM0;....:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXO0NWKOKWMMMMMN0OXMNO0NMMMMMMMMMMMMMM    //
//    Wx..........'kWMMMMMMMMMMMMMMMMMMWXKKKKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0odO0xodOKNMMMXxok0kook0XWMMMMMMMMMMM    //
//    Wo     'lc.  'coKMMM0occcccclOWMMXdccccxXkll0MNxccccoKMMMMMWNOlcccl0MNxcoKMMMMMMMMMWWKdlkKkooOXNWMWXkld00dlxKNWMMMMMMMMM    //
//    Wo     :Ok,  ..,ON0Oc   ..   ;O0NO.    ,Oc  :Ok:..  .o0KNN0Ok;   ..lOx' .xMMMMMMMMMMMWNKxld00dlkNWMMNXOookKkldKWWMMMMMMM    //
//    Wo           oXXWk.    ;0Kc    .dO.    ,Oc    .dXO'    ,Od.     cK0:.   .xMMMMMMMMMMMMMWX0kook0xoxXMMMNKOdoxOOdo0WMMMMMM    //
//    Wo     ,ol.  ':l0x.    .;:.     ok.    ,Oc    .xMK,    .Oo      oWX;    .xMMMMMMMMMMMMMW0xxkkxxxk0NMMMXkxxkxxxxOXMMMMMMM    //
//    Wo     lWX:    .xx.    ..'''''',kO.    ,Oc    .xMK,    .Oo      oWX;    .xMMMMMMMMMMMN0kxdxkkxx0WMMWKOkxxxkxdkXMMMMMMMMM    //
//    Wo     lNX:    .xx.    ;0XXXXNNNWO.    ,Oc    .xMK,    .ko      lNX;    .xMMMMMMMMMNKOdok0kodKWMMWK0xldOOdoOWMMMMMMMMMMM    //
//    Wo     .,,.  ;xkXXkx;  .,;;;;kWMMO.    ,Oc    .dMK,    .OKkdo,  .,,.    .xMMMMMMMMWOldKNklxXWWMMMXdlON0oo0WWMMMMMMMMMMMM    //
//    Wk;,,,,,,,,,:OMMMMMMO:,,,,,,;kWMMKl,,,,oKx;,,,:OMXo,,,,lKMMWNk;,,,'.    .xMMMMMMMMMNXNWMNXNWMMMMMWNXWMWNXWMMMMMMMMMMMMMM    //
//    MWWWWWWWWWWWWMMMMMMMMWWWWWWWWMMMMMWWWWWWMWWWWWWMMMWWWWWWMMMMMWNXXN0;    .kMMMMMMMWXKKKKKKKKKKKKKKKKKKKKKKKKKKKXWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNx,'''..  :kONMMMMMMMXxcclcccccccccccccccccccllcccdXMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNk:::::::c0MMMMMMMMMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXNWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOoooodKMMMMMMMMM0doood0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMNXXXXXXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXNWMMMNc    .dMMMMMMMMWd.....dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWd.......'kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:....:KMMMNc    .dMMMMMMMMMNK000KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    W0oc.  'c:.  ,ldKKolkWW0olxMaKerOfErRoRsxNMKollllxdl;.    .:llkKc     ,lllldXMMM0olllo0XxldXMKdllllkNMMMMMNxlllldXMKdlxN    //
//    Wo     oWX:    .xx. ,k0l..   :Ox,..     ,KMd.  ..:;..      ...c0c     ...  .o0KNo     oO' .d0d'..  'kKXWXKx'  ..,xKo. ,K    //
//    Wo     oWX:    .xx.  ..c0K:   ..lKx.    ,KMd. ;0XNXXx.    'kXXNNc     lKk'   .,Oo     lO'   .,kXo.   .l0c..  .dKx'.   ,K    //
//    Wo     .c:.    .xx.    cNWl     oWO.    ,KMd. :XMMMM0'    ,KMMMNc    .dMK,    .ko     lO'    '0Mx.    :O;    .OMO.    ,K    //
//    Wo     ...     .xx.    cNWl     oWK:..  .dOo'.oNMMMM0'    ,KMMMNc    .dMK,    .ko     lO'    '0Mx.    :O;    .OMO.    ,K    //
//    Wo     lX0;    .xx.    cNWl     oWWNNx.    ;0NWMMMMM0'    ,0MMMNc    .dMK,    .ko     lO'    '0Mx.    :0;    .kMk.    ,K    //
//    Wo     oWX:    .xx.    cNWl     oWMMMk.    ;KMMMMMMMNkd:. .,::dKc    .dMK,    .ko     lO'    '0Mx.    :KOdl.  ';'     ,K    //
//    Wk;,'';kWNd,,,':0O:'',,dNWx,',';kWMMM0c'.  ;KMMMMMMMMMMKc',,',oKx,,,';OMXl,,',c0k;',',kKl',,'lXM0:',,,dNMMXl,,,,.     ,K    //
//    MWWWWWWWMMWWWWWWWWWWNWWWMMWWWWWWWMMWWWNXd. ;XMMMMMMMMMMMWWWWWWWMWWWWNWWMMWWWWWWMWWWWWWWMWWWWWWMMWWNWWWWMMMWNNNNNx.    ;K    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl,,,,:dk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo,,,,.  .lk0W    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl;;;;oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;;;;;;oXMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BANY is ERC721Creator {
    constructor() ERC721Creator("Being Anything", "BANY") {}
}
