// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./IGorfSeeder.sol";

interface IGorfDecorator {
    function genericDataURI(
        string calldata name,
        string calldata description,
        IGorfSeeder.Seed memory seed
    ) external view returns (string memory);
}