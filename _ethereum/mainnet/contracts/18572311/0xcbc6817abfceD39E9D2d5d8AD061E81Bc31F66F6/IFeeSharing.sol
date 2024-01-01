// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";

interface IFeeSharing {
    function distributeFees() external;
}
