// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IBMon is IERC20 {
    function logPresaleParticipants(address _recipient, uint256 _amount) external;
}