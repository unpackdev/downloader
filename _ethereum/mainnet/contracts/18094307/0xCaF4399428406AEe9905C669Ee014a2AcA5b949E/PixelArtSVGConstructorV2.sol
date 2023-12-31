// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Local References
import "./ISVGConstructor.sol";

/**
 * @title PixelArtSVGConstructorV2
 * @author @NiftyMike | @NFTCulture
 * @dev An SVG constructor optimized for pixel art.
 *
 * This version uses the XHTML approach:
 *     - Inject the PNG dataURI into an <img> wrapped in a <foreignObject>
 *     - Improves compatibility with Webkit(Safari)-based browser engine. Webkit
 *      does not support the pixelated image rendering on <image> objects.
 */
contract PixelArtSVGConstructorV2 is ISVGConstructor {
    function constructFromPNG(
        bool hasBackground,
        string memory backgroundColor,
        string memory pngDataURI
    ) external pure override returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet" viewBox="0 0 320 200" width="100%" height="100%" shape-rendering="crispEdges" style="image-rendering:pixelated',
                (hasBackground) ? ';background-color:' : '',
                (hasBackground) ? backgroundColor : '',
                (hasBackground) ? ';">' : '">',
                '<g><foreignObject x="0" y="0" width="100%" height="100%"><img xmlns="http://www.w3.org/1999/xhtml" width="320" height="200" src="',
                pngDataURI,
                '"></img></foreignObject></g></svg>'
            );
    }
}
