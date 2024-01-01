// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRoyalties {
    function royaltyInfo(
        address token,
        uint256 salePrice
    ) external view returns (address, uint256);
}
