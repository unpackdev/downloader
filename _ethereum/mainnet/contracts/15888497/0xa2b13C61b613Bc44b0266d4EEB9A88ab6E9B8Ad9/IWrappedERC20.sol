// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./IERC20.sol";

interface IWrappedERC20 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}
