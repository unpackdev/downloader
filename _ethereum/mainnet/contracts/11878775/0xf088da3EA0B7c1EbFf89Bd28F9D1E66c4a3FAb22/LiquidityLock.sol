// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./TokenTimelock.sol";

contract LiquidityLock is TokenTimelock {
    constructor(IERC20 _token, uint256 _releaseTime) public TokenTimelock(_token, msg.sender, _releaseTime) {}
}
