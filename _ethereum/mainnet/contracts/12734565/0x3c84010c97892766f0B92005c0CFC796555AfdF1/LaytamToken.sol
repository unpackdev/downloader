// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";

contract LaytamToken is ERC20{

    constructor() ERC20( "Laytam", "LAYTAM", 18 ){
        _mint( address(0xF6c1B11A0aBEf272b2535F17C27b291390f92715), 200000000e18);
    }

}