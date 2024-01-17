// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IPool.sol";

interface IStrategy {
    function mint(address to) external returns (uint256 minted);

    function burn(address to) external returns (uint256 withdrawal);

    function burnForBase(address to) external returns (uint256 withdrawal);

    function pool() external returns (IPool pool);
}