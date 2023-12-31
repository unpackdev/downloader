// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ISVGConstructor
 * @author @NiftyMike | @NFTCulture
 * @dev A simple interface for rendering an SVG.
 */
interface ISVGConstructor {
    function constructFromPNG(
        bool hasBackground,
        string memory backgroundColor,
        string memory pngDataURI
    ) external view returns (string memory);
}
