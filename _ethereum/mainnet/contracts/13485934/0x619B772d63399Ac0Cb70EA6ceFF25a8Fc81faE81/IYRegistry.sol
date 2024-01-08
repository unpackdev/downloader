// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IVault.sol";


interface IYRegistry {
    function numTokens() external view returns (uint256);
    function tokens(uint256 index) external view returns (address vault);
    function numVaults(address token) external view returns (uint256);
    function vaults(address token, uint256 index) external view returns (address vault);
}
