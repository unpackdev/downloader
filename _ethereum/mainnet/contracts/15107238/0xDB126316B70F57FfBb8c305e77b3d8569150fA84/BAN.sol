
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bandageBOX
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    **, ****************************************************************************************,   *******************************************************************************************************     //
//    ***,*****************************************************************************************  ******************************,**************************************************************************    //
//    *******************************,***********************************************************,**,****************************** *,************************************************************************    //
//    **************************************************************************************************************************,.   .,***********************,***********************************************    //
//    ***************************************************************************************************************************** ,************************. .**********************************.***********    //
//    ******************************************************************************************************************************************************************************************** ***********    //
//    *******************************************************************************************************************************************************************************************  .**********    //
//    ****************************************************************************************************************************************************************************************,       ********    //
//    ***********,*******************************,.,*************************.,***************************************************************************************************************,,     *********    //
//    ***********  ******************************,  *********************************************************************************************************************************************  ,,*********    //
//    ****************************************,       .****************,*************************************************************************************************************************, ***********    //
//    ******************************************** .****************@@*&@&************************************************************************************************************************,***********    //
//    *******************************************,.,*************,%@,,,,,,,@@&*,******************************************.**********************,**@@,**,,,,*************************************************    //
//    ,,,,,,***************************************************,*@#,,,,,,,,,,,*@@/*,,*********************************************************,**@@*,,@(,.    ,,**********************************************    //
//    ******************************************************,*,@@,,,,,,,,,,,,,,,,,&@(**,,*,*,,,,,,,,,,*******/@&.....&@%,,,,,,,,,,,,,,,,,**,,*@@,,,,,,,@@**  ,***,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ****************,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*,**,,,***@#,,,,,,,,,,,,,,,,,,,,,%@(,**,*,,,******,*******,/@#.......@%,,,,,*,,,,,*,,,*@@*,,,,,,,,,,#@*,,***********************,*************************    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*,,#@,,,,,,,,,,,,,,,,,,,,,,,,,.@@,***,  ,***,*,,,,,,,,,,*%@..,,*//@,,,,,,,,*,,*#@(,,,,,,,,,,,,,,*@,,,,,,,,,,,******,,,*,,*****,,,,,,,,,,***,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@%*/##&&&&&&&#/...,*,****@*/////&#,**,,*,,,@@,,,,,,,,,,,,,,,,,,,@/*,,,,,,,,,,,,,,,,,,,,*,,,**************,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..,,@#..............@/..,**,%/////%///////&@&,,,,,,,,,,,,,,,,,,,,,,@#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..   .,*%@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@(//////////////*,%***/#///%///////&#,,,,,,,,,,,,,,,,,,,,,,,,,@%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,             @@,,,,,,,,,,,,,,,,,,,,,..*%@@%,.............*&*//////**,,.,%#%*%/%,..,*******,..*&@@&,,,,,,,,,,,,,,,,,,@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.*,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*               @#,,,,,,,,,,,,,,,,,,/&@/.........................,*/////////////(///(%#/**,**/(##(//*..../@&*,,,,,,,,,,,,@&,,,,,,,,   ,,,,,,,,,,,,,,,,,,,,,,,,.,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*                @*,,,,,,,,,,,,,,.@@, . ..................... ,,%////////////////(#,....................%//,....(@(,,,,,,,,,@%@,*,,,      ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,               ,@,,,,,,,,,,,,,%@*...........................#*,...............,**...........................#*......#@*,,,,,,@*..%&,      .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,, ,,,,,,,,,,,,,,,,,*.               /@,,,,,,,,,,,@&............................(.............................,(......................&.......,@,,,,,@*...,@(     ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,.             %%,@,,,,,,,,,@#............,................#....................................(...................,%......../@,,*@/.....*@    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,           @%.,,@,,,,,,,&@ ............/.............  .#. .......................................(*% . ............***.........@*#&/,.....*@  *,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,         &%,,,,,@,,,,,,@#..............#..............,#............................#................#**(.............**/........../@(//......%( ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,       @(,,,,,*@,,,,,@(...............#.............,% .............................../................/*/............**/............////*,.....@*,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    .*,,,,,,,,,,,,,,,,,,,,,,,,     &%,,,,,,*@,,,,@(................%............,*/.................................,%................%*#...........****/...........*(////*,...@**,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//     ,,,,,,,,,,,,,,,,,,,,,,,,,    @*,,,,,,*@/,,&&.,,,,,,,,,.......*...........**%........,.........................../%................%(..........****.../..........,///////**.(&,*,,,,,,,,,,,,,,,,,,,,,,,,    //
//      ,,,,,,,,,,,,,,,,,,,,,,,*   @,,,,,,**#@,*@.,,,,,,,,,,,,......%,........***%......,*.............................*/%................/.........****#...../,........,///////////@/,,,,,,,,,,..,,,,,,,,,,,,    //
//      *,,,,,,,,,,,,,,,,,,,,,*,  @,,,,*****@,@.,,,,,,,,,,,,,,,,,...%.......,***%.....,**..*...........................*/(.............,#,........*****#........&........,*///////////(@,          ,,,,,,,,,,,    //
//      .,,,,,,,,,,,,,,,,,,,,,,,&&,,*******@*%.,,,,,,,,,,,,,,,,,,,,,%......,***%.....***/*#............................///,...........#........******/...........(........,,(////////////&.         ,,,,,,,,,,    //
//       ,,,,,,,,,,,,,,,,,,,,*@&**/*******%@..,,,,,,,,,,,,,,.(,,,,,,,/,,.,,***/*....*/*/*%. ..........................,///,......../,.*************%..............,,.......,.,,%//////@&            .,,,,,,,,,    //
//       ,,,,,,,,,,,,,,,,,,,,#@%**********@.,,,,,,,,,,*/,,,,(,,,,,,,,(,.,,****%,...**//%*............................,///(.....*%/***********/##,....(............,.%.,,,..,,,,,,#&                  ,,,,,,,,,    //
//       **,,,,,,,,,,,,,,,,,,**(@,,,,****%.,,,,,,,,,*///,,,,*,,,,,,,,,*(,*****#...**///(............................,////%......................,....*,.........,,,,,,(*.,,,.&,,,,,(&                ,,,,,,,*,    //
//        ,,,,,,,,,,,,,,,,,,,&/,,,,*****%,,,,,,,,,*////*,,,,/,,,,,,,,,,,%*******..**///(,..........................*////%@.................,*..,......*#,,,,,,,,,,,,,,,,,,*#(,,%,,,,,&*               ,,,,,,,,    //
//         ,,,,,,,,,,,,,,,,,@,,,,,****(*,,,,,,,,*/////*.,,,,%,,,,,,,,,.***%(***(..**///%,,,,.....................**////(@@,............,,,..*//(..,,,,,./(#*,,,,,,,,,,,*%*///*,,/,,,,,,@              ,,,,,,,,    //
//          *,,,,,,,,,,,,,,@,,,*****#*,,,,,,**////////.,,,,,,*,,,,,,,,***#///%(**(**///#,,,,,,,,,,,*,,,,,.,,..,**/////%#*&....,,(,,.,,**/,,,**///.,,,,,,,*///#/(////(//////*,,,,,/,,,,,*@              .,,,,,,    //
//            ,,*,,,,,,,,,@******(%*//*/////////////*..,,,,,,,,,,,,,,,***///////(%*(/////,,,,,,,*/(.,,,,,,*,***/////(@..@,,.%,,,.,.,**/@,,,,,*/////,,,,,,,**/%///////#//**,,,,,,,/(,,,,,/@,,,,.          ,,,,,    //
//                .,,*,,,@/****#*,*(%(////////(#/*,(..,,,,,,,,*,,,,,,,**/*//////////%#(//,,,*///(,,,,,,,,,*&//#&@@@@@@@%*,,,,,,,,***/#%.@,,,,*//////,,,,,,***&(/////**(,,,,,,,,,,***,,,,*#@,,,,*                  //
//                   ,@@/*****%,,,,,,,,,,,,,,,,,,,,%..,,,,,,,,,,#,,,,,**(///////////%,,,,*////@@,,,,,,*//////&/**,,,,,,,,,,,****////@.   @*.,**/////,,,,,,***@&,,,,,,,,/*,,,,,,,,**&,,,,,/@,,,,,,                 //
//                       /&&&%,,,,,,,,,,,,,,,,,,,,,&.,,,,,,,,,,,*/*,,,**////////////%,**///(@ @,,**/////(%&@@(*@(////**///////////@(       #&,**////#,,,,,,*@  @,,,,,,,,*****,,,,**/,,,,,/@,, *,,                 //
//                          @,,,,,,,,,,,,,,,,,,,,,,&.,,,,,,,,,,****((,,**#/////////(@////(@%/@@@*..... ....%.     %@%//////////#@       ,%  . *@#*///%,,,,*@    @,,,,,,,,,(//*******%,,,,/@,*  ,,                 //
//           ...           &*,,,,,,,,,,,,,,,,,,,,,,*,.,,,,,,,,,******((/,*/////////@@///@............*%,     ,@@(/////////#&@*      */ ..       ..*@@&,,,(@     .&,,,,,,,,,,,,((*****(*,,*@,*,,,                  //
//        ,,,,,,,,,        @,,,,,,,,,,,,,,*,,,,,,,,,&.,,,,,,,,,******#,,,*(%//////%#.@/@........,&                              #*.            /@    (/@%        @,,,,,.,,,,,,,,,,(,,,,,,*@*,*                    //
//       ,,,,,,,,,,,       @,,,,,,,,,,,,*(,,,,,,,,,,,%.,,,,,,,,,*****/*,,,*///////@...@&. ./#                              .%.            . %@@@@@@@@&#/,        .@,,,,,..,,,,,,,,,&,,,,,/#&                      //
//       ***,,,,,,,,.      .@,,,,,,,,,,*(,,,,,,,,,,,,,%,,,,,,,,,******#,,,**//////@...(%                               *#           ..  .@&#########%@@@@@@@@@@@, @,,,,,...,,,,,,,,*,,,,,//@,                     //
//       ,, ,,,,,,,,        @/,,,,,,,,*%,,,,,,,,,,,,,,,%,,,,,,,,******%,,,/*/////%@                                #*            . . *@%#################@    @@@ @,,,,,/...,,,,,,,*(,,,,///@(                    //
//        ,,,,,,,,,          @,,,,,,,*#*,,,,,,,,,,,,,/,,,#,,,,,,******%,,,,(*////%&                           *#.                 @@ .%############.   /#@    &@@ @,,,,,/,..,,,,,,,/%/////////@.                  //
//          .,,,.             @,,,,***#,,,,,,,,,,,,,,%,,,,#,,,,,,****/(,,,,,*/////@                      .%*..                *@,    .&##########%       @    @@. @,,,,,/&.,,,,,,,*/((#(//////(%@@&.              //
//                             @,,**/(/*,,,,,,,,,,,,//,,,,,,%,,,,****%,,,,,,,,%///@                  (*,..                 @%         @###########.     (*   *@% /&,,,,*/#*,,,,,,//(////@.                        //
//                              @*///#//*,,,,,,,,,,///,,,,,,,%,,****%,,,,,,,,,,,#/(@            //,,.                  %@             #(((((((((((((((((@    @(  @,,,,*//(////////(*/////@                        //
//                             /@////(///*,,,,,,,*///#,,,,,,,,(***/*,,,,,,,,,,,,,((%@      ((,,,.                ..@@                  @/((((((((((((((&    @   @,,,,*///#///////(*///////@                       //
//                           #@///////(//////**//////%,,,,,,,,%*%,,,,,,,,,,,,,,,,,//&@(/,,,,.                 ,@#                       @((((((((((((/&        @,,,*/////%///(#****///////@.                      //
//                        &@//////////#//////////////(*,,,,,,,,,,,,,,,,,,,,,,,,,,,*///&@.             ..  @@                             ,@/(/(((/(/(@       .@,,*//////%%/(******////////@,                      //
//                            *%@@&%#(((%/////////////%*,,,,,,,,,**,,,,,,,,,,,,,,**//////@&.  ..... (@#                                        .,,. . . . .,@,,///////////(******////////(@                       //
//                                @/////(*(#///////////(*,,,,,,,,,,****,,,,,,,,***//////////(@@@%      /   /            ______              /  /      . .@&////////////#/******/////////%@                        //
//                                @////%***///(%#///////(**,,,,,,*,,,**/*******////////////////////&@                                                *@&//////////(#(///*****/////////%@                          //
//                                *@///%****/////////%#//%*/*,,,,,,,,,,,,,/%///////////////////(@%.                                                         .@////////**%****///////%@                            //
//                                 .@//%,***//////////(/*******,,,(,,,,,,*,,,,**/(#####%@&%/.                                                       ....,,,#&//////*****(***////////@                             //
//                                    &@*,***////////////,,,,,**,,#,,,,,*/*,,,,,***/////@#...,.                                          .......,,,,,,,,,@&/////*******//**///@/(///&(                            //
//                                       #***///////////%,,,,,,,,*,,,,,***%,,,,,,,,*/////@,,,,,,,,,,.............................,,,,,,,,,,,,,,,,,,/%@&////***********////*////@&@%&&@@@                          //
//                                          &#//////////%,,,,,,,%,,,%/....,@@*,,,,,,,/////@...,,,,,,,,,,,#@#....,@.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%@@@#//****%/***//#/////((@                                  //
//                                            .@#//////#*,*%#(**,***@........../@*,,,,,*///@&,,,,,,,,(@,........,/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(#***///%(/%///(@                                   //
//                                              @/////%/%,,,,,/%#/**#*.,..,*......*@@(*,,/*//%@,,,,@,..... /,../,@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@///////%(/@ %/(@                                     //
//                                            .&//#%(////##,,,,******@....,,,/,,,,,,,@,,,,,,,,,,*%,.....*,,,,..,@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**/(/@#///(%  &.                                       //
//                                          ,     @////((&**%@*,*****/@/..,,,,,(,,,,,,,@,,,,,,,@*......,,,,,..*@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*,*****&@@   /@@@                                           //
//                                                #@@@/   /@@#**/#@@@@@@@...,,,,*,,,,,,,@%(((@*,...../**,,..,/*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,***********/&@&.                                                     //
//                                                             %@@******,(@...,***,,,,,,,.. . ......,**,,..(@,,,,,,,,,,,,,,,,,,,,******************/@@@,                                                          //
//                                                            #&///(%%@@@@@@/.....  .... ...   .........,#&**,******************************/(&@@(.                                                               //
//                                                           &% .    .,/@....             .   ..........,@*******************/////////////@@@&(@                                                                  //
//                                                         .@.        @... ..             .............,,*@////////////////////////////&@///    *@*                                                               //
//                                                        @@////////*@,... ..       .#*  .............,((*&(/#@@%/,*,**////*/////#&                                                                               //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BAN is ERC721Creator {
    constructor() ERC721Creator("bandageBOX", "BAN") {}
}
