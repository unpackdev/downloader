// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecks {

    struct StoredCheck {
        uint16[6] composites;  // The tokenIds that were composited into this one
        uint8[5] colorBands;  // The length of the used color band in percent
        uint8[5] gradients;  // Gradient settings for each generation
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint32 epoch;      // Each check is revealed in an epoch
        uint16 seed;      // A unique identifyer to enable swapping
        uint24 day;      // The days since token was created
    }

    struct Check {
        StoredCheck stored;    // We carry over the check from storage
        bool isRevealed;      // Whether the check is revealed
        uint256 seed;        // The instantiated seed for pseudo-randomisation

        uint8 checksCount;    // How many checks this token has
        bool hasManyChecks;  // Whether the check has many checks
        uint16 composite;   // The parent tokenId that was composited into this one
        bool isRoot;       // Whether it has no parents (80 checks)

        uint8 colorBand;    // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8 gradient;    // Linearly through the colorBand [1, 2, 3]
        uint8 direction;  // Animation direction
        uint8 speed;     // Animation speed
    }

    function getCheck(uint256 tokenId) external view returns (Check memory check);

    function colors(uint256 tokenId) external view returns (string[] memory, uint256[] memory);

    function svg(uint256 tokenId) external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

}
