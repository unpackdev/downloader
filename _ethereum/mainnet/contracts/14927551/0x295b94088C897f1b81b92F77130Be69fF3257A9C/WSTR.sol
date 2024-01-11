// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20.sol";

interface WSTRInterface {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract WSTR is WSTRInterface {}