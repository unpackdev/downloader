// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./TokenTimelock.sol";

contract NFTLTimelock is TokenTimelock {
    constructor(
        address nftlAddress,
        address beneficiary_,
        uint256 releaseTime_
    ) TokenTimelock(IERC20(nftlAddress), beneficiary_, releaseTime_) {}
}
