
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hudson Valley NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//    HHHHHHHHH     HHHHHHHHHVVVVVVVV           VVVVVVVVNNNNNNNN        NNNNNNNNFFFFFFFFFFFFFFFFFFFFFFTTTTTTTTTTTTTTTTTTTTTTT    //
//    H:::::::H     H:::::::HV::::::V           V::::::VN:::::::N       N::::::NF::::::::::::::::::::FT:::::::::::::::::::::T    //
//    H:::::::H     H:::::::HV::::::V           V::::::VN::::::::N      N::::::NF::::::::::::::::::::FT:::::::::::::::::::::T    //
//    HH::::::H     H::::::HHV::::::V           V::::::VN:::::::::N     N::::::NFF::::::FFFFFFFFF::::FT:::::TT:::::::TT:::::T    //
//      H:::::H     H:::::H   V:::::V           V:::::V N::::::::::N    N::::::N  F:::::F       FFFFFFTTTTTT  T:::::T  TTTTTT    //
//      H:::::H     H:::::H    V:::::V         V:::::V  N:::::::::::N   N::::::N  F:::::F                     T:::::T            //
//      H::::::HHHHH::::::H     V:::::V       V:::::V   N:::::::N::::N  N::::::N  F::::::FFFFFFFFFF           T:::::T            //
//      H:::::::::::::::::H      V:::::V     V:::::V    N::::::N N::::N N::::::N  F:::::::::::::::F           T:::::T            //
//      H:::::::::::::::::H       V:::::V   V:::::V     N::::::N  N::::N:::::::N  F:::::::::::::::F           T:::::T            //
//      H::::::HHHHH::::::H        V:::::V V:::::V      N::::::N   N:::::::::::N  F::::::FFFFFFFFFF           T:::::T            //
//      H:::::H     H:::::H         V:::::V:::::V       N::::::N    N::::::::::N  F:::::F                     T:::::T            //
//      H:::::H     H:::::H          V:::::::::V        N::::::N     N:::::::::N  F:::::F                     T:::::T            //
//    HH::::::H     H::::::HH         V:::::::V         N::::::N      N::::::::NFF:::::::FF                 TT:::::::TT          //
//    H:::::::H     H:::::::H          V:::::V          N::::::N       N:::::::NF::::::::FF                 T:::::::::T          //
//    H:::::::H     H:::::::H           V:::V           N::::::N        N::::::NF::::::::FF                 T:::::::::T          //
//    HHHHHHHHH     HHHHHHHHH            VVV            NNNNNNNN         NNNNNNNFFFFFFFFFFF                 TTTTTTTTTTT          //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HVNFT is ERC721Creator {
    constructor() ERC721Creator("Hudson Valley NFTs", "HVNFT") {}
}
