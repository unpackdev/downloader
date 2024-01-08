//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMutagen {
    function mintGenesis(address, uint8) external;

    function mintMutagen(
        address,
        uint8,
        uint8,
        uint16
    ) external;
}
