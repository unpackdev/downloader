// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBridgeToken {
    function burn(address from, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
