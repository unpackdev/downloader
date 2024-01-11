// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import "./IERC20.sol";

interface IImpossibleWrappedToken is IERC20 {
    function deposit(address, uint256) external returns (uint256);

    function withdraw(address, uint256) external returns (uint256);

    function amtToUnderlyingAmt(uint256) external returns (uint256);
}
