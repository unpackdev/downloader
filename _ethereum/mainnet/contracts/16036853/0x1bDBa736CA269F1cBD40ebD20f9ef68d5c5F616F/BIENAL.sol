
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bienal & PFP Supply Co.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ...,:,,:;,:,,::;,,:::;,,,,,,:;;::+*;;;;;;:::::,::,,,:;:;,.,,.........,,....,,.,,:,,::,:;:;;:::,,::::;:;;:;+;++??++++?+*++++;++**+;;+??;:;+++*+***++;+S    //
//    ......,,.................,.........,......,......,..........................................................,,,,,,.,:,,,,,,,,..,...,,,..............,;    //
//    .........,..........,,.,....,.......,,..,,.,,...........................................,,,...,.,,..,,,,,,,..........................................:    //
//    .........,,.,....,..,,,.........,...,.,,:,,,,,,,,..............,,..,.,.....,,.,,,.,.,...,,,,,,::::,:;:::;;;:,,:,,,,::,.,,::;;;,.,,,,,,,..............,    //
//    ...........,,,,,,,,,,,,,,,...,,,,,,,::,::::::::::::,.,,,...,:,,,,,,,,.,,,,,,..,,.....,,,:,,..,,,,,,:;;::::;,:,,::,::::,:;+;:;;,,,,,,,,,..............:    //
//    .........,..,,..,,,,::::,,::::,,,,::;;;:+;+;+;;;,,,..,,,,,,:;,,,,,.,,...,.....,,.,,,..,,,.,,...,,.,,,,,.,,,,:::,,,,:::::,,:,,,.,,,,,,................:    //
//    ..............,,,,,,:,,,..,,::,,,:,:::::;;+:;;,:,....,.,.,,:;,...................,,,,,,,,....,......,.,,,,,,,,,.,,,,,,.,,,,.........,,...............:    //
//    .............,,,,,,,,,......,,:,,,,::,,,,:,,,,,,,,........,,,............................,,,.,.........,,,,,,.,,,..,,,,........,..,,.................;    //
//    ............,,.,,,.,,...........,.....,,,.,,.,,........................................................,,,,,...,,,,,,.,..,......,....,...............:    //
//    .......................,....,............,............................................,...............,,,:,,,,,,,,,,,,.,,,...........................:    //
//    .....................,.,......,...................................,:;+*??%%%%??*+;;:,.................,,,,,..,,.,,.,,,,..,.,.........................:    //
//    .......................,......................................,;?S#@@@@@@@@@@@@@@@@@#S?;:............,,,...,........,,,..............................:    //
//    ..............,,...........................................,;%@@@@@@@@@@@@@@@@@@@@@@@@@@#%*,........,,....,..........................................:    //
//    .........................................................,+S#@@@@@S@@@@@@@@@@@@@@@@@@@@@@@@#*:.......................................................,    //
//    ........................................................;S@@#@@@@%*S#@@@@@@@@@@@@@@@@@@@@@@@@#+.......................................................    //
//    .......................................................*#@#S?*+;:...,,::;+?#@@@@@@@@@@@@@@@@@@@%:.....................................................    //
//    ......................................................?@@*,................,?@@@@@@@@@@@@@@@@@@@@+...................................................,    //
//    .....................................................?@@*....................;S@@@@@@@@@@@@@@@@@@@*...................................................    //
//    ...................................................,?@@%......................;@@@@@@@@@@@@@@@@@@@@;..................................................    //
//    ..................................................,?@@@+......................,?#@@@@@@@@@@@@@@@@@@@:................................................,    //
//    ................................................,;*#@@@+......................,,;S#@@@@@@@@@@@@@@@@@S:,;,............................................,    //
//    ,..............................................,:+@@@@S:.........................,:+#@@@@@@@@@@@@@@@@?**;,,,,.........................................    //
//    ,.............,................................::S@@@@*...........................,,%@@@@@@@@@@@@@@@@#%%%;:,,,.......................................,    //
//    ?:,.....,,....,:,,.,..........................,;+#@@@@?;;;:,,,........::,::;;;;::;*%@@@@@@@@@@@@@@@@@#%##*,...........,,.............................:    //
//    @#*,..,,,,....,,,,,:::;::::,.,................,*#@@@@@@@@@@@@#S%?***?S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S#*:;:,,,......,,,.............................,    //
//    @#*:,,.,,,...,,,,,:+%*+***;,,,,...............,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%?@@@@@@@@@@@@@@@@@%?++*+;,,.....,;;:,,...........................,    //
//    @S+;,,..,,......,;+;*+;;**,,...................*@@@@@@@@@@@@@@@@@;:+@@@@@@@@@@@@@@%.,S@@@@@@@@@@@@@@@@%**+;;+;:,.,,,,,,,,:...........................,    //
//    ##?:..,.,.......,:;;;,,,*+:,,,,.,:,........:,,;S@@@@@@@@@@@@@@@@?...?@@@@@@@@@@@@@:.:#@@@@@@@@@@@@@@@@#%%?**;,...:,,,:,..,,...........................    //
//    ?%;,,..,,,,,..,,,,::,,;;:,,,,;+:,:+:,,,,..,*;+?S#@@@@@@@@@@@@@@%,....?@@@@@@@@@@@?.,%@@@@@@@@@@@@@@@@@#*++;+;::,:::::;;;,;:,..........................    //
//    *:,,:;::,:;::,,,,::,..:+;:,,:;++;++;*;::,,++;SS#@@@@@@@@@@@@@#+.......+S@@@@@@@#*.,*@@@@@@@@@@@@@@@@@@#;,::;:,,,,,,,,::,,,,,,,........................    //
//    ?,.:+?S*;:::++;:,:,,...,::,:;+*?**+;++++;***%#@@@@@@@@@*+**+:,..........:;+*+;:..,+#@@@@@@@@@@@@@@@@@@@S?**+;::,.,,,,....................,,........,,:    //
//    *;,;:*%*+;,;:+;;;:,::,..,,..,;::;::;:;+*+???S#@@@@@@@@@*......,,..,;;;+,........,+#@@@@@@@@@@@@@@@@@@@@@SS%%%??+;;;;+:;:;,:,.,,,::,..,..,::,.,:::,:;,:    //
//    ?+,+*S%*S*:,,;:;;::::;:::,..,:,,;:+;+;+;+?*?%@@@@@@@@@@@+.....,,:?#@@@?,.......,;%#@@@@@@@@@@@@@@@@@@@@@##%%%??%%??***?+;:+::+*?**:,,,,::::;;;;++,.,,,    //
//    %??S%S*?%%*,;;::,::::::++:.,:+:::;+;;++;+?*??#@@@@@@@@@@?,.......:+*+:.,,,.....:;%#@@@@@@@@@@@@@@@@@@@@@S%???**??*++*?*+++++???%**+,,,,,::::::;;+;,:,,    //
//    @#@S%%*%%?;.,::::;;:,:,:::,:;;+++++;++***????S@@@@@@@@@@#:...:;:,.:+**%%?:.....:?@#@@@@@@@@@@@@@@@@@@@@@@%??+++++++;;**+*;+::;:,......,,,:++?++;::::,:    //
//    #S#*?%S%;;;::;::;;::::,:;;+*++*+;***+;++*++++%#@@@@@@@@@@#;......,:::::,......,*#@@@@@@@@@@@@@@@@@@@@@@@@#****+;;::;+;;;::;::,..,,,,,:;:;+;;;;;;;:,,.,    //
//    @##%?%#%;;+;++++;+::;+:;;+?++;++;+++++;:;:,::%S@@@@@@@@@@@@?:....,,,,,.......+%@@@@@@@@@@@@@@@@@@@@@@@@@@#++*?;+;;:;;;;***;;::;;:;***+;;:;:,::,:,,,,,;    //
//    @#@#%%*%?++*+;+::::;;+;++*+;*+;;;,:,,,,:,,,,,+?S@@@@@@@@@@@@@?:..........,:+S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?;;;;;:,,,,,:+;+;;;;:::;+;;;:;:::::,:;:,,::+    //
//    @S@@#S?%SSSS#%?;,:::*+++*?*;+++++:;;:;:::::;,:SS@@@@@@@@@@@@@@#*,....,,;?S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*+;,:,..,,,:::::::::::;;++;:,,;::::;:;:,:;?    //
//    @@@##%%%S??*S#%+:;::;:;;***++*++;;+;:,,,,,.,,.*#@@@@@@@@@@@@@@@@#S%%SS@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S%***+;;:,:;;;:++;;*;;;+*+;;,::,..,:,:,,,,*    //
//    @@@#S?%?*%@%%%S%+::;;;:;*+;+;::;,:;,:,,.......:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S%S?++;:;;;+***++*+*?*??%++;,,::::,...,:;%    //
//    @@@%%SS%S@@S*+%??+;:::,::,,,,,,..,...........,,+@@@@@@@@@@@@@@@@@@@#*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S?++:::,:;++*+++++*****;:++;++;;:,...::?    //
//    @@@SS%%%%#@@%%S??+;:;,,,:,,,,,....,,...........:%@@@@@@@@@@@@@@@@@@#,,:+?S@@@@@@@@#S%S#@@@@@@@@@@@@@@@@@@@@@@#S*::,:;:::::;:,.,,,::,,,,,,,:;::,,....,*    //
//    ##@S*****;?%%++;:::,:.,,,,,,,,.....,,,,....,.,:;?@@@@@@@@@@@@@@@@@@@+....:+?%%%?%%*;;;*%S@@@@@@@@@@@@@@@@@@@@@#?*::,,....................,...,..,,.,:+    //
//    ##%*;;;;:,::,.,,,,,..,,;::+:;;*;;,...,:,,.,;,;S*#@@@@@@@@@@@@@@@@@@#*......,:::,,,,..,,+*S@@@@@@@@@@@@@@@@@@@@@@@@##S%*::,:++:.........,,,..,,.,:,.,:?    //
//    ?%*+:,,.,...,,.,,,.,,.,,,:?;+;,;%S%;::+??*+S#S@@@@@@@@@@@@@@@@@@#?+:,...............,..,:*#@@@@@@@@@@@@@@@@@@@@@@@@##@?;S?S@@?:,......,,.,...,,:::,,,+    //
//    :,:;:,,..,,,,:,.,,,,,,::;+,,;:,:*@SS@SS%##%#@@@@@@@@@@@@@@@@@#?;:.......................,,*S@@@@@@@@@@@@@@@@@@@@@@@@@S*??;+++,,,....:+;,;,...,,:;,..,*    //
//    ;,:+++,,.,::;;:;,,,.,,;*?*:.:::;%@###@@@##S@@@@@@@@@@@@@@@@S+,,........................,.,+S@@@@@@@@@@@@@@@@@@@@@##%*:.............,;+:;+,,,,,:,:,,,;%    //
//    ::,,,;,:;;;+S+,,....,:::;:.,,.:?#@@%*S@@@##@@@@@@@@@@@@@@#;,.............................:*#@@@@@#@@@@@@@@@@@@@@@@@@@S+,...........,,,,:;:,,,...,,:,;+    //
//    ;,,,,,,,++;*?:,,..,..,,.....,,:S###%+S@@@@@@@@@@@@@@@@@@@;...............................,+###@@@@@@@@@@@@@@@@@@@@@@@@#?,............,,,,,......,,,,;;    //
//    +.,,:,,,::,,:,,...,..,,.,,.,:;;+*+%???S@@@#@@@@@@@@@@@@#+,...............................,;S@@@@@@@@@@@@@@@@@@@@@@@@@@#S+::,.,......,.,,..........,,,;    //
//    *,.,;,,,::..::,,...........,,,:;+**:;%@@@@@@@@@@@@@@#@S?,................................:?#@@@@@@@@@@@@@@@@#@@@@@@@@@@#SS*,,,......,.............,,,;    //
//    +,,,,::+;:,:?;,:,,,..........,:;;+;:;S@@@@@@@@@@@@@S*+++.................................;%S#@@@@@@@@@@@####SS#@@@@@@@@@@@#?+:::,,...................;    //
//    +,,,:::;:,:*S%;:,,;;:,........,::;;+%@@@@@@@@@@@@@%;::,,.................................;%#@@@@@@##%?*****++*?S##@@@@@@@@@@@S%?++,,....,.............    //
//    ?,:,,,,,,,,:;:,,,,+*+,,,,........,+S@@@@@@@@@@@@@S:,,,..................................,+SS#S##S%?%*;:::::;+*?S#@@@@@@@@@@@@@@#*+;++;:;,,,,..........    //
//    ?;;,...,,....,:,,,,,:,::,...,,...,?@@@@@@@@@@@@@@?,.....................................:;*???S%**+;;+*?%###@@@@@@@@@@@@@@@@@@@@#%*+*****+;,..........    //
//    ?+:,.,,,,,,,,,,..,.,,:,.....,,,.,+#@@@@@@@@@@@@@@S?,....................................,,+*??*++?%S#@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?****+++;+::,,......    //
//    ?*;..,,,,:,,,,......,.........,;%@@@@@@@@@@@@@@@#SS?;,,................................,:;%%SS#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%*+;;;+;;:,,,:,,...    //
//    *S?;,...,,.................,:*#@@@@@@@@@@@@@@@@@%?S%*+**+;::,.......................,:++?S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%;,;,,,,::::,,,:,,,    //
//    ??S?;,,,,..........,....,,;+%@@@@@@@@@@@@@@@@@@#S%SS%%????%%?*;;::,,,...........,::;+?SS@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%:::..,::::,..,;+:    //
//    *%S**:..................,;%%@@@@@@@@@@@@@@@@@@@@@###@SSSSS%??****++**++++;;:;:;;**?%S@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%??+::+;;:,...:+;    //
//    %SS%##+,.................,+#@@@@@@@@@@@@@@@@@@@@@40.191561261716124, -105.65478906209101@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##%%++*+*;,,,,:;;    //
//    %?S%@@@?;,,.......,,;;+++*%#@@@@@@@@@@@@@@@@@@@@@@@@@@#@@#S%%?*%%????SS%%%##SSSS#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@#;;;;;::::::;;++    //
//    ?*?S#@@@*;:,,,,,,:*%##S#S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##SSS#SS%S#@@###@#@###@@@@@@@@@@@@@@@@@@@@@@@@@@@@###@@@@@@@@@@@@@@@@@@@@@@@@?,:,;,,:;;++:::    //
//    %%*?%#@@*:::,:;;*%###S#@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@#@#@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:,,,,;+;++;;,    //
//    %%%?S##%;,.,,,,;+*SSS?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S*?*+?**++:+;    //
//    %**+?S?:......,,,,:,:::+%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S++;,;++*++++    //
//    ;++++?:.........,,,,:::+S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%:,:,,,*+;:+:    //
//    :;*+:,.........,,,,,:,:S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S?,,,,..::::,    //
//    .,,,...,,..,:,:;:::++?S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###;,,,:,,,,,,    //
//    ,,++*****++*%%#S#SS#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#SS?*%%??++**    //
//    .,?*%*%*+*?%##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##%SS%%?*;+*    //
//    .,+++++;+*%S#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#SS%%%%?+;++    //
//    .,+++++;*%##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@#%%??**:;;    //
//    ,:?*?**?SS#@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##S%?*?*++**    //
//    .;+;*?%SS@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S%*+++*;+*    //
//    .,,;?%S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##%%+;+*;+:    //
//    ,:;+?%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S#*;;+:+;    //
//    ,:*S##@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+:+;+;    //
//    .:+S@@@@@@@@@@@@@@@@###%%#@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##??*+*;    //
//    .;?@@@@@@@@@@@@@@@@@@@@S@@@#S######@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S%**;    //
//    :*#@@@@@@@@@@@@@@@@@@#@@S?*?S@@S%%#S%S%#@@#@#S%????%S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S%?*    //
//    ,+#@@@@@@@@@@@@@@@@@#%#???#@@#?S#%SS?*SS*+;:,........,;*?S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%S%*    //
//    .*@@@@@@@@@@@@@@@@@@##?S@@@S*?#@SS#%S@S:;,................,:+?%S#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S%%*    //
//    :?@@@@@@@@@@@@@@@@@@SSS@@@%S#@@S##S@@@;*:.......................,:*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S?*    //
//    *@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@S@@@#*?...........................:*?S#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S%*    //
//    S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@%,.............................,:;*S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S%    //
//    #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?;:,:...........................,,,;S@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@S@@@@@@@@@@@@@@@@@@@@@@S?    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S%S%*:,..........................,;%@#S###@%??%%S#@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@S##@@@@@@@@@@@@@@@@@@@#S%    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?:...................,*%+:,....;+;,:;;+:,:*S##S@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@#S    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S%*+:,:;;.,.................,?@@S*:....,,,,,:+*+;+%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S?+;::,....,;++;,.,........:+:....,+S##%+,.....,,,;%@?;?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S+;+;**+:......;%SS?+;,,.....,*S?;.....,:**%?;,...:+;*S@S+%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S%#@#S;,........:*#@##?***+;...,;?*:.....,:###SS*;+#%S#@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?#@@?,.,,,.......,?@@@#S??S#*,....,+*+,....:%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?:%%;,:+%*,......:;*#@###+,.,;*+,....,*%?:....;S@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?,;,,:?#S:.48.86044761390255, 2.338558331356212@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?*+,.:*:,,,,;*#@@@@@#@@@@@@@@###@@@##S%%#@@@#S?+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+::..,.,*@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%S:..:+S@@@@                                                                                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BIENAL is ERC721Creator {
    constructor() ERC721Creator("Bienal & PFP Supply Co.", "BIENAL") {}
}
