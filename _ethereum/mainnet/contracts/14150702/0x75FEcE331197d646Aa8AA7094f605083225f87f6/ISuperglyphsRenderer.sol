//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Randomize.sol";

/// @title ISuperglyphsRenderer
/// @author Simon Fremaux (@dievardump)
interface ISuperglyphsRenderer {
    struct Configuration {
        uint256 seed;
        uint256 mod;
        int256 z1;
        int256 z2;
        bool randStroke;
        bool fullSymmetry;
        bool darkTheme;
        bytes9[2] colors;
        bytes16 symbols;
    }

    function start(
        uint256 seed,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols
    )
        external
        pure
        returns (Randomize.Random memory random, Configuration memory config);

    /// @dev Rendering function
    /// @param name the token name
    /// @param tokenId the tokenId
    /// @param colorSeed the seed used for coloring, if no color selected
    /// @param selectedColors the user selected colors
    /// @param selectedSymbols the symbols selected by the user
    /// @param frozen if the token customization is frozen
    /// @return the json
    function render(
        string memory name,
        uint256 tokenId,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols,
        bool frozen
    ) external view returns (string memory);
}
