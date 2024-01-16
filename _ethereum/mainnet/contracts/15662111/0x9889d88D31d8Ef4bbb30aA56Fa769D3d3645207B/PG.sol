
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paintings by Georgesketch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    |||'__||T|L|j$$$$$$lllllllllllllllllM$$@@@$$$$$$$$$@@@lllllllllllllll|l||ll|Ll$$    //
//                                                                                        //
//    ,ggggg@,;g@$$$$$$$$$$$llllllllll&$$@$$$$$$$$$$$$$$$$$$$@llllllllllllllllllllll&$    //
//                                                                                        //
//    $$$$$$$$$$$$$$$$$$$$$$lllllll&g$$@$$@$$&lllT||l|l$$$$$$$$@lllllllll||lllllllllll    //
//                                                                                        //
//    $$$$$$$$$$$$$$$$$l$&Ml&$lllll@@$$$$@MTll||||'||||$$$$$$$$$@lllllll%@|lllllllllLl    //
//                                                                                        //
//    $$$$$$$$$$$$$$$$$$lLlL|T|llM@$$@$Mlllll|||L_||l||$&$$$$$$$$@llllll|lll|l|llllllL    //
//                                                                                        //
//    $$$$$$$$$&$$@$@@@$@$$$ill|lll%$5|gg@@@@@@@@$L|j@@@B@@@@@{$$$lllllllllllllllllll|    //
//                                                                                        //
//    |ll@@@@@@$@$@@@$@@$$$$TllLW&$lL|j$M$T|s|$$@$$L,@@NMM*1&$%$$@Wlllllllllllllllllll    //
//                                                                                        //
//    |$@@@@$$$$$$$MMMM$MlL||||||ll*lL`$@$@@@gg$@@$g@@@$@@@@$$$$$@lllllllll|llllllllll    //
//                                                                                        //
//    l|l%%%MMMMMW$l'''l' __ _ _'`____,gMg$@gg@@$M$M$$@Q$@$g@$$$$Wlllllllll|llll||||||    //
//                                                                                        //
//    @@@$@lww@ggwgwg&ggwg@&&@&gwggLg@$$lMMM$@M$@$W$$@&g*%5ll$$$@lllllllllllLll|l|||||    //
//                                                                                        //
//    $$$$$$@$$$$$$$$$$$$$$$$$$$$@@@$$$',l&T|ll@$$T|$$$&$M$$&iM$@@N$@lLlllllll||||||||    //
//                                                                                        //
//    $$$$@@@@@@$$$$$$$$$$$$$$$M@$@@$@ll||lll@$@@@|l$@$` |"T||l$@j$$@lLl|lllll||||||||    //
//                                                                                        //
//    $$@@@$$$$$@@$$$$$$$$$$$$$$j$@@@$@Ll|lll$N@@@R$$&$W, _||l$$M@@M|lllll|l|||l||||||    //
//                                                                                        //
//    $$@@@$$l$$$$W$$$$$$$$$$$$$$MB@$@$@|L|||g@@NM@@N@@@@@L;l$$@@$MllLlLl|l|||||||wl||    //
//                                                                                        //
//    $$@$$$@@$$$$@$$$$$$$l$l$$$$$$j@@$@@L|@@$@@$$@@$@@$@@@$@$$@$lllLlLlLlLllL||||||||    //
//                                                                                        //
//    $@$@$@@@@@i$@@$$$$$$$l$$$$$$$$#@@$$$$B@$$$&}&$$@@@$$@$@$$Tlllll|l|lll|l|||||||||    //
//                                                                                        //
//    $@$$@@@@$@LQ@$@$$$$$$$$$$$$$$$$j@@@$$$@l$@@@@@@$Tl$@$@$@|lllll|lllllll||||||||||    //
//                                                                                        //
//    @@$@@@@@@@@@@@$@$$$$$$$$$$$$$$$$#@@@@@$$$$M{lll$%$@@@@|llllllllll|l|llll||l|||ll    //
//                                                                                        //
//    @$@$@&M$T|l%$$R@@$$$$$$$$$$$$$$$@$@@@@@@@@@@@@$@$@@@@@$$llLllllllLl|lllllllllll|    //
//                                                                                        //
//    @$@$@$l$llll]$@$@$$$$$$$$$$$$$$$@$@@@@@@@@@@@@@@@@@$$$$$$$lllllllllllllllllllll|    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract PG is ERC721Creator {
    constructor() ERC721Creator("Paintings by Georgesketch", "PG") {}
}
