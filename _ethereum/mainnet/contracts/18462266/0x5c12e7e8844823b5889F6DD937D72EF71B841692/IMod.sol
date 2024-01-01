// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMod {
    struct Mod {
        uint256 id;
        string name;
        string description;
        string image;
        string animation;
        string uri;
        uint256[4] bonus;
    }

    event ModCreated(Mod);

    function createMod(Mod calldata mod) external;
}
