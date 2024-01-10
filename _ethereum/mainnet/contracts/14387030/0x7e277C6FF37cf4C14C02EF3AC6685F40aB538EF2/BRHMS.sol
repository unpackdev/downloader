
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bear Homies NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMWWMMMMWWMMMMMMMMMMMMMMMMMMMMMM      //
//                                                                                                                                  //
//                                                            ,--,    ,----..             ____                                      //
//        ,---,.     ,---,.   ,---,       ,-.----.          ,--.'|   /   /   \          ,'  , `.   ,---,    ,---,.  .--.--.         //
//      ,'  .'  \  ,'  .' |  '  .' \      \    /  \      ,--,  | :  /   .     :      ,-+-,.' _ |,`--.' |  ,'  .' | /  /    '.       //
//    ,---.' .' |,---.'   | /  ;    '.    ;   :    \   ,---.'|  : ' .   /   ;.  \  ,-+-. ;   , |||   :  :,---.'   ||  :  /`. /      //
//    |   |  |: ||   |   .':  :       \   |   | .\ :  |   | : _' |.   ;   /  ` ; ,--.'|'   |  ;|:   |  '|   |   .';  |  |--`        //
//    :   :  :  /:   :  |-,:  |   /\   \  .   : |: |  :   : |.'  |;   |  ; \ ; ||   |  ,', |  ':|   :  |:   :  |-,|  :  ;_          //
//    :   |    ; :   |  ;/||  :  ' ;.   : |   |  \ :  |   ' '  ; :|   :  | ; | '|   | /  | |  ||'   '  ;:   |  ;/| \  \    `.       //
//    |   :     \|   :   .'|  |  ;/  \   \|   : .  /  '   |  .'. |.   |  ' ' ' :'   | :  | :  |,|   |  ||   :   .'  `----.   \      //
//    |   |   . ||   |  |-,'  :  | \  \ ,';   | |  \  |   | :  | ''   ;  \; /  |;   . |  ; |--' '   :  ;|   |  |-,  __ \  \  |      //
//    '   :  '; |'   :  ;/||  |  '  '--'  |   | ;\  \ '   : |  : ; \   \  ',  / |   : |  | ,    |   |  ''   :  ;/| /  /`--'  /      //
//    |   |  | ; |   |    \|  :  :        :   ' | \.' |   | '  ,/   ;   :    /  |   : '  |/     '   :  ||   |    \'--'.     /       //
//    |   :   /  |   :   .'|  | ,'        :   : :-'   ;   : ;--'     \   \ .'   ;   | |`-'      ;   |.' |   :   .'  `--'---'        //
//    |   | ,'   |   | ,'  `--''          |   |.'     |   ,/          `---`     |   ;/          '---'   |   | ,'                    //
//    `----'     `----'                   `---'       '---'                     '---'                   `----'                      //
//                                                                                                                                  //
//    MMMMMMMMMNOdoodx0WMNNNNNXXWXXWMMMMMNNWKKWMMWNWMMMMMMMMWWMMMMMMMMMMWWMMMMMMMMMMMMWX0000KXNMWWMMMMWNNMMMMMMMMMMMMMWWMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:'''''',;cokXWMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,.;ooollc:,'.':xKWMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:,',lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.'oo;..',:looc,.'cONMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc'.';cc;.,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc.;o; .;,'...,:oo:'.;xXWMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:..:loclod:.'OMMMMWWWWWWWWMMMMMMMMMMMMMMMWWWNO'.co. ;dl;;,..'ldddc'.'kWMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd..:ol;...;oc. 'cc:::::;;::::::::::ccccc::::;;,'.;oo' .,,,,,:ldddddo,.'kWMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWk..cd:. .'..::,,,,;;;;::::::::;;;;;;;;;;;;;:::cclodddl:,.....,cddddc..lKWMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..lo:..''..:dddddddddddddddddddddddddddddddddddddddddddol:,...:oo:.'kWMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'.,col,..;odddddddddddddddddddddddddddddddddddddddddddddddoc:co:.'OWMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd,.,lc;cdddddddddddddddddddddddddddddddddddddddddddddddddddddo'.dWMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.'ldddddddddddddddddddddddddddddddddddddddddddddddddddddddl..OMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc.;ddddddddolcclddddddddddddddddl;'.':odddddddddddddddddddo..xMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk',oddddddc'.  .,lddddddddddddo;.     'lddddddddddddddddddo'.dWMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;:ddddddc.      ,odddddddddddc.       ,ddddddddddddddddddd,.lNMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.;dddddo,       .lddddddddddd,        .ldddddddddddddddddd:.;XMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:.:dddddl.        :ddddddddddo.        .:ddddddddddddddddddc.'OMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;.cdddddc.        ,odddddddddl.         ;ddddddddddddddddddo'.xMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'.cddddd:.        ,odddddddddc.         ;ddddddddddddddddddd,.lNMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO..lddddd:       .,ldddddddddd:.      ..;lddddddddddddddddddd:.:XMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.'oddddd:      .:lddddddddddd:.     .;lddddddddddddddddddddd:.;XMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.,odddddc.       .lddddddddddc.       .;oddddddddddddddddddd;.:NMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.,ddddddo,       ,oddddddddddo'        ,oddddddddddddddddddd,.lWMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.;dddddddo;.   .,lddddddddddddl'      'ldddddddddddddddddddl..xMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.,dddddddddoc:clddo:''',:loddddo:,..':odddddddddddddddddddd:.,KMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.,odddddddddddddddc.    .,cdddddddddddddddddddddddddddddddo'.dWMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk..lddddddddddoooodoc,.',codddddddddddddddddddddddddddddddd;.;XMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,.;clodddddc'......''',,;;;;;::::::cccloddddddddddddddddd:.'OMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.  .:dddddl,.      ...'''....         .:odddddddddo:'.,,..kWMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdol..cdoddddl:,......'',,''..     ...';lddddddddoc'.;l' .xWMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo..'.;oddddddolc:;;,,,,,,;;::clooddddddoodddc' .oKWXk0WMMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXOkxdc.    'lolldddddddddddddddddddddddddo:...;:,...,;:cldOXWMMMMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl:;,,;;;;'..'.....cddddddddddddddl:cl:lddl;...;'. .,lddolc:,,;cd0WMMMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;';coddddddoooo;. ...:;,':ll;'.':l:. .. .''..,codoc:lddddddddddl:,,:xXMMMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXc.;oddddddddddddddlcl;...,'....',....':;;;..':ldddddddddddddddddddddo:';xNMMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMK:.:dddddddddddddddddddollodo:;coddo;';odddddoddddddddddddddddddddddddddo;.oNMMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMK:.:ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo;.dWMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMMXc.:ddddddddddooddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl.;KMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMMNl.:ddddddddddl,,codddddddddddddddddddddddddddddddddddddddoloddddddddddddddddo,'kMMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMMMWd.;oddddddddddd:..'ldddddddddddddddddddddddddddddddddddddd;.',cddddddddddddddd:.oWMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMMWXd',oddddddddddddo, .ldddddddddddddddddddddddddddddddddddddo,  .cdddddddddddddddl',OWMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMMWk,.'ldddddddddddddd:.'odddddddddddddddddddddddddddddddddddddo' .cddddddddddddddddo' .kWMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMWKl..,odddddddddddddd;.;ddddddddddddddddddddddddddddddddddddddl..cdddddddddddddddddo;..oNMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMM0;..codddddddddddddl,..lddddddddddddddddddddddddddddddddddddddl..ldddddddddddddddddo;. ;0MMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMWd.'odddddddddddddo:. ,odddddddddddddddddddddddddddddddddddddc. 'odddddddddddddddddo'.o0NMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMXc.cddddddddddddddo, .cdddddddddddddddddddddddddddddddddddddd;. ,odddddddddddddddddo,'OMMMMMMMMMMMMMMM      //
//    MMMMMMMMMMMMMMMMMMO''oddddddddddddddd:..odddddddddddddddddddddddddddddddddddddd:. ,ddddddddddddddddddo,'OMMMMMMMMMMMMMMM      //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BRHMS is ERC721Creator {
    constructor() ERC721Creator("Bear Homies NFT", "BRHMS") {}
}
