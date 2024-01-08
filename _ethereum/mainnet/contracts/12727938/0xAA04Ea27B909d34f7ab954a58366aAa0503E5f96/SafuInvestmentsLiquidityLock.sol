// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TokenTimelock.sol";

contract SafuInvestmentsLiquidityLock is TokenTimelock {
    constructor(
        IERC20 _token,
        address _presaleCreator,
        uint256 _releaseTime,
        address _safuInfo
    ) public TokenTimelock(_token, _presaleCreator, _releaseTime, _safuInfo) {}
}
