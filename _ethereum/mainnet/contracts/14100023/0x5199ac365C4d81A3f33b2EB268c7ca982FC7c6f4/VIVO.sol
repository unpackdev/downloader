
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vivo: My eye and around.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//    [size=9px][font=monospace]   "φ   "",                         ░   ≥╔φσ, , ,╓░░φ░;░╠░░"Γ  «φ╚φ▒░ φφφφφ░«╠φ░    //
//         ░  ]░'                    ≈"-,«=φ░ ⁿ   ░░░░ⁿ╙╚░^╚░░░░░░≥, '«╠φ╩░,φ╚░φ╠░░╠▒φ                              //
//          "  "",                    """ `«       ,"╙ ,φφφφφ░░ⁿ╔ε»²░"≈≥╚φ░░╔φφ░░░"╔╠φ                              //
//           `≥≥,╚,                  "    «"       `.φ╠╢╣╬╣╣╣▓▓▓╣▒░φ"▒,""░^"░░≥«╙╚5░░≈                              //
//     `ⁿ      [░ⁿ≥,                      .       ' "╙╚╫▒╚╚╠╬╠╬╝╠╚▒╠φ░░, ,≥»"`░,╓φ░░δφ                              //
//               ░╠░φ≥░≥=`  -           -αφ, ,    -.φ░≥╙╚╚╙= -,╓φ░╙╠φ▒╣φ░,  ░░░"[;╙╙φ░                              //
//    ⁿ        -φ╚░",ⁿ`=                 , "`╓  "  ░="  ╔φ  "φδ░╠░ φ╙▒"'.   ░ε░ ░└.φφ░                              //
//            «░  ,"      ]              [    `ε   ░╓░░╔╣▒╠σ,σ#▒╣▒░░-~⌐ ,╓    ⁿ&gt;≥ "░                             //
//        ,φ░░  -∩ "   ,φ░φ░ "           `     7   ░╙╙≤╚╠║▒╚╠╩╬╠╠╙▐▒φ",«╔╚ε ≤,"` ".                                 //
//    -φ≥░`   .,ⁿ»  =δ@╙#ε╙"                 `     "  ;  «φ  "^╚φ"≈╙"`░7φε "⌐» `    `-                              //
//    ░≈═,,   ⁿ╓#≈@▒░.▄-]║▒                  '      = ,  ,"',`░φ╚,   "░     ]'                                      //
//    ░╙╝╚▒#φ╬▒▄,,,░╚φ░╠▒╠╬Q,,                      "≥░φ≈╠╠╠▒╩╚"φ╠φµ «φ  .           ,                              //
//    ▒╚   ▒é~.,..,,  '"¡╙▒░Σ╚φφ≈▒&gt;-       `         "░ⁿ╙╚╚╙",░≥╚║╣▒╚╚▒▒▄▓Æ»        ⁿ=                           //
//    ░░   .-""-≤φφ╠▒▒▓▒▒φ║║░"≥%.░ "φ\           ,σφ░╬╚     -░5░░╚╬╣▒  ╣╣╩░░░╚╚▒φ╔ `-ⁿ                              //
//    ▐    ''[«"░╠╠╠╠╠╣╣▓╣▒▒░]░▐▐   ▐φ1        ,≥"╙╙╠░       ≥«».«σ╝╩╔▓╠░░""░φ░╠╠╠▒α"░                              //
//    ╠      ░░φ╠φ╠╠╠║╣╩╩╝╬╬⌐,`]╚   ]╚εε     .░ⁿ    φ░       ░░φφ╓╔░╔╣╬▒ ".░░░░╚╠╠╬▒ ;                              //
//    ▒      !░░╚╠╠╬╠░╩╩╚φ╣▒δ   ▐    ░╠]    »""    ╠░╩▒▄     ]╠░░░ⁿ╔╣╣▒φ,  ░░░░░╠╠╠╠                                //
//    ⌐     ╓Qµ░░╚╠╠╣╣▓▓▓▓╩╬Θ   ░    ░║░ε  ⁿ     φ╠░░░░╚░  "  """"@╠╠╩ ╙╙≥ '"░]╠░╠╠╠⌐`                              //
//         ▒φε╙░░░░╚╠╠╠╠╠╬▒▒╣▒φ▄░░   ▒╚▒╚ ',░    ╔░░  ░╦╓µ▄▄▄Q╓,╔╠╠╠╚⌐     "≥"-░░╠╠╩                                //
//    φ≤«φε└╩╢φφ░░░░░╚╚╚╠╠▒╓░║▒╙▀▒   ▒φ▌▐░░░░.  φ░░░░ⁿ░╚╚╚╙╙╠╩╚╚╠╣╣▒░ε .,   ╚╠φ▒░╚░╙                                //
//    ╣╣╣╬▓╗εⁿ░░░░░░░░░░░░░░╔▓▓▓▒║'  ≥░║░▒░░░'.φ╩φ░╙»≤╚▒▒▒@@╗▄╓╓╔φ▒░╚╚φ,░- «╠╠╠╠▒φ░ε "                              //
//    ╚║▒φφε╓,'░░=≥░░░░░░φφ▓█▓█▓▓▒░~`Γ`║▒ε"`╓#╠╠╠╩░"╔░╙╙╚≥░╙░╙╙╚╝╝╣▒░╚φ╠⌂  ░≈░╙╢╬╠▒ε ░                              //
//    ╬╫▓▓▓▓▒║▒▒▄▄░░░ⁿ";╔╣╣▓███╬▓▓░ -╡'╠▒╞φ╠╠╚╚╚≥=` ╚░░φφ░==»╓,,,,'"░░╚╙░`.░]░╚╠╩╠╠φ [                              //
//    ░╬╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓███▒╠╣╣▓▓╗▓φ╠╠╠╠░░░░░    ░░░φ░"""`=└╙╙╙= `«░╚╔ :░»░░╓╔╠╠░ ⁿ                              //
//    :░╚╚░╚╣▓▓▓▓▓▓▓▓▓▓▄╠▒╬╠╣▓▒░░╚╚╠╠╬░░╚░░░░░ -φδ╠▒░φ░░░░ⁿ≤░░░░    -»"≥░░≥░'"░░φ╚╚╠⌐,                              //
//    [/font][/size]                                                                                                //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VIVO is ERC721Creator {
    constructor() ERC721Creator("Vivo: My eye and around.", "VIVO") {}
}
