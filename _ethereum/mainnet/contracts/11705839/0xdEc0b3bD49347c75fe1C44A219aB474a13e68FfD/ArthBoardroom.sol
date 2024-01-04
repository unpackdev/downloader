// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Boardroom.sol";

contract ArthBoardroom is Boardroom {
    constructor(IERC20 _cash, uint256 _duration)
        public
        Boardroom(_cash, _cash, _duration)
    {}
}
