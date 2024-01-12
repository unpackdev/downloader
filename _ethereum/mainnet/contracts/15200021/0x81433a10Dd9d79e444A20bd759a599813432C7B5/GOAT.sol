
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Goat Slayer
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                               //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    //  xxxxxxxxGGGGGGGGGGGGGxxxxxOOOOOOOOOxxxxxxxxxxxxxxxxxAAAxxxxxxxxxTTTTTTTTTTTTTTTTTTTTTTTxxxxxxxxSSSSSSSSSSSSSSSxLLLLLLLLLLLxxxxxxxxxxxxxxxxxxxxxxxxxxxxAAAxxxxxxxxxxxYYYYYYYxxxxxxxYYYYYYYEEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRRxxx    //
//    //  xxxxxGGG::::::::::::GxxxOO:::::::::OOxxxxxxxxxxxxxxA:::AxxxxxxxxT:::::::::::::::::::::TxxxxxxSS:::::::::::::::SL:::::::::LxxxxxxxxxxxxxxxxxxxxxxxxxxxA:::AxxxxxxxxxxY:::::YxxxxxxxY:::::YE::::::::::::::::::::ER::::::::::::::::Rxx    //
//    //  xxxGG:::::::::::::::GxOO:::::::::::::OOxxxxxxxxxxxA:::::AxxxxxxxT:::::::::::::::::::::TxxxxxS:::::SSSSSS::::::SL:::::::::LxxxxxxxxxxxxxxxxxxxxxxxxxxA:::::AxxxxxxxxxY:::::YxxxxxxxY:::::YE::::::::::::::::::::ER::::::RRRRRR:::::Rx    //
//    //  xxG:::::GGGGGGGG::::GO:::::::OOO:::::::OxxxxxxxxxA:::::::AxxxxxxT:::::TT:::::::TT:::::TxxxxxS:::::SxxxxxSSSSSSSLL:::::::LLxxxxxxxxxxxxxxxxxxxxxxxxxA:::::::AxxxxxxxxY::::::YxxxxxY::::::YEE::::::EEEEEEEEE::::ERR:::::RxxxxxR:::::R    //
//    //  xG:::::GxxxxxxxGGGGGGO::::::OxxxO::::::OxxxxxxxxA:::::::::AxxxxxTTTTTTxxT:::::TxxTTTTTTxxxxxS:::::SxxxxxxxxxxxxxxL:::::LxxxxxxxxxxxxxxxxxxxxxxxxxxA:::::::::AxxxxxxxYYY:::::YxxxY:::::YYYxxE:::::ExxxxxxxEEEEEExxR::::RxxxxxR:::::R    //
//    //  G:::::GxxxxxxxxxxxxxxO:::::OxxxxxO:::::OxxxxxxxA:::::A:::::AxxxxxxxxxxxxT:::::TxxxxxxxxxxxxxS:::::SxxxxxxxxxxxxxxL:::::LxxxxxxxxxxxxxxxxxxxxxxxxxA:::::A:::::AxxxxxxxxxY:::::YxY:::::YxxxxxE:::::ExxxxxxxxxxxxxxxR::::RxxxxxR:::::R    //
//    //  G:::::GxxxxxxxxxxxxxxO:::::OxxxxxO:::::OxxxxxxA:::::AxA:::::AxxxxxxxxxxxT:::::TxxxxxxxxxxxxxxS::::SSSSxxxxxxxxxxxL:::::LxxxxxxxxxxxxxxxxxxxxxxxxA:::::AxA:::::AxxxxxxxxxY:::::Y:::::YxxxxxxE::::::EEEEEEEEEExxxxxR::::RRRRRR:::::Rx    //
//    //  G:::::GxxxxGGGGGGGGGGO:::::OxxxxxO:::::OxxxxxA:::::AxxxA:::::AxxxxxxxxxxT:::::TxxxxxxxxxxxxxxxSS::::::SSSSSxxxxxxL:::::LxxxxxxxxxxxxxxxxxxxxxxxA:::::AxxxA:::::AxxxxxxxxxY:::::::::YxxxxxxxE:::::::::::::::ExxxxxR:::::::::::::RRxx    //
//    //  G:::::GxxxxG::::::::GO:::::OxxxxxO:::::OxxxxA:::::AxxxxxA:::::AxxxxxxxxxT:::::TxxxxxxxxxxxxxxxxxSSS::::::::SSxxxxL:::::LxxxxxxxxxxxxxxxxxxxxxxA:::::AxxxxxA:::::AxxxxxxxxxY:::::::YxxxxxxxxE:::::::::::::::ExxxxxR::::RRRRRR:::::Rx    //
//    //  G:::::GxxxxGGGGG::::GO:::::OxxxxxO:::::OxxxA:::::AAAAAAAAA:::::AxxxxxxxxT:::::TxxxxxxxxxxxxxxxxxxxxSSSSSS::::SxxxL:::::LxxxxxxxxxxxxxxxxxxxxxA:::::AAAAAAAAA:::::AxxxxxxxxxY:::::YxxxxxxxxxE::::::EEEEEEEEEExxxxxR::::RxxxxxR:::::R    //
//    //  G:::::GxxxxxxxxG::::GO:::::OxxxxxO:::::OxxA:::::::::::::::::::::AxxxxxxxT:::::TxxxxxxxxxxxxxxxxxxxxxxxxxS:::::SxxL:::::LxxxxxxxxxxxxxxxxxxxxA:::::::::::::::::::::AxxxxxxxxY:::::YxxxxxxxxxE:::::ExxxxxxxxxxxxxxxR::::RxxxxxR:::::R    //
//    //  xG:::::GxxxxxxxG::::GO::::::OxxxO::::::OxA:::::AAAAAAAAAAAAA:::::AxxxxxxT:::::TxxxxxxxxxxxxxxxxxxxxxxxxxS:::::SxxL:::::LxxxxxxxxxLLLLLLxxxxA:::::AAAAAAAAAAAAA:::::AxxxxxxxY:::::YxxxxxxxxxE:::::ExxxxxxxEEEEEExxR::::RxxxxxR:::::R    //
//    //  xxG:::::GGGGGGGG::::GO:::::::OOO:::::::OA:::::AxxxxxxxxxxxxxA:::::AxxxTT:::::::TTxxxxxxxxxxxSSSSSSSxxxxxS:::::SLL:::::::LLLLLLLLL:::::LxxxA:::::AxxxxxxxxxxxxxA:::::AxxxxxxY:::::YxxxxxxxEE::::::EEEEEEEE:::::ERR:::::RxxxxxR:::::R    //
//    //  xxxGG:::::::::::::::GxOO:::::::::::::OOA:::::AxxxxxxxxxxxxxxxA:::::AxxT:::::::::TxxxxxxxxxxxS::::::SSSSSS:::::SL::::::::::::::::::::::LxxA:::::AxxxxxxxxxxxxxxxA:::::AxxYYYY:::::YYYYxxxxE::::::::::::::::::::ER::::::RxxxxxR:::::R    //
//    //  xxxxxGGG::::::GGG:::GxxxOO:::::::::OOxA:::::AxxxxxxxxxxxxxxxxxA:::::AxT:::::::::TxxxxxxxxxxxS:::::::::::::::SSxL::::::::::::::::::::::LxA:::::AxxxxxxxxxxxxxxxxxA:::::AxY:::::::::::YxxxxE::::::::::::::::::::ER::::::RxxxxxR:::::R    //
//    //  xxxxxxxxGGGGGGxxxGGGGxxxxxOOOOOOOOOxxAAAAAAAxxxxxxxxxxxxxxxxxxxAAAAAAATTTTTTTTTTTxxxxxxxxxxxxSSSSSSSSSSSSSSSxxxLLLLLLLLLLLLLLLLLLLLLLLLAAAAAAAxxxxxxxxxxxxxxxxxxxAAAAAAAYYYYYYYYYYYYYxxxxEEEEEEEEEEEEEEEEEEEEEERRRRRRRRxxxxxRRRRRRR    //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    //  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GOAT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
