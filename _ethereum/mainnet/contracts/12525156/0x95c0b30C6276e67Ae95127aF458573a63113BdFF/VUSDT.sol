// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VTokenBase.sol";

//solhint-disable no-empty-blocks
contract VUSDT is VTokenBase {
    string public constant VERSION = "3.0.3";

    // USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7
    constructor() VTokenBase("vUSDT Pool", "vUSDT", 0xdAC17F958D2ee523a2206206994597C13D831ec7) {}

    /// @dev Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _value) public pure override returns (uint256) {
        return _value / (10**12);
    }
}
