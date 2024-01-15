//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SIU is ERC20 {
    constructor() ERC20("sands investment union", "SIU") {
        _mint(
            0x8F35Ca1cF8905676AF36Ab452E468B936d306b0B,
            10000 * 10**uint256(decimals())
        );
    }
}
