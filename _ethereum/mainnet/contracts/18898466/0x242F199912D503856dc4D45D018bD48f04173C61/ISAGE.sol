//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IERC20.sol";
import "./IVotes.sol";
import "./IOwnable.sol";

abstract contract ISAGE is IOwnable, IERC20, IVotes {
    function setBlacklisted(address account, bool isBlacklisted) external virtual;
}