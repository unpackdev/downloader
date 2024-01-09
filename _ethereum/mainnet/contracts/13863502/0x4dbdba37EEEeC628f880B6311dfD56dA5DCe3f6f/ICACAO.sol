// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IInblockGuard.sol";


interface ICACAO is IInblockGuard {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}