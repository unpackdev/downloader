// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./IGOOPsSeeder.sol";

interface IGorfDecorator {
    function backgroundMapping(uint256) external view returns (string memory);
    function bodyMapping(uint256) external view returns (string memory);
    function accessoryMapping(uint256) external view returns (string memory);
    function headMapping(uint256) external view returns (string memory);
    function glassesMapping(uint256) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IGOOPsSeeder.Seed memory seed
    ) external view returns (string memory);
}