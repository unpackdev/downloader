// contracts/IMBytes.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IMBytes is IERC20 {
    function rewardMbytes(address _to, uint256 _amount) external;
}