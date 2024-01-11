
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Coalesce
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ssssssssssssssssssssssssssOOOOOOOOOhhhhhhhhEEEEEEEEEddddddddddddddRRRRRRRRRRRRRRoooooNNNNiiiiSSSSooooHHHeeeeDDDDDrrrrrrO    //
//    ssssssssssssssssssssssssssOOOOOOOOOhhhhhhhhEEEEEEEEEddddddddddddddRRRRRRRRRRRRRRoooooNNNNiiiiSSSSooooHHHeeeeDDDDDrrrrrrO    //
//    sssssssssssssssssssssssssssOOOOOOOOOhhhhhhhEEEEEEEEEddddddddddddddRRRRRRRRRRRRRooooooNNNNiiiiSSSSooooHHHeeeeeDDDDDrrrrrr    //
//    ssssssssssssssssssssssssssssOOOOOOOOOhhhhhhhEEEEEEEEdddddddddddddRRRRRRRRRRRRRRooooooNNNNiiiiSSSSooooHHHHeeeeDDDDDrrrrrr    //
//    ssssssssssssssssssssssssssssssOOOOOOOOhhhhhhhEEEEEEEEddddddddddRRRRRRRRRRRRRRRoooooooNNNNiiiiSSSSSoooHHHHHeeeeDDDDDDrrrr    //
//    sssssssssssssssssssssssssssssssOOOOOOOOhhhhhhEEEEEEEEdddddddddRRRRRRRRRRRRRRRoooooooNNNNNiiiiiSSSSooooHHHHHeeeeeDDDDrrrr    //
//    sssssssssssssssssssssssssssssssssOOOOOOOhhhhhhEEEEEEEddddddddRRRRRRRRRRRRRRoooooooooNNNNNiiiiiSSSSSooooHHHHHeeeeeDDDDDrr    //
//    ssssssssssssssssssssssssssssssssssOOOOOOOhhhhhhEEEEEdddddddRRRRRRRRRRRoooooooooooooNNNNNNiiiiiSSSSSSooooHHHHHeeeeeDDDDDr    //
//    sssssssssssssssssssssssssssssssssssOOOOOOhhhhhhEEEEEddddddRRRRRRRRRooooooooooooooNNNNNNNNiiiiiiSSSSSSooooHHHHHHeeeeeDDDD    //
//    sssssssssssssssssssssIIIIsssssssssssOOOOOOhhhhhEEEEEdddddRRRRRRRRoooooooooooooooNNNNNNNNNiiiiiiSSSSSSooooooHHHHHeeeeeDDD    //
//    ssssssssssssssssssssIIIIIIIsssssssssOOOOOOhhhhhEEEEdddddRRRRRRoooooooooooooNNNNNNNNNNNNNiiiiiiiiSSSSSSooooooHHHHHeeeeeDD    //
//    ssssssssssssssssssssIIIIIIIsssssssssOOOOOOhhhhEEEEEddddRRRRRRoooooooooNNNNNNNNNNNNNNNNiiiiiiiiiiSSSSSSSooooooHHHHHeeeeeD    //
//    ssssssssssssssssssssssIIIIssssssssssOOOOOhhhhhEEEEddddRRRRRoooooooNNNNNNNNNNNNNNNNNiiiiiiiiiiiiSSSSSSSSoooooooHHHHHeeeee    //
//    OOOOOOsssssssssssssssssssssssssssssOOOOOhhhhhEEEEddddRRRRRoooooNNNNNNNNNNNNNNiiiiiiiiiiiiiiiiSSSSSSSSSSooooooooHHHHHeeee    //
//    OOOOOOOOOOssssssssssssssssssssssssOOOOOhhhhhEEEEddddRRRRoooooNNNNNNNNiiiiiiiiiiiiiiiiiiiiiiSSSSSSSSSSSSooooooooHHHHHeeee    //
//    OOOOOOOOOOOOOsssssssssssssssssssOOOOOOhhhhEEEEEdddRRRRoooooNNNNNNiiiiiiiiiiiiiiiiiiiiiiSSSSSSSSSSSSSSooooooooooHHHHHHeee    //
//    OOOOOOOOOOOOOOOOOssssssssssssOOOOOOOhhhhhEEEEddddRRRRoooooNNNNNiiiiiiiiiiiiiiiiiiSSSSSSSSSSSSSSSSSSSoooooooooooHHHHHHeee    //
//    hhhOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOhhhhEEEEEddddRRRRooooNNNNNiiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSSooooooooooooHHHHHHHHeee    //
//    hhhhhhhhhhhOOOOOOOOOOOOOOOOOOOOOhhhhhhEEEEdddddRRRoooooNNNNNiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSoooooooooooooooHHHHHHHHHeee    //
//    hhhhhhhhhhhhhhhhOOOOOOOOOOOOOOhhhhhhEEEEEddddRRRRoooooNNNNNiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSoooooooooooooooHHHHHHHHHHHHHee    //
//    EEEEEEEhhhhhhhhhhhhhhhhhhhhhhhhhhhEEEEEddddRRRRRooooNNNNNNiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSoooooooooooooHHHHHHHHHHHHHHHHHee    //
//    EEEEEEEEEEEEEhhhhhhhhhhhhhhhhhhhEEEEEEddddRRRRRooooNNNNNNiiiiiiiiSSSSSSSSSSSSSSSSSSSSSooooooooooooHHHHHHHHHHHHHHHHHHHeee    //
//    ddddEEEEEEEEEEEEEEEhhhhhhhhhhEEEEEEEddddRRRRRoooooNNNNNNiiiiiiiiSSSSSSSSSSSSSSSSSSSSSoooooooooooHHHHHHHHHHHHHHHHHHHHeeee    //
//    dddddddddddEEEEEEEEEEEEEEEEEEEEEEEdddddRRRRRoooooNNNNNNiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSoooooooooHHHHHHHHHHHHHHHHHHeeeHeeeH    //
//    ddddddddddddddddEEEEEEEEEEEEEEEEdddddRRRRRoooooNNNNNNiiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSooooooooHHHHHHHHHHHeeeeeeeeeeeeeeHH    //
//    RRRRRRRRRddddddddddddEEEEEEEEdddddddRRRRRoooooNNNNNNiiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSooooooooHHHHHHHHHeeeeeeeeeeeeeeeeeHH    //
//    RRRRRRRRRRRRRddddddddddddddddddddddRRRRoooooNNNNNNNiiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSoooooooHHHHHHHHHeeeeeeeeeeeeeeeeeeHH    //
//    ooooooRRRRRRRRRRRddddddddddddddddRRRRRoooooNNNNNNiiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSoooooooHHHHHHHeeeeeeeeeeeeeeeeeeeeHH    //
//    ooooooooooRRRRRRRRRRdddddddddddRRRRRRoooooNNNNNNiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSSoooooooHHHHHHHHeeeeeeeeeeeeeeeeeeeeHH    //
//    ooooooooooooRRRRRRRRRRRRdddRRRRRRRRRoooooNNNNNNiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSSSooooooooHHHHHHHHeeeeeeeeeeeeeeeeeeeeHH    //
//    ooooooooooooooRRRRRRRRRRRRRRRRRRRRoooooNNNNNNiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSSSSSooooooooHHHHHHHHeeeeeeeeeeeeeeeeeeeHHH    //
//    oooooooooooooooooRRRRRRRRRRRRRoooooooNNNNNiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSooooooooHHHHHHHHHHeeeeeeeeeeeeeHHHHHH    //
//    ooooooooooooooooooooooooooooooooooNNNNNiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSooooooooHHHHHHHHHHHHHHHHHHHHHHHHHHH    //
//    ooooooooooooooooooooooooooooNNNNNNNiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSooooooooooHHHHHHHHHHHHHHHHHHHHHHH    //
//    ooooooooooooooooooNNNNNNNNNNNNiiiiiiiSSSSSSSSSSooooooSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSooooooooooooooHHooHHoooooooooo    //
//    oooooooooooooNNNNNNNNNNNiiiiiiiSSSSSSSooooooooooooooooooSSSSSSSSSSSSiiiiiiiiiiiiiiiiSSSSSSSSSSSSoooooooooooooooooooooooo    //
//    ooooooooooooNNNNNNNiiiiiiiSSSSSSooooooooooHHHHoooooooooooSSSSSSSSiiiiiiiiiiiiiiiiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSSSSSooooo    //
//    ooooooooooNNNNNNNiiiiiSSSSSooooooHHHHHHHHHHHHHHHHHHooooooSSSSSSiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiSSSSSSSSSSSSSSSSSSSSSSS    //
//    ooooooooooNNNNNiiiiSSSSSooooHHHHHHHeeeeeeeeeeHHHHHHHoooooSSSSSiiiiiiiNNNNNNNNNNNNNNNNNNNNNiiiiiiiiiiiiiiiiiiiiiiiiiSSSSS    //
//    ooooooooNNNNNiiiiSSSSooooHHHHHeeeeeeeeeeeeeeeeeeHHHHooooSSSSSiiiiiNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNiiiiiiiSS    //
//    oooooooNNNNNiiiiSSSooooHHHHeeeeeDDDDDDDDDDDeeeeeeHHHooooSSSSiiiiNNNNNNoooooooooooooooooooooooNNNNNNNNNNNNNNNNNNNNNNiiiii    //
//    ooNNNNNNNNiiiiSSSooooHHHeeeeDDDDDDDDDDDDDDDDDeeeeHHHoooSSSSiiiNNNNNoooooooooooooooooooooooooooooooooooooooooooooNNNNNNii    //
//    NNNNNNNiiiiiSSSooooHHHeeeeDDDDDDrrrrrrrDDDDDDeeeeHHHoooSSSiiiNNNooooooRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRoooooooooooooooNNNN    //
//    iiiiiiiiiSSSSooooHHHeeeeDDDDDrrrrrrrrrrrDDDDDeeeHHHoooSSiiiNNNNooooRRRRRRRRRRRRddddddRRRRRRRRRRRRRRRRRRRRRRRRRRRoooooNNN    //
//    iiSSSSSSSSooooHHHHeeeeDDDDDrrrrrrrrrrrrrDDDDeeeHHHoooSSSiiNNNoooRRRRRddddddddddddddddddddddddddddddddRRRRRRRRRRRRRRooooN    //
//    SSSooooooooHHHHHeeeeDDDDDDrrrrrrrrrrrrrDDDDeeeHHHoooSSiiiNNNoooRRRRddddddddddddEEEEEEEdEdddddddddddddddddddddddRRRRRRooo    //
//    oooooHHHHHHHeeeeeDDDDDDDrrrrrrrrrrrrrDDDDDeeeHHHoooSSiiiNNNoooRRRddddddEEEEEEEEEEEEEEEEEEEEEEEEEEddddddddddddddddRRRRRoo    //
//    HHHHHHHeeeeeeeDDDDDDrrrrrrrrrrrrrrrrDDDDDeeeHHHoooSSiiiNNNoooRRRdddddEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEdddddddddddRRRRR    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract COALESCE is ERC721Creator {
    constructor() ERC721Creator("Coalesce", "COALESCE") {}
}
