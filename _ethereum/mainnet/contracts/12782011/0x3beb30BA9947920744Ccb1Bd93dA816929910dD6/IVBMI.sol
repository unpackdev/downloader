// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IERC20Upgradeable.sol";

interface IVBMI is IERC20Upgradeable {
    function lockStkBMI(uint256 amount) external;

    function unlockStkBMI(uint256 amount) external;

    function slashUserTokens(address user, uint256 amount) external;
}
