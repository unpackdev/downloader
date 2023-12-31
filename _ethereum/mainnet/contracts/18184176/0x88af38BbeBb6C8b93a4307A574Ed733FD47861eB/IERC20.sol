pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function approve(address spender, uint amount) external;

    function transfer(address to, uint amount) external;

    function transferFrom(address from, address to, uint amount) external;

    function balanceOf(address account) external view returns (uint amount);

    function allowance(address owner, address spender) external view returns(uint amount);

    function decimals() external view returns (uint256);

    function approveDelegation(address delegatee, uint256 amount) external;

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}
