// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./OFTV2.sol";

contract HeraOFT is OFTV2 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _sharedDecimals,
        address _lzEndpoint
    ) OFTV2(_name, _symbol, _sharedDecimals, _lzEndpoint) {}
}
