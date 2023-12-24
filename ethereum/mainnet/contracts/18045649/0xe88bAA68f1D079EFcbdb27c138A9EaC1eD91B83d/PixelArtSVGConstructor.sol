// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Local References
import "./ISVGConstructor.sol";

/**
 * @title PixelArtSVGConstructor
 * @author @NiftyMike | @NFTCulture
 * @dev An SVG constructor optimized for pixel art.
 */
contract PixelArtSVGConstructor is ISVGConstructor {
    function constructFromPNG(
        bool hasBackground,
        string memory backgroundColor,
        string memory pngDataURI
    ) external pure override returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" style="image-rendering:pixelated',
                (hasBackground) ? ';background-color:' : '',
                (hasBackground) ? backgroundColor : '',
                (hasBackground) ? ';">' : '">',
                '<image x="0" y="0" width="100%" height="100%" style="image-rendering: pixelated" href="',
                pngDataURI,
                '" /></svg>'
            );
    }
}
