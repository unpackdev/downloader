
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Danny Kass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ,$$llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll$@,    //
//        $lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllllllllllll||@|W|g|@l|lllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllllllllLgg@@@@$@@$@$@@@M|llllllllllllllllllllllll    //
//        lllllllllllllllllllllllllllllllllllll]@@@@@@@@@@@@@@@$@@llllllllllllllllllllllll    //
//        llllllllllllllllllllllll|||lllllll|g%$@@$$$$@@$@$$$M*%$@llllllllllllllllllllllll    //
//        llllllllllllllllllllllg@@MM%@|l|g$@@@@"|||||||||R||||j@@|l@@glllllllllllllllllll    //
//        llllllllllllllllllll|@$|||||{%@$@@@@|||,dMlllW||]w$Q|v$@M$%M$@llllllllllllllllll    //
//        llllllllllllllllllll@$L||||l"|%@@@@|||$l$$$ll$||M$jl$jM||}||]@Wlllllllllllllllll    //
//        lllllllllllllllllll$@@||||L||||@@@@|||5mw,,wg@g@@TMM$F|||j||@@llllllllllllllllll    //
//        llllllllllllllllllll@$w||||||||@@@%@gwwgm**||||||||j$k||||g$M|llllllllllllllllll    //
//        llllllllllllllllllll]@$g|||||||@@@@$$$||@NM||||*j|MMN@||g$$|llllllllllllllllllll    //
//        lllllllllllllllllllll|%$@%ggg@@@@@@M|||||F*|lwwWwgI|MN%@|lllllllllllllllllllllll    //
//        llllllllllllllllllllllll||||||jM$2Mj2mMT||||lll|l||||TT%Mw"yllllllllllllllllllll    //
//        llllllllllllllllllllllllllllj|*|gg@$W%RFT%M@MY%Tj[ll|]ll$j@@llllllllllllllllllll    //
//        llllllllllllllllllllllllllllj|y|%%l@l$@|$$l%||jgi@l$L#MlA@M|llllllllllllllllllll    //
//        lllllllllllllllllllllllllllll]wl&@l|}4WiLl$Llll|#lllWjW$@|llllllllllllllllllllll    //
//        lllllllllllllllllllllllllllll{?@@g||l|||l||Lll|l|||g@FMK|lllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllj$@%@@||||||M"||||w|||||Mlllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllj@$%$$@@g||||||||||||;4|llllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllj@@@@$$$%@@@@M%%%TT||lllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllll$@@@@@@@@$$$@lllllllllllllllllllllllllllllllllllll    //
//        lllllllllllllllllllllllllllllj$@@@@@@@@@@@$lllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllg%@@@@@@@@@@@@@@|lllllllllllllllllllllllllllllllllll    //
//        lllllllllllllllllllllllll|g$$@@@@@@@@@@@@$@@$@g|llllllllllllllllllllllllllllllll    //
//        lllllllllllllllllll|@g@%$$$$@@@@@@@@@@@@@@@@@@@$$@@gllllllllllllllllllllllllllll    //
//        llllllllllllllll|g%$@@@@@@@@@@@@@@@@@$@@@@@@@$$@@@@@%@llllllllllllllllllllllllll    //
//        lllllllllllllll#$@@@@@@@@@@@@@@@@$M%%@@@@$@@@$@@@@@@@$@lllllllllllllllllllllllll    //
//        llllllllllllll]@@@@@@@@@@@@@@@$M||||]@@@@$@@$$F||%@$@@$lllllllllllllllllllllllll    //
//        llllllllllllll@@@@@@@@@@@@@$N||||||||||||MN@$Y||||j$$@$lllllllllllllllllllllllll    //
//        \llllllllllllj@@$@@@@@@@@@@|||||||||||||||||\||||||]@@$WlllllllllllllllllllllllF    //
//                                                                                            //
//                                                                                            //
//                                BAYC 4893                                                   //
//                                By Danny Kass / @dannygkass                                 //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract BAYC4893 is ERC721Creator {
    constructor() ERC721Creator("Danny Kass", "BAYC4893") {}
}
