// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMToken {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function burnSupply(address to, uint256 amount) external;

}