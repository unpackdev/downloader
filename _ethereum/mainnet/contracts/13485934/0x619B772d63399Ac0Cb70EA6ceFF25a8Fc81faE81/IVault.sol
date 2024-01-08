// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IVault {
    function pricePerShare() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalAssets() external view returns (uint256);
    function decimals() external view returns (uint256);
}
