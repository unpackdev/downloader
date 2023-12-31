// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Giant Swan DxP
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    %%%%&&&&&&&&&&&&&&%%%%%%############%%%%%%%%%%%%%%%%%%%%#%##########%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%##################((((((((((((((((    //
//    %&&&&&&&&&&&&&&&&%%%%%##########%%%%%%%%%%%%%%%%%%%%%%##################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####################(((((((((((((((((    //
//    &&&&&&&&&&&&&&&&&%%%%%%######%%%%%%%%%%%%%%%%%%%%%%%%%%########((((###################################%%%%%%%%%%%%%%%%%%%%##############%%%%%%%%%%%%%%%%%%%%############################((((((((((((((((    //
//    &&&&&&&&&&&&&&&&%%%%%%%%####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#######(((############((((((((((((((############%%%%%%%%%%%%###########(#############%#%%%%%%%###############((((((#############((#((((((((((((    //
//    &&&&&&&&&&&&&&&&%%%%%%%#####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####################(((((((////(((((##########%%%%%%%%%%%%########(((((((((############%#############((((((((((((((((######################((    //
//    &&&&&&&&&&&&&&&%%%%%%%#######%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%###################((((((((////((((#########%%%%%%%%%%%%%%%%#######(((((((###########################(((((((((((((((((#######################    //
//    %%%%&&&&&&&&&&%%%%%###########%%%%%%%%%%%%%%%%%%%%%%%%%%%%###########%%%%####(((((((//////((((########%%%%%%%%%%%%%%%%%%%#########################%%#############(((((((((((((((########################    //
//    %%%%%&&&&&&&&&%%%%%############%%%%%%%#%%%%%%%%%%%%%%%%%%##########%%%%%%%###(((((//(((/(((((#######%%%%%%%%%%%%%%%%%%%%%%%%%%################%%%%%%%%##########(((((((((((((((###(#####################    //
//    %%%%%%&&&&&&&&%%%#####((((((########################################%%%%%%%###(((((((((((((########%%%%%%%%%%%%%%&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%########(((((((((####################%########    //
//    %%%%%%%%%&&&%%%#((((/////////((((###################################%%%%%%#####(((((((((((########%%%%%%%%%%%%%%%&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%############################################    //
//    %%%%%%%%%%%%##((//*************//(((######################(((######%%%%%%####((((((((/////((####%%%%%%%%%%%%%%%(,.              ./((%%%%%%%%%%%%%%%%%%%%%%%%############################################    //
//    %%%%%%%%%%##((/****,,,,,,,,,,,****/((###%################(((((######%%%%###((((////********//((#####%%%#*                ..            .,(%%%%%%%%%%%%%%%%%%%###########################################    //
//    %%%%%%%%##(//***,,,........,,,,,,**/((##%%###############(((#######%%####(((///****,,,,,,,****///.              ...............            ./#%%%%%%%%%%%%%%%###########################################    //
//    %%%%%%##((//***,,,...........,,,,***/((###############((((((((########((((///***,,,,...,,,,.      ....................,......... .........     ./%%%%%%%%%%%%#############################(#############    //
//    %%%%%%##((/****,,,............,,,,**/((#################((((((#####((((////***,,,.......          ..............,..............................   /%%%%%%%%%%%%%########################################    //
//    %%%%%%##((//***,,,,,,........,,,,**//((##################(((((((((((//////***,,,....     ...................,,,.,,,,,,.,,,,,,....................   ,%%%%%%%%%%#########################################    //
//    %%%%%%%##((//****,,,,,,,,...,,,,**//((#######%%#############(((#(((((/////****,,.   ........................,,,,,,,,,,,,.,,,,,,,,,,..........,.......  ,#%%%%%%%##########################(#############    //
//    %%%%%%%###(((///******,,,,,,,,***//((#######%%%%%#################(((/////****.   .........................,,,,,,,,,**,*,,,,,*,,,,,,,,,,.......,,......   ./%%%%%#######################(###(###########    //
//    %%%%%%%%####((((((//************//((#######%####%################((((((/////. ...................... ......,.,,,,,***,*****,,*,****,,,,,................... .#%%%%%#######################(((###########    //
//    %&&&&%%%%%%######((///////*/////(((#######%%%%%%%%%%%##############(((((((. ...................       ..,,,,,,,,,,,***,****,,,*,,,,,,,,,,....,,..............  ,#%%%%###################################    //
//    %%&%&%%%%%%%%####(((//////////((((####%%%%%%%%%%%%%%##%################(*......,..,...,,.....      .  ..,,....,,,,,,,,,,,,,,,,,,,,***,,,,,.,,,,,,,............. .#%%%%%%################################    //
//    %%%%%%%%%%%%%%###((((////////(((#####%%%%%%%%%%%%%%%%#################(.........,..,,,,,,,.....,(&%&@&&*.  ...........,,,,,,...,*,,,,,......,,,,,,,,,,,,......  . .#%%%%################################    //
//    %%%%%%%%%%%%%%%%###((((((((((((#######%%%%%%%%%%%%%%%################(....,.,.,,,,,.,,..,..,,(%&@@@@@@@*      ........,,,,,,,,,*,,,,,,,,,,,,,,,*,,,,,,,,..........  *%%%%%%%%%%%%#######################    //
//    %%%%%%%%%%%%%%%%%######(((((##############%%%%%%%#################%#(....,,,,*,,,,*,,..../&@@@&&&@@&@@,     . .......,,.,,,,,,,,.,...,,,,,,,,,,,,,,,,,,,,,...........,%%%%%%%%%%%%%#####################    //
//    %%%%%%%%%%%%%%%%%%#########################%#############((#########.....,,,**,****/*%@@@@@@@@@&@&,         ......,,,,*,*,*,,,,,,,,,,,,,,,,,.,,,****,**,,,,,,,.........*%%%%%%%###%%#######%%###########    //
//    %%%%%%%%&&&&%%%%%###################################((((((((((((##(...,,*//(&&&@@@@@@@@@@&&&&&&@*..        ....,,,,,**,,***,,,,,.,......,,**,,,,,***,,,**,,,,.......... .#%%%%%%%%###%%%%%%%%%%%%#######    //
//    %%%%%%%&&&&&%%%%%##################################((((((((((((((/,,,**#%@@@@@@@@@@@@@&&&&@@@&@*.    . .....,.,,,,,,,***,*,*,,,,,,,,,,,,,,,,,,,,****,,,,,,,*,,,,,,.........%%%%%%%%%%%%%%%%%%%%%%%%#%###    //
//    %%%%%%&&&&&&%%%%%######(((((((((((##################(((((((((((((/,**%@@@@@@@@@@@@@&@@@@@&@@@@(.. ........,,.,,,,,,,,,,,,*,***,,,,,,,,,,,,,,,,*/******,*,,,.,,,,,.,,.......,%%%%%%%%%%%%%%%%%%%%%%%%%###    //
//    %%%%%%%%%%%%%%%########((((((((((((((((#############((((((((((((/(#(((@@@@@@@@&&@@@&&@@@@@@@@@,.......,,,,,,,,,,,,,,,,,,,****,,,,*,,,,,,,,,**////*,,*,,,,,,,,,,,,..,,,,.....*%%%%%%%%%%%%%%%%%%%%%%%####    //
//    %%%%%%%%%%%%%%######((((/////((((((((((((((((((##((((((////////#(&@&@@@@@@@@@@&&@&@@%@@@@@@@@(,.....,,,.,,,,***,,,,,,,,*********,****,,,,,//((/*//**,,,**,,,,,,,,,,,,,,,,....,%%%%%%%%%%%%%%%%%%%%%%%###    //
//    %%%%%%%%%%%%%#####(((///////////////(((((((((((((((((/////////%@#&@@@@@@@@@%#((/#&@&&@@@@@@@@&*,,...,,,,,,*,****,,,,,,********,,,,,*,,,**//####//*,***,*,**,,,,,,,,,,.,,.......#%%%%%%%%%%%%%%%%%%%%####    //
//    #%%%%%%%%%%%#####((((((/////////((((//((((((((((/////////////@@@@&@@@@@@@@%##((((/(/%@&&@@@@@@@/,,,,,,,,,,*,***,,,*******///***,******//((#(((((/************,,,,,,,,.,,...,...,#%%%%%%%%%%%%%%%%#######    //
//    #####%%%%%%%#######((((((((////(((((((((((((((((((//////////&&@&@&@@@@@@@@@&%(((/(////(@@@&@@@@#/*,,,,,,*****/***/*//*///(///*/****//(####((((/////**,,****,,,,,,,*,,,,,,,,......*%%%%%%%%%%%%%%########    //
//    ######%%%%%%########((((((////////(((((((((((((((((//////////@@@@@@@@@@@@@@@@((/////(/((#&@@@@@@(/***,**/**//((/////((((////////((##%%%##%#/(*/(/(/(//*****/**,*,**,*,,,,,,......,#%%%%%%%%%%%%%########    //
//    ####%%%%%%%%%%%#######(((//////((((((((((((//((((///////****//(@@@@&%%@@@@@@@(/////////((##%&@@%(/**,**//****/***//((((((####&&&&&&%&%#(#(#(///*(#///*****,**,,,*,*,,,*,,,,,,...../%%%%%%%%%%%##########    //
//    ####%%%%%%%%%%%%######(((((///((((((((((((////////////***********#%##@@@@@@&@(((/***/(//((##&@@@#/**,,,*******/////(########((#&&&%%%%##((((((/***((******,,**,,*,,,*,,,,,,,,.,,...(%%%%%##%############    //
//    ####%%%%%%%%%%########(((((///(((((((((((((((//////////*********(##@@@@@@@&((*(((/*//(/((#(%@@@%((*,,,*//((((############(((((((%%%%%%%%###(/////**////*********,,,,,**,,,,.,,,,,..(%%%%%%%#############    //
//    ####%%%%%%%%%%%######(((////////(((((((((((((//////(/////*****,(%##%&@@@@@(///(/*/(///((#&@@@&#(***////(((((#(#(((((((((((((((///#&&%%#%%%((((/(********/******,,*,,,*,*,,,,,,,.,,./%%%%%%##############    //
//    ####%%%%%%%%######(((((//////////////////////////////////****,/##(&&@@@@&&@%((/(/*//#/(@@@@&#*,*****////((((((((((((((((((((((((//#%&%%%%%%#/////(/(/****///**,***,,,,*,*,,*,,,....,(%%%%%##############    //
//    ###%%%%%%#######((((///////(((((((((//////*****************,,(##(#(###///*/((#//////(@@@@%((*******///////((((((((((((((((((((//////#%%%%%##(((/////(***/*/***,*,,*,*,*,**,,,,..,.../%%%%%##############    //
//    #%##%%########(((((////////((((((((((((////**************,,,(##((//****////(((//#(#&@/,,,**********////////(((((((((((((((///////////#%%%#%%##((/((/(/**(*///**,*,,*,*,,,,,,,,,..,...(%%%###############    //
//    ##%%%%%%#####(((((/////////(((((((((((((/////*********,,,,/###(///****///(/////(%%&,,,,,,,,*********////////(((((((((((((((///////////#%%##%##((/(#/////(//*///*/**,,,,,,,,*,,,,,.....*%################    //
//    ##############(((((((///(((((##(((((((((//////*******,,,,(%%###((/////((((///###(,,********************///((((#######((((((((((((((///(#%##%##(****((/**(//////(/(//*,,,*,*,*,,,,,,....(################    //
//    ################(((((((((((############(((////*****,,,,/(######(((((((((//(#(%*,,****////////////////////(((((((############((((((((////(##%###(///(/(/*//#///(*/*/***,,,,,,,,,,,,,,,..(%%%%%###########    //
//    ###############((((((((///((((((#########(((//*****,,*/(#%((((((/((((//(###%.,,,****///////////////////(((((################((##(#(((((//(#######(//#///*****/***,*,,*,,*,,,,,,,,,,,,,.,#%%%%%##########    //
//    ####################((((///////(((((((((((((//****,**//(((/(#(((((***##(##,,,,,*****/////////////////////((((((#(############(((((((((((///#((##(((((/****//**/((*****,,,***,**,,,,,,,,./##%#%%#########    //
//    ################((##((((///////(((((((((((((///**/#(*/((////###**/(%%(@,,,,,********/////////////////////((((((((((((((((((((((((###(((((/(#####(/////**,/*//*(////**,*,,****,**,,,,,,,.*%%%%%%#########    //
//    #####################(((///////((((((((((((((//*%&&/(#//(((#%,//(%&@(,,,,,,******//////////////////////((((((((((((((((((((((((((((((((((*/###(((///#/*/**//**///**//****,*****,**,,,,,,,#%%%%%#########    //
//    ####################(((((///////(((((((###((((%&@&**(/(((%(**/(#@%,,,,,******///////////******/////((((((((((((((((((((((((((((((((((((((//(/(((((((//(/*,//******//*/*,*,*,,,,,,,,,,,,,,(%%%%%%########    //
//    ######################(((((((////((((((((((((&@@@#(#(((//*/(@@#,,,,,****/////(((((/////////////////((((((((((((((((((/////////(((((((((((/*/(((((/////(/*/(********(*******,*,,,,,,,,,,,,/%%%%##########    //
//    ############################(((((((((((((((((@@@@&%####%&&&,,,,,,****/////((((((((//////////////((((((((((######((((((///////////(((((((((*((#(/*////*///#**/////*****,*/*****,*,,,,,,,,,/%%%%%#########    //
//    #############################(((((((((((((((((@@@@@@@@@#***********/////((((((((((((////((((((((((##############((((((((((((//////(((((##(/(#(((/////(/*(///((/(/*/**/**/****,,*,,,,,,,,,(%%%%%%########    //
//    #############################(((((((((((((((((((@@@@@///***//////////((((((((((((((((((((((((((((###################(((((((((((((((((((##(/(///(//*///(//(/((///////*/****/****,,*,,,,..,(%%%%#####%%%%%    //
//    ###############################((((((((((((/////(((////////////////(((((((((((((((((((((((((((((((##################(((((((((((((((((####*****/(///(/(**(//(/((/**////**********,,,,,,,,,(%%%%%%%%%%%%%%    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GSDxP is ERC721Creator {
    constructor() ERC721Creator("Giant Swan DxP", "GSDxP") {}
}
