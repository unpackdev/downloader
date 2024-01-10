
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grand Rising DAO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    $$$$$$$$$$$$$$$Wl$$$li$$ll$$ll$$ll$$l$$$l$$ll$$l$$$l$$$l$$$ll$$$l$$$$$$$$$$$$$$$    //
//    llllll$$lll$l$llll$l$lll$lll$l$lillllll$llll$l$llllll$lll$llllll$ll$l$ll$$$lllll    //
//    ll$$lll$ll$l$ll$l$lll$lll$l$llllll$lLlllllll$llll$l$llll$lll$ll$l$l$ll$l$lll$$ll    //
//    llllll$ll$ll$lllll$ll$llll$l$l|&W*^""``````"""**&|llill$l$l$l$l$ll$lMll$l$ll$lll    //
//    lllllllll$llll$lllllll$lL$P"                        "*&|$lll$lll$llll$llll$ll$ll    //
//    |Wlllljlllllllll$$ll$lP`                                 *&llllllll$lllll@lllll|    //
//    Ll|yll|WVllllllllllr`                                       "&lllllllllll|lll|l|    //
//    W@llllV|lYllllll$"                                             Vlllllll||@${|l$W    //
//    |T5gl|lll|llll$`                                                 \llllWlll|llM||    //
//    lllllllll|@llC,                                                  ,,@ll|lllllllll    //
//    $|llllllllllllll|l&y,                                      ,<&$|llllllllllllll|$    //
//    |||||lllllllll@M*******E***$$$**************************$F******My|llllllll|||||    //
//    lllllllllllllll&,,,gg$$llllllllll$%wg,,,,,]$|||||||||||||||l$$Mw$lllllllllllllll    //
//    llll{lllllllllllyM|llllllllllllllllllj['''@llllllllllllllllllllll%ll|illlllMllll    //
//    H$$|ljllllljQQl&|llllllllllllllllllllljM&&@llllllllll@@gllllllllll$@MlllllLl|$@M    //
//    A$|lljllllllr @llllllllll@BB@@lllllllllP  @llllllllllP*R$@llllllll[ llllllLll|$$    //
//    IFlll$$Wllll@$|lllllllll@lll]@@@@@@@@@@lll@llllllllll@ll$Mlllllll@W#llllj$$lll]@    //
//    L|lll||@l$$$L$llllllllllP  @ll|||||||||j  @llllllllll|||llllll|@P  j$$$ljM|lll|@    //
//    EllllllF@W$lj@llllllllllP ]@lllllllllllj  @lllllllllllllllllll||%   W$jg'Mlllll$    //
//    @llllllLk@$@A@|lllllllllk,]@gggllllllllj,,@llllllllll|||lllllllllj,,]lj4,|lllll]    //
//    Illlllll`W"``$@||||||||||$Z$$$@||||||||]``@||||||||||@B@||||||||||F``"$`]llllll]    //
//    @llllll|gMmmmj@@|||||||||||||||||||||||]mm@||||||||||Mm$@|||||||||$mmmMM@llllll]    //
//    Sllllll|i      %@@|||||||||||||||||||||]  @||||||||||P ]@|||||||||]    )||lllll$    //
//    E|llllll|$llllll&%@@@g,||||||||||||,ggg$ll@,,,,,,,,,,Wll@g,,,,,,,,,BlllWllllll|@    //
//    L|||||lll|L         "*N@@@@@@@@@NNM*""    MMMMMMMMMP`   ]**PMMMRRM`  ,Mlll|||||$    //
//    A@ll||||ll|%********************************************************j|lL|||lll]@    //
//    S$||lll|||ll}                                                      /|L|||llL||@@    //
//    S||||||ll|||||k                                                  ,$L|||lL|||||||    //
//    I|||ll||||ll|||lw                                              ,$|||llL|||llL|||    //
//    El|||||ll|||ll||||M,                                         xl|||lL|||llL||||lL    //
//    ||||ll||||l||||l|||l|x,                                   ,$|L||lL|||lL|||ll||||    //
//    ||||||||l||||l|||lT||l||T~,                           ,g||l|||l|||lL|||lL|||||L|    //
//    |||||||||||l||||l|||l|||l||||Ty~,              ,,wsTl||lL||lL||ll|||lL||||l|||||    //
//    |||||||||l||||l|||lT|||l||lL||l||lL||||ll|||||l||lL||l|||l|||l|||lL|||lL||||||||    //
//    ||||||||||||l||||l|||lT||lT||lL||l||lL|lL||l|||!||l|||l|||l|||lL|||l||||||||||||    //
//    ||||||||||||||||l|||lT|||l|||l||l|||l|||l||lL||l|||l|||l|||l||||L|||||||||||||||    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract GRDAO is ERC721Creator {
    constructor() ERC721Creator("Grand Rising DAO", "GRDAO") {}
}
