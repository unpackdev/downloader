// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                        888
//                        888
//                        888
// 88888b.d88b.   .d88b.  888888 888d888 .d88b.
// 888 "888 "88b d8P  Y8b 888    888P"  d88""88b
// 888  888  888 88888888 888    888    888  888
// 888  888  888 Y8b.     Y88b.  888    Y88..88P
// 888  888  888  "Y8888   "Y888 888     "Y88P"

// 888                    d8b          888                          888
// 888                    Y8P          888                          888
// 888                                 888                          888
// 88888b.  888  888      888 88888b.  888888       8888b.  888d888 888888
// 888 "88b 888  888      888 888 "88b 888             "88b 888P"   888
// 888  888 888  888      888 888  888 888         .d888888 888     888
// 888 d88P Y88b 888      888 888  888 Y88b.       888  888 888     Y88b.
// 88888P"   "Y88888      888 888  888  "Y888      "Y888888 888      "Y888
//               888
//          Y8b d88P
//           "Y88P"

struct MetroTokenProperties {
    uint256 mode; // 0: Curate, 1: Evolve, 2: Lock
    uint256 progress;
    uint256 maxProgress;
    uint256 progressSeedStep;
    uint256 curateCount;
    bytes32 seed;
    bytes32[] progressSeeds;
    uint256 seedSetDate;
}

interface IMetro {
    function mint(address target, uint256 count) external;

    function getTokenProperties(
        uint256 tokenId
    ) external view returns (MetroTokenProperties memory);
}

struct MetroInternalTokenState {
    uint256 mode; // 0: Curate, 1: Evolve, 2: Lock
    uint256 baseSeedSetDate;
    uint256 lockStartDate;
    uint256 progressStartIndex;
    uint256 curateCount;
    bytes32 baseSeed;
}

interface IMetroV2 {
    function mint(address target, uint256 count) external;

    function tokenStates(
        uint256 tokenId
    ) external view returns (MetroInternalTokenState memory);

    function getTokenProperties(
        uint256 tokenId
    ) external view returns (MetroTokenProperties memory);
}
