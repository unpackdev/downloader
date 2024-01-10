// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDMT_ERC20 {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}