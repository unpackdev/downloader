// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IStripToken is IERC20 {
    function decimals() external view returns (uint256);
    function setMultiSigAdminAddress(address) external;
    function recoverERC20(address, uint256) external;
}
