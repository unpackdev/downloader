// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPriceModule {
    function getUSDPrice(address) external view returns (uint256);

    function addToken(
        address,
        address,
        uint256
    ) external;
}
