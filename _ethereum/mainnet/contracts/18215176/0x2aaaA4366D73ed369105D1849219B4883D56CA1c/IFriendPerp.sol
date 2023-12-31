// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IFriendPerp is IERC20 {
    function mint(address _to, uint256 amount_) external;
}