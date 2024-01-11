// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./DataTypes.sol";

interface IWPunkGateway {
    function supplyPunk(
        address pool,
        DataTypes.ERC721SupplyParams[] calldata punkIndexes,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdrawPunk(
        address pool,
        uint256[] calldata punkIndexes,
        address to
    ) external;
}
