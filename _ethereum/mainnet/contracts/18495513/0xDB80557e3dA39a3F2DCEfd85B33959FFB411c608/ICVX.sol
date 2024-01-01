// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";

/// @notice Interface for the Convex Booster contract
interface ICVXL1 is IERC20 {
    function maxSupply() external view returns (uint256);

    function operator() external view returns (address);

    function reductionPerCliff() external view returns (uint256);

    function totalCliffs() external view returns (uint256);
}
