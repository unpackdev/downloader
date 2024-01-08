// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./IERC20.sol";

interface IRing is IERC20 {
    function delegate(address delegatee) external;
    function setMinter(address minter_) external;
}
