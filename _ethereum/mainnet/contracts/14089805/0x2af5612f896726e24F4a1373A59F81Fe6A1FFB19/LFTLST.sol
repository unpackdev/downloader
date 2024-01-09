
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LeftLost
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
//        llllllllllllllllllllllllllllllllllllll||lWF**""IJ,,,,`"*|lllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllll|lF*"}=jTl|||lllllllll|*',|lllllllllllllllllllllll    //
//        lllllllllllllllllllllllllll^`,gl|lllllllllllll|lFp2=Ql|lllllllllllllllllllllllll    //
//        lllllllllllllllllllllllll|  *WllllllWW{@p%FMsTl||l@jl|llllllllllllllllllllllllll    //
//        llllllllllllllllllllllllll|||lll|||||l||*||||||||||||||lllllllllllllllllllllllll    //
//        llllllllllllllllllllllll|||lllllll||||||||||||||||||@#|yllllllllllllllllllllllll    //
//        lllllllllllllllllllll|M|g@M@@|l|||||||*'  |- `""h$0` j|[|lW@Llllllllllllllllllll    //
//        llllllllllllllllllll|C4"|||*l@P|*Wwg@@@@@@@@@@@@]wg%*=j$@jT%Ljllllllllllllllllll    //
//        lllllllllllllllllll|L|L^`| /^"$|||]"@@@@@@@@@@@KM$$$kjM"`} "|lWlllllllllllllllll    //
//        lllllllllllllllllll||M |||C|||"|||$| "B@@@@@@$%MWb@m$@|||j|,M/llllllllllllllllll    //
//        lllllllllllllllllll||\w|||r|||,W||%&wwy*"2l| ' -DL;,,"c|-`/|4|llllllllllllllllll    //
//        llllllllllllllllllll|||L||`|,^`L|||w*|\,*MM$$W |IM%$lw""x|6|llllllllllllllllllll    //
//        lllllllllllllllllllll|yg]Tr=gl]Qw*|||||l*T|+.|`|Y,|+`"Qw||llllllllllllllllllllll    //
//        lllllllllllllllllllllll|||||||j||||**"",,,,,gg,,,;,gw|,*|lllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllll[||j L[`]    ]     [    L[|lllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllQ|||C], @bg,g@NgggQ%N@$a|lllllllllllllllllllllllll    //
//        lllllllllllllllllllllllllllllj@|||]L"$@l|T%Wl|T&$$$%Flllllllllllllllllllllllllll    //
//        lllllllllllllllllllllllllllll||@|$|\| \]**W$$|l&&bww4{"|llllllllllllllllllllllll    //
//        lllllllllllllllllllllllllllllll|&$@@K||,x,  [     L  #,Wllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllj||ji$j@,   L|*MWwmN+*|l~Mllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllj|||||||%@@g |`  - |`-",$lllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllll$|||||||||||F||%M=w+=j|lllllllllllllllllllllllllll    //
//        lllllllllllllllllllllllllllll|||||||||||||llllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllll2||||||||||||||\|lllllllllllllllllllllllllllllllllll    //
//        lllllllllllllllllllllllll|@|||ww||||||||||l||%g|llllllllllllllllllllllllllllllll    //
//        lllllllllllllllllll|wM*|||||||||||||||||||||||||||MQllllllllllllllllllllllllllll    //
//        llllllllllllllll|M||||||||||||||||||/||||||||||||||||wllllllllllllllllllllllllll    //
//        lllllllllllllll#|||||||||||||||||||@[@L||||||(@@|||||||lllllllllllllllllllllllll    //
//        llllllllllllll]||||||||||||||||c'  |]@@@g$||||L' v||||$lllllllllllllllllllllllll    //
//        llllllllllllllA|||||||||L|||z" ||||||" ""*&|]P`|||}$||j|llllllllllllllllllllllll    //
//        \lllllllllllljM/|gL|||||W|@`|||||||||||||||`}||||||]||JWlllllllllllllllllllllllF    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract LFTLST is ERC721Creator {
    constructor() ERC721Creator("LeftLost", "LFTLST") {}
}
