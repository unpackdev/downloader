// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ISaverExtended {
    function get_withdraw_fee(IERC20 token, uint256 amount) external view returns (uint256);

    function finalizeWithdraw(IERC20 token) external;
}
