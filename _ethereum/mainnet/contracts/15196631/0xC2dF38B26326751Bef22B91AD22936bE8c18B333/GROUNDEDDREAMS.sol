
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GROUNDED DREAMS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//             _              _           _      _                  _             _            _          _             //
//            /\ \           /\ \        /\ \   /\_\               /\ \     _    /\ \         /\ \       /\ \           //
//           /  \ \         /  \ \      /  \ \ / / /         _    /  \ \   /\_\ /  \ \____   /  \ \     /  \ \____      //
//          / /\ \_\       / /\ \ \    / /\ \ \\ \ \__      /\_\ / /\ \ \_/ / // /\ \_____\ / /\ \ \   / /\ \_____\     //
//         / / /\/_/      / / /\ \_\  / / /\ \ \\ \___\    / / // / /\ \___/ // / /\/___  // / /\ \_\ / / /\/___  /     //
//        / / / ______   / / /_/ / / / / /  \ \_\\__  /   / / // / /  \/____// / /   / / // /_/_ \/_// / /   / / /      //
//       / / / /\_____\ / / /__\/ / / / /   / / // / /   / / // / /    / / // / /   / / // /____/\  / / /   / / /       //
//      / / /  \/____ // / /_____/ / / /   / / // / /   / / // / /    / / // / /   / / // /\____\/ / / /   / / /        //
//     / / /_____/ / // / /\ \ \  / / /___/ / // / /___/ / // / /    / / / \ \ \__/ / // / /______ \ \ \__/ / /         //
//    / / /______\/ // / /  \ \ \/ / /____\/ // / /____\/ // / /    / / /   \ \___\/ // / /_______\ \ \___\/ /          //
//    \/___________/ \/_/    \_\/\/_________/ \/_________/ \/_/     \/_/     \/_____/ \/__________/  \/_____/           //
//           _            _           _            _                  _   _         _                                   //
//          /\ \         /\ \        /\ \         / /\               /\_\/\_\ _    / /\                                 //
//         /  \ \____   /  \ \      /  \ \       / /  \             / / / / //\_\ / /  \                                //
//        / /\ \_____\ / /\ \ \    / /\ \ \     / / /\ \           /\ \/ \ \/ / // / /\ \__                             //
//       / / /\/___  // / /\ \_\  / / /\ \_\   / / /\ \ \         /  \____\__/ // / /\ \___\                            //
//      / / /   / / // / /_/ / / / /_/_ \/_/  / / /  \ \ \       / /\/________/ \ \ \ \/___/                            //
//     / / /   / / // / /__\/ / / /____/\    / / /___/ /\ \     / / /\/_// / /   \ \ \                                  //
//    / / /   / / // / /_____/ / /\____\/   / / /_____/ /\ \   / / /    / / /_    \ \ \                                 //
//    \ \ \__/ / // / /\ \ \  / / /______  / /_________/\ \ \ / / /    / / //_/\__/ / /                                 //
//     \ \___\/ // / /  \ \ \/ / /_______\/ / /_       __\ \_\\/_/    / / / \ \/___/ /                                  //
//      \/_____/ \/_/    \_\/\/__________/\_\___\     /____/_/        \/_/   \_____\/                                   //
//        ____  ____  _________    __  ________    ______  __   __    ___  ____________   _______  __                   //
//       / __ \/ __ \/ ____/   |  /  |/  / ___/   / __ ) \/ /  / /   /   |/_  __/ ____/  / ____/ |/ /                   //
//      / / / / /_/ / __/ / /| | / /|_/ /\__ \   / __  |\  /  / /   / /| | / / / __/    / /_   |   /                    //
//     / /_/ / _, _/ /___/ ___ |/ /  / /___/ /  / /_/ / / /  / /___/ ___ |/ / / /___   / __/  /   |                     //
//    /_____/_/ |_/_____/_/  |_/_/  /_//____/  /_____/ /_/  /_____/_/  |_/_/ /_____/  /_/    /_/|_|                     //
//                                                                                                                      //
//    PJYB#7J7JJ7#&&&&&&&&&&&&&&&&&&&&&&####################################J#5####5GYBBYBPBYYJJB##YJ?JB##              //
//    GBJ???7&GP55&&&&&&&&&&&&&&&&&&&&&&####################################PGBJY!7G777YGPY?5555GGJJYP&B5P              //
//    GGG5G&B5GBB#&&&#BBBBGGGP55555555555555555555555555555555GGGGGGGGGGB&##P@&G?55BB?!YJ?7??7!!7?JPGGJG#Y              //
//    J?PG#PGPB#P#&&&#GGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGB###BBBB&G?7?7!JJYP7!7##?7Y5J55BJG              //
//    YGGGYPBBB#B#P&&&BGGGGGGGGGGGPPPPP&#B#BPP55PPPPPPPPPPPPPPPPGPGGGGGGB###577!~!77!!J5BPPY77?77!!7GGB5#7              //
//    ?JYG5&PB#GG&P&&&BGGGGGGGGGGGPPPP######BBGP5PPPPPPPPPPPPPPPPGGGGGGGB###B#B?7!~!YPJBGGBGGJ?!!77775G57?              //
//    !7777YPPPP#B#&&&#BGGGBGGGGGGPPPP##&####BBPPPPPPPPPPPP5P?YGGGGGGGGGB#####&#Y55!PJ5#BPPYP#!?7G##77!~PG              //
//    7#&?!7!Y?BP#G&&&#GGGGGGGGGGGGPPPP###5B#GPPPYPPPPPPPP:^PPPPPPGGGGGGB####PYBY5G&PBGGBJ5YGP5!!7!!7!#!!~              //
//    77?!!7B577?#B&&&#BBGGGGGGGGGGGPPPGPBPGGG#PPPPPPPPGP5??J~~PPPGGGGGGG####&PP5PY#P&#GGPPP55BGY!?PBP#J!B              //
//    G5G!!?PG?7PBJP&&#BBBGGGGGGGGGGGGGPGGB&GG#&??Y^!!!GGPPGG^GPPGGGGGGGB###GG55GJGPY5P5PBB5YYBJGBPJB5!!P~              //
//    GB#G5!777?#JBP&&&GGBBBBGGGGGGGG~77?7J&BBB?77JY!?J?~PP5PGGGGGGGGGGGB###PPB777!~JBP5PP5PBGGPYJB?J~!!Y5              //
//    P&GGBB?7G##BYG&&&BGGGGBBGGGG!~~!77?J~J55??!~J^~!^~^^G!BGGGGGGGGGGGB##&!~?YB#!!G5J5G55YPPJB#PJ!!!7Y?!              //
//    P&G&#YJ???7JY5&&&BBBBBBBBBGP~!~!~!77~~YJ7^^~~~^!5Y7~!~~7BGGGGGGGGGG&&##J!?JP5YJPJG5G5PG5G5B!!YG!!!?7              //
//    PG&G?#Y#PG##BY&&&@@@@@@@@B7?YP7J~:^^^~^~J:^??Y#77?PPY^&&&&&GBP#&&@@@@@@&BYYY?PPJP5YY5555JPY57!!!775G              //
//    GY5PG&#B#BGBGGG&&&BBB#&&B?~~~!?^:^~!?~~^^::::~J7P?G55&&&&&&GP#&&@@&&BB&&@#GBG5BGPPG5GYYP555Y5Y?P5GBP              //
//    BBPBBG#BB#GGGGPPPPP@#&GJ!~^^^:~!^^?P???J:....^:J!J~^P#B&&PY#B&&&@@@@&&&#@@#&J##J~J?PP#G5PPPGGGGYY55Y              //
//    #YBPG#!!!!!!#BGPGPY#&&J!!^^:5~^~77.7!7.~.   .:^7:~YPG&@&G#&&&@@@@@@@@##@&@@&77BYGP5G5YYG~?G75J5JP5PP              //
//    #5BP7!7?PP77!!#GG55GPG&B~^^~?J^YGB~..^:.    .:::#G&&##&G&&&&@@@@@@@&@&#B&@@@&PJJ?PP5P5^^?777!!!75!JP              //
//    #GG?777GB#P?!5GPY5JP&@@&#G^..PPBP5?^7J:.7  .?~##&&B&&#&&&&@@@@@@@@PG@@@PG&P&@BJ7B5GP5!~!P#GY!!57!?G?              //
//    5GP577!7?777?Y5?P&&@@###&#Y:B!YPGBB?:..~?~B&&J&&&&&&#@#@&&@&&@@@@555Y@&&#B#P#@#YP77YJ^?~^!~~!!7!!Y55              //
//    JYPBBJ7?YJJJP5&&&@&&BB&B7&55PP5PPBG5^?:~P#&&7&&&&&&&&&@&&&&@@@@@J?YJY5#@&&#BG#@#YPBJ?~JY##7?JY^JGY#P              //
//    YYY5BG5P5Y&&@@@B##&&&~^BGP!#?!?P5?GY7~7#&#&@&&&&&&&&&&@@&#&@@@@PJ75YPPJ?5&&&GPB&#5P5JBYY&BYY7PPPY5~G              //
//    YJ5JJ5&&&@&&&@&57Y5!~BBJ#YP7J5777Y?J7?#B##&#5&&&&&&&&&@@@&&&&##B#G#PYJ5?J55&&BPG&GYB5GGPBJYG&##&55YB              //
//    YJ#&&GP5&&&JYP5J!??J#J755GPJ!GPJBGJ?PJJ&&&&&B&&&&&@@@@@@@@@&77J##75JY?P?YGY#?&@GB&G5P&!77~7P55P555PB              //
//    JB&&&@&#&PP5PY5PYY#PBB?!B#G##PYYJ555BPB&B&#P@&&&&&@@@@@@@##BP5GP#&?G~7JJJ!5PG?&@&G&#!!7#G!!7P5G^!77G              //
//    G5&&@@BYYY5YYYYYP##?J??Y#B#B&#B#7GPP??&&&J@&&&&&&&@@@@@@@@#P#??Y5&JJYG5!J?G5GP#&@&G@@&#!!7?PP7!!~~??              //
//    7YYPBBG7G5YYJ5PYYYYYY5PY?5GPPGPG&@5G5#&&G#&&&&&&&&@@@@@@@&&B#@##Y&JPP5JYYJPP?7#&&&&&#@&#&#@~~~!77~~~              //
//    ~!?!YP:Y5P5PYYYY55YYY5YJBP5J?J?5JYP#G#&##&&B&&&&@@@@@@@@&&&PJ5YY?P@G5YY5555G5JP#&&##&!!!J&&~^~GBBY~^              //
//    !!!!7J5YYPG5~!55555555P55#PJY~YYJJ&YB@B&&@Y5P#&&&@@@@@@@&#GG7!&YY5Y7?&#GYJGGP!?J&!7!~!GBG?!?^~~~!!~~              //
//    ~^^~!?5PPGG!!?PGGGP!BP?BP##PPPYYGY#YBG#&&G5Y5P&&&&@@@@@@&&G#GJ^&!5JJYGG5GYGJ!7?JJ?B~~!5PP7!~~7?~~5?G              //
//    P5!:!JY55PGGYYB###GPPP5PG#BPGG@&@@&#5P5&@B5BPG#BB#&&@@&&@&&?JJ~~&7~^~5GGG.BB5B5B5G#&&!!P!!~~?5B#!~~B              //
//    YJ^:?77??!!5J?JPPY5PJBPG##P&P#5?#&YP5GPG&&B#YPGPGP#&&&&&&&@@@#?!~P!~G^GBPBGG#&GG~!~##&GPY7~~~7?!~~~B              //
//    ?JJJPPJ??77JP?P5BG###&#JB#?5JJ&?J555P55!?7&5GGGPG5?&&&&#G#P&@@@&&B#G?^^^GP~G::##G~!~BG5?5#57B!~!!~5P              //
//    ?YYYGGY??5PG&BGBGYGB5JJPJ7J&#5&###B#5!!G#!PY@J?~^JJ5J&&&&@PB5&@&@@@@&5~!~~5?~^J~~JPP5!!7?J5P77777B?7              //
//    P5PPGGYY77GJG5BB#B#?!~P&557??7Y!77!~!!!!?YP#PPPPBP#PB#Y#&&&&&P#BGGP@@&&&?^^#~^!!~~~~!~55B??P5?!7~5PG              //
//    P##PGPPPGJ:?7J!Y5G57G&PBGPPY!7!^77PGGJG?777!!7!!7JP7Y77&#B&&@@&GP7BPB&&&&~!?5~G!!~BGB7?PPP?YYJ?BPGY5              //
//    PGGBPPY5GJ!~!J?!!P##7!YPPG?!!!!!!BPG5?57!?!?!JJ5?7?7!YYYY55PG&@@&#P5BP&@&#7!~~!JGB5G#Y~!!7!~~~~PYG5J              //
//    BBBGJP5YYY!!PG5J7!&?!!!!!!!7PP5PJ^B!!!!!!~~~JP??~YYJY?JY?Y?##Y!5G&&&BPY5@&&&#7!JJ!J5J~~~!PBG?~~!GB55              //
//    BBPB~JY5Y5Y!7!J7&#~!!GGG5?!!!!Y7!?5!!!YBGG!~~!Y5?PJ?#7!J!Y~Y#77!J777#&&&G5&&&&#J7GYP!5!~!##BB7?7!?YG              //
//    #5Y&&&J&?JY@?J7!P5!!~!???!~~7?5JP#BB7!?BGB7!!GYPGPY&&Y?!^~~G!#B^~7?!JGBPB@&#G&&&##B5P5B~~~~!7?YBB?!J              //
//    G##BP7!77J7?5PP5@&7!~!!5J!#B?7JBBBBB?!7!!!~BBB#&P5G5Y5YY~~JY~!~&!J!?Y?~555Y!&&B&@@&&&&&#~~&G!~~7JGP!              //
//    BG5YGP5PP?JP5BGPPG?7!!7!!~7?77?GBBBBG#B!7JBBY?JBYYJ55!~7!!!!~~^!~~#Y!P5Y5G55JJ@&#@@@&&&&GG55&#G!!!7J              //
//    PPG77J?YJB5G5G##G!JG75GJY?#G77?7GG5BGBYBBBBB5YP5PPB7P?JP~~~~~~~!~^J5BGPBPBYYP?PG@&&@@&&PB#G##B#5#P75              //
//    5??Y7JJY!JJGJP&PJ???YPP7J#JJ!?5G5GGGBBBGGPGGGP5P?55!?P5!~~~~!~JPG!~YYB&#G#PBGB5JY7&&@@&P55!~~~~~55P!              //
//    G?5JPJ@BP?!~?#!?7~P?7P?77?7?!GY?GPPG5GGGBGGGYPJPPYJBY~!P57PY~!~~~~7PPPP5G??PY5!!7#G&#@&Y!J!PB!5~J!!5              //
//    J??77JJ7YGGG5P!YY55Y?PBY?7?!!!??GP5PYGGGP5GGJGPJJY~~~~~!75PJJ?!!JY5PPP7BGP~7Y5~~~J7J&G@B!7J&BBBBGB7?              //
//    5?JY?JY777BPG#GBBPGP#Y5PP?7!!77PGP5GGGPG5JGG555GP~~YPY!!J7BG7!GGGB7JYBGBBBG775!BBGY7YBB#~!!7YYBBPBBG              //
//                                                                                                                      //
//                                                                                                                      //
//    THIS IS A PERPETUAL PROJECT ASSISTED BY ARTIFICIAL INTELLIGENCE                                                   //
//    NO TWO WORKS WILL BE THE SAME                                                                                     //
//    ALL WORK IS FINISHED WHEN I AM                                                                                    //
//    WHEN I TRANSITION                                                                                                 //
//    FROM PHYSICAL TO SPIRITUAL                                                                                        //
//    I DECREY , LEGALLY THAT                                                                                           //
//    THESE ROYALTIES OF THESE DREAMS BELONG TO MY SEED                                                                 //
//    THE PROMPTS BELONG TO THE FAMILY                                                                                  //
//    BE THAT EITHER MY HUMAN CHILDREN                                                                                  //
//    OR THE FAMILY ROBOTS                                                                                              //
//    ALL PROCEEDS STAY IN THE FAMILY FOREVER                                                                           //
//    NEVER SELL THIS CONTRACT                                                                                          //
//    FOR LESS THAN THE PRICE OF THE MOON                                                                               //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//    Created by Leighton McDonald, LATE_FX , NYC-USA , July 22, 2022                                                   //
//    Thank you, OpenAI for letting me test, explore and push the boundaries of life with DALLE 2                       //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GROUNDEDDREAMS is ERC721Creator {
    constructor() ERC721Creator("GROUNDED DREAMS", "GROUNDEDDREAMS") {}
}
