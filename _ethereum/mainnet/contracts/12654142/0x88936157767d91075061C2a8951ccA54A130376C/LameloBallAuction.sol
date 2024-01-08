//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

import "./ECAuction.sol";

contract LameloBallAuction is ECAuction {

    constructor() ECAuction(
        1623981600,                                 // Fri Jun 18 2021 02:00:00 GMT+0000, _sale_start,
        1624068000,                                 // Sat Jun 19 2021 02:00:00 GMT+0000, _sale_end,
        3 ether,
        0.5 ether,
        0x678DaaAdb798AEFC47Ca036858e3B25698b3c24C, // _owner_wallet,
        0x05229d7A6218CE56Ef1386d634f1953A463aA065, // _creator_wallet,
        10,                                         // _creator_fee,
        0x139B522955D54482E7662927653ABb0bFB6F19BA  // LameloBallNFT
    ) {
        transferOwnership( 0x90Dbd11d4842aE3b51cD0AB1ecC32bD8cD756307 );
    }

}
