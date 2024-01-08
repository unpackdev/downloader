// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.3;

import "./EchoBase.sol";

/**
 * @title Echo Token
 * @dev DISCLAIMER
 * The Echo Token is provided by ECHO TECHNOLOGIES SAS
 * By being a holder of this ERC-20 Token (the balanceOf function returns a value greater than zero,
 * or did return a nonzero value at any point in time since your first purchase)
 * you accept the terms and conditions as laid out in [link] in their entirety.
 */
contract NewEchoToken is EchoBase {

    constructor(
        uint256 launchStartTime,
        uint256 launchVolumeLimitDuration,
        address payable charityAddress
    ) EchoBase (launchStartTime, launchVolumeLimitDuration, charityAddress) {}
}