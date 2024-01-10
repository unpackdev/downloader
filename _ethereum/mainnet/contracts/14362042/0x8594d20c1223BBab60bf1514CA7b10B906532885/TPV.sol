
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Pinco Verse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%??%%%SSSSSSSSSSSSSSSSSSSSSS%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?**++++++?%SSSSSSSSSSSSSSSS%%?********?%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%??******????????%%%%%%SSSSSSSSSSSSSS%%?**+++++++++++?%SSSSSSSSSSS%?**++++++++++++?%SSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%??***????????????***********?????%%%%%%?*++++++++++++++**?SSSSSSS%%?**++++++++++++++++*?%SSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%?***???**********??????????????****************++++++++******%SSS%?**++++++++++++++++++++++*?SSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%??***???*******+++++*++++**********??%??*************************?S%*++++++++++++++++++++++++++**?SSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%??***???%?************+*+++++++++++*****************************???%%?+++++++++++++++++++++++++******%SSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%???*************?????????******************************************??%%?*++++++++++++++++++++++**********?SSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?******************************?????**********************************?**++++++++++++++++++++**************%SSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?*****************************************************************************++++++++++++++*****************?SSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?*******************+++++++++++****************************************************++++++******************???%SSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?*****************+++++++++++++++++++*********************************************************************???%%%SSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?***************++++++++++++++++++++++++****************************************************************??%%%%%????%SSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%**************+++++++++++++++++++++++++++++**********************************************************???%%%%?**++++++*?SSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?***********++++++++++++++++++++++++++++*************************************************************?%%%%%?*++++++++++++*%SSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?********?*******+++++++++++++++++++++******************************************************************?%*++++++++++++++***%SSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?*******????????????**+++++++++++++++************************************************************************+++++++++++******?SSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?*******???????????????**+++++++++*********************************************************************???*******++++***********?SSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?********?????????????????**+++++*********************************************************************???%%%??*****************???%SSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?*********%%%?????????????**************************************************************************???????*??%??******?*****???%%%SSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%***********?%%%%?%%%??%%%??**********************************************************************???????***+++*?%%??******???%%%%%SSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?**************?%%%%%%%%%??*****************************??*****************************************????**++++*+*++*?%%??*****?%%SSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?******************?????*****************************??????***************?**************************????***++*+***++*?%%??****?%SSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSS?***************************************************?????????************??******************************????***++*****++*?%%??****?%SSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSS%?***********?*************************************??????????????******???***********************************????**+********+*??%??****?%SSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSS?*************%**?*****************************??????????%S%??????**?????***************************************????***********+*?%%??****?%SSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSS%?****************???*************************??????????%%%%%?????????????******************************************????***+*********?%%??****?%SSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSS%********************?**?%**??*************???????????SS%%%%%????????????**********************************************????***********+*?%%??****?%SSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSS%?******************+++*******???????????????????????%%SSS%%%%?????????????************************************************????*************?%%??****?%SSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSS%*****************????**++++*?????????????????????%SSSS%%%%%%%?????????????***************************************************????*************?%%??****?%SSSSSSS    //
//    SSSSSSSSSSSSSSSSSS?*****************???????******????????????????%%%SS#S%%%%%%????????????????*****************************************************????***********+*?%%??****?%SSSSS    //
//    SSSSSSSSSSSSSSSS%?*****************??????????????%????????????%S#SSS%%%%%%%????????????????**********************************************************????**********??????******?%SSS    //
//    SSSSSSSSSSSSSSS?******************?*??????????%%%%%%%%%%%%%%SSSSS%%%%%%%??????????????????*************************************************************????*****???????*******???%SS    //
//    SSSSSSSSSSSSS%?*****************??%%???????????%%%%%%%%%%%%%%%%%%%%%???????????????????******************************************************************??????????********???%%%SSS    //
//    SSSSSSSSSSSS%*****************??%S@@@#S%??????????%%%%%%%%%%%%%???????????????????????*********************************************************************?????*******????%%%%SSSSS    //
//    SSSSSSSSSS%?*****************??%#@@@@@@@#S%???????????????????????????????????????**********************************************************************************???%%%%%SSSSSSSS    //
//    SSSSSSSSS%*****************??%S@@@@@@@@@@@@@#%%?????????????????????????????????*********************************************************************************???%%%%SSSSSSSSSSSS    //
//    SSSSSSS%?******************??%@@@@@@@@@@@@@@@@@#S%???????????????????????????********************************************************************************???%%%%%SSSSSSSSSSSSSSS    //
//    SSSSSS%?**********************??S#@@@@@@@@@@@@@@@@@#S?????????????????????****************************************************************************???????%%%%SSSSSSSSSSSSSSSSSSS    //
//    SSSSS?****************************?%S@@@@@@@@@@@@@@@S??????????????????***********************************************************************???????%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSS    //
//    SSS%?********************************??S#@@@@@@@@@#???????????????********************************************************************??????%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SS%**************************************?%S@@@@@%*????????*?****************************************************************???????%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    S%?*****************************************?%SS????????************************************************************????????%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    S%%%??******************************************???**********************************************************??????%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSS%%%%???******************************************************************************************???????%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSS%%%%???*****************************************************************************????????%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSS%%%%???*****************************************************************????????%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSS%%%%??******************************************************????????%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSS%%%%???******************************************???????%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSS%%%%??******************************???????%%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSS%%%%???******************???????%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%??******????????%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%????%%%%%%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//                                                                                      ERC 721 BY MRSNOWY10                                                                                  //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TPV is ERC721Creator {
    constructor() ERC721Creator("The Pinco Verse", "TPV") {}
}
