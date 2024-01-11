// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Structs.sol";

interface ICelestialCastle {
    function retrieveFreaks(
        address owner,
        uint256[] memory freakIds,
        Freak[] memory freaksAttributes
    ) external;

    function retrieveCelestials(
        address owner,
        uint256[] memory celestialIds,
        CelestialV2[] memory celestialAttributes
    ) external;

    function retrieveBucks(address owner, uint256 amount) external;
}
