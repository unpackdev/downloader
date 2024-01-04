// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Boardroom.sol";

contract ArthLiquidityBoardroom is Boardroom {
    constructor(
        IERC20 _cash,
        IERC20 _share,
        uint256 _duration
    ) public Boardroom(_cash, _share, _duration) {}
}
