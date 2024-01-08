// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
interface IAccessController {
    function updatePremiumOfPool(address pool, uint256 newAquaPremium) external;

    function addPools(
        address[] calldata tokenA,
        address[] calldata tokenB,
        uint256[] calldata aquaPremium
    ) external;

    function updatePoolStatus(
        address pool
    ) external;

    function updatePrimary(
        address newAddress
    ) external;

    function whitelistedPools(
        address pool
    )
    external
    returns (
        uint256,
        bool,
        bytes calldata data
    );
}