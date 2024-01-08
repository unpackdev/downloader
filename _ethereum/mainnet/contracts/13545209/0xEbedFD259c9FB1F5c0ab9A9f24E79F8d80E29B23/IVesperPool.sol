// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IERC20.sol";

interface IVesperPool is IERC20 {
    function getPricePerShare() external view returns (uint256);
}
