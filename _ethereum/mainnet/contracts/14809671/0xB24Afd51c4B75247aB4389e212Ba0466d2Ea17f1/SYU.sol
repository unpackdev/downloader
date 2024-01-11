
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Salyaku
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//        lllllllllllllllllllllllllllllllllllllllllyuyyyayyyyyyyyyyuusllllllllllllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllluyyaakkkkkkkkkkkkkkkkkkkkkkkkkayyusllllllllllllllllllllllllllllllll    //
//        lllllllllllllllllllllllllllluyakkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkayuslllllllllllllllllllllllllll    //
//        lllllllllllllllllllllllluaakkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkyuslllllllllllllllllllllll    //
//        llllllllllllllllllllluakkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkysllllllllllllllllllll    //
//        lllllllllllllllllluakkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkuslllllllllllllllll    //
//        llllllllllllllllykkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkyulllllllllllllll    //
//        lllllllllllllsakkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkulllllllllllll    //
//        llllllllllllakkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkulllllllllll    //
//        llllllllllykkkkkkkkkkkkkkkkkkkkkkkkkkkkllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkyslllllllll    //
//        llllllllyakkkkkkkkkkkkkkkkkkkkklllllllllllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkullllllll    //
//        llllllllkkkkkkkkkkkkkkkkkkklllllllllllllllllllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkylllllll    //
//        lllllllkkkkkkkkkkkkkkkkklllllllllllllllllllllllllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkslllll    //
//        lllllakkkkkkkkkkkkkkkklllllllllllllllllllllsysuuuuuuuuusyslllllllllllllllllllllkkkkkkkkkkkkkkkksllll    //
//        lllllkkkkkkkkkkkkkkkkllllllllllllllluyaakkkkkkkkkkkkkkkkkkkkayuulllllllllllllllllkkkkkkkkkkkkkkkslll    //
//        lllykkkkkkkkkkkkkkkkullllllllllllyakkkkkkkkkkkkkkkkkkkkkkkkkkkkkkaulllllllllllllllkkkkkkkkkkkkkkklll    //
//        lllkkkkkkkkkkkkkkkkkllllllllllllakkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkullllllllllllslkkkkkkkkkkkkkkull    //
//        lllkkkkkkkkkkkkkkkkullllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkylllyuyyaakkkkkkkkkkkkkkkkkkksl    //
//        llkkkkkkkkkkkkkkkkkkllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkakkkkkkkkkkkkkkkkkkkkkkkkkkkyl    //
//        llkkkkkkkkkkkkkkkkkkulllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkl    //
//        lakkkkkkkkkkkkkkkkkkkullllllllllllllllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkku    //
//        lkkkkkkkkkkkkkkkkkkkkkyullllllllllllllllllllllllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkku    //
//        lkkkkkkkkkkkkkkkkkkkkkkkkyullllllllllllllllllllllllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkku    //
//        lkkkkkkkkkkkkkkkkkkkkkkkkkkkayuuslllllllllllllllllllllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkku    //
//        lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkaayyyuyuuuuuusyyyyyyyyssllllllllllllllllllllllllkkkkkkkkkkkkkkkku    //
//        lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkaayuslllllllllllllllkkkkkkkkkkkkkkku    //
//        llkkkkkkkkkkkkkkkkkkkkklllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkysllllllllllllkkkkkkkkkkkkkkkl    //
//        llkkkkkkkkkkkkkklllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkllllllllllllkkkkkkkkkkkkkkul    //
//        lllkkkkkkkkkkkkkkllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkllllllllllllkkkkkkkkkkkkkkll    //
//        lllkkkkkkkkkkkkkkylllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkllllllllllllukkkkkkkkkkkkkull    //
//        llllkkkkkkkkkkkkkkysllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkklllllllllllllllakkkkkkkkkkkkklll    //
//        lllllkkkkkkkkkkkkkkkulllllllllllllllllllllllllkkkkkkkkkkkkllllllllllllllllllllllllakkkkkkkkkkkkkllll    //
//        llllllkkkkkkkkkkkkkkkkulllllllllllllllllllllllllllllllllllllllllllllllllllllllllukkkkkkkkkkkkkklllll    //
//        lllllllkkkkkkkkkkkkkkkkkysllllllllllllllllllllllllllllllllllllllllllllllllllllyakkkkkkkkkkkkkkllllll    //
//        lllllllllkkkkkkkkkkkkkkkkkkyuslllllllllllllllllllllllllllllllllllllllllllluaakkkkkkkkkkkkkkkulllllll    //
//        llllllllllkkkkkkkkkkkkkkkkkkkkkayuuslllllllllllllllllllllllllllllllsuyaaakkkkkkkkkkkkkkkkkklllllllll    //
//        llllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkaaayyyyyyyuuuuyyyyyyayyaaaakkkkkkkkkkkkkkkkkkkkkkkklllllllllll    //
//        lllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkklllllllllllll    //
//        llllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkklllllllllllllll    //
//        llllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkklllllllllllllllll    //
//        lllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkllllllllllllllllllll    //
//        lllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkklllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkllllllllllllllllllllllllll    //
//        lllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkklllllllllllllllllllllllllllllll    //
//        llllllllllllllllllllllllllllllllllllllkkkkkkkkkkkkkkkkkkkkkkkkllllllllllllllllllllllllllllllllllllll    //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SYU is ERC721Creator {
    constructor() ERC721Creator("Salyaku", "SYU") {}
}
