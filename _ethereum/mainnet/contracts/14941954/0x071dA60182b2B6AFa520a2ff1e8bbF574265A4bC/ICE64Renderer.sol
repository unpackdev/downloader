// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*


        .++++++    .-=+**++=:  -+++++++++++-      .-=+**.     .++++:      
         :@@@@. .+%@#++++#@@@@#=*@@@%++*@@@*   :*@@%+=-:      +@@@+       
          %@@# +@@+        :#@@#.@@@=    :#+ .#@@*.          -@@@+        
          #@@#*@@=           *@# @@@@-      -@@@*+*+=-      :@@@= =       
          #@@@@@@             += @@@@@@%%%=:@@@@*++#@@@#:  :@@@--%#       
          #@@@@@@                @@@= -*@@=#@@@     .*@@@--@@# +@@#   =   
          #@@@@@@-               @@@=    :.@@@%       #@@@@@+..+@@%-*@@   
          #@@#%@@@-           .%@@@@=      #@@@:      -@@@@@@@@@@@@@@@@   
          %@@# #@@@#-       :+@%-@@@=     :%@@@%.     *@@+     +@@%       
         :@@@@. :*@@@@%###%@@#= +@@@#++#%@@@**@@@#=-=%@%-     .@@@@-      
        .*****+    :=*###*+-.  -************:  -*###*=:      :******=

        M E T A D A T A   &   R E N D E R I N G   C O N T R A C T

*/

import "./Strings.sol";
import "./DynamicBuffer.sol";
import "./Base64.sol";

import "./IICE64.sol";
import "./IICE64DataStore.sol";
import "./IICE64Renderer.sol";
import "./IExquisiteGraphics.sol";

/**
@title ICE64 Renderer
@author Sam King (samkingstudio.eth)
@notice This contract renders token metadata for the main ICE64 contract: a standard baseURI
        for original photos stored off-chain, and base64 encoded on-chain SVGs for editions.

        Code is licensed as MIT.
        https://spdx.org/licenses/MIT.html

        Token metadata and images licensed as CC BY-NC 4.0
        https://creativecommons.org/licenses/by-nc/4.0/
        You are free to:
            - Share: copy and redistribute the material in any medium or format
            - Adapt: remix, transform, and build upon the material
        Under the following terms:
            - Attribution: You must give appropriate credit, provide a link to the license,
            and indicate if changes were made. You may do so in any reasonable manner, but not
            in any way that suggests the licensor endorses you or your use.
            - NonCommercial: You may not use the material for commercial purposes
            - No additional restrictions: You may not apply legal terms or technological measures
            that legally restrict others from doing anything the license permits.

*/
contract ICE64Renderer is IICE64Renderer {
    using Strings for uint256;
    using DynamicBuffer for bytes;

    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev The address of the token ownership contract
    IICE64 public ice64;

    /// @dev The address of the on-chain data storage contract
    IICE64DataStore public dataStore;

    /// @dev The address of the xqstgfx public rendering contract
    IExquisiteGraphics public xqstgfx;

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /// @param ice64_ The address of the token ownership contract
    /// @param ice64DataStore_ The address of the on-chain data storage contract
    /// @param xqstgfx_ The address of the xqstgfx public rendering contract
    constructor(
        address ice64_,
        address ice64DataStore_,
        address xqstgfx_
    ) {
        ice64 = IICE64(ice64_);
        dataStore = IICE64DataStore(ice64DataStore_);
        xqstgfx = IExquisiteGraphics(payable(xqstgfx_));
    }

    /* ------------------------------------------------------------------------
                             R A W   R E N D E R I N G
    ------------------------------------------------------------------------ */

    /// @notice Draws an SVG from data in the .xqst format to a string
    /// @param data The photo data in .xqst format
    function drawSVGToString(bytes memory data) public view returns (string memory) {
        return string(drawSVGToBytes(data));
    }

    /// @notice Draws an SVG from data in the .xqst format to bytes
    /// @param data The photo data in .xqst format
    function drawSVGToBytes(bytes memory data) public view returns (bytes memory) {
        string memory rects = xqstgfx.drawPixelsUnsafe(data);
        bytes memory svg = DynamicBuffer.allocate(2**19);

        svg.appendSafe(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" width="100%" height="100%" version="1.1" viewBox="0 0 128 128" fill="#fff"><rect width="128" height="128" fill="#fff" /><g transform="translate(32,32)">',
                rects,
                "</g></svg>"
            )
        );

        return svg;
    }

    /* ------------------------------------------------------------------------
                 P U B L I C   F R I E N D L Y   R E N D E R I N G
    ------------------------------------------------------------------------ */

    /// @notice Gets a photo in SVG format
    /// @param id The id of the photo to render
    function getEditionPhotoSVG(uint256 id) external view returns (string memory) {
        bytes memory data = dataStore.getRawPhotoData(id);
        return drawSVGToString(data);
    }

    /// @notice Gets a photo in Base64 encoded SVG format
    /// @param id The id of the photo to render (use original photo's id: `getEditionId(id)`)
    function getEditionPhotoBase64SVG(uint256 id) external view returns (string memory) {
        bytes memory data = dataStore.getRawPhotoData(id);
        bytes memory svg = drawSVGToBytes(data);
        bytes memory svgBase64 = DynamicBuffer.allocate(2**19);

        svgBase64.appendSafe("data:image/svg+xml;base64,");
        svgBase64.appendSafe(bytes(Base64.encode(svg)));

        return string(svgBase64);
    }

    /* ------------------------------------------------------------------------
                         O N - C H A I N   T O K E N U R I
    ------------------------------------------------------------------------ */

    /// @notice Renders metadata for a given token id
    /// @dev If the photo is an edition, then render an SVG, otherwise return the constructed URI
    /// @param id The token id to render
    function tokenURI(uint256 id) external view returns (string memory) {
        if (!ice64.isEdition(id)) {
            return string(abi.encodePacked(dataStore.getBaseURI(), id.toString()));
        }

        uint256 originalId = ice64.getOriginalTokenId(id);
        string memory originalIdStr = originalId.toString();

        bytes memory data = dataStore.getRawPhotoData(originalId);
        bytes memory svg = drawSVGToBytes(data);

        bytes memory svgBase64 = DynamicBuffer.allocate(2**19);
        svgBase64.appendSafe("data:image/svg+xml;base64,");
        svgBase64.appendSafe(bytes(Base64.encode(svg)));

        bytes memory json = DynamicBuffer.allocate(2**19);
        bytes memory jsonBase64 = DynamicBuffer.allocate(2**19);

        json.appendSafe(
            abi.encodePacked(
                '{"symbol":"ICE64","name":"ICE64 #',
                originalIdStr,
                ' (Edition)","description":"A fully on-chain edition of ICE64 #',
                originalIdStr,
                ". Edition size of ",
                ice64.getMaxEditions().toString(),
                '. Each edition is 64x64px in size with a 32px border, 64 colors, and stored on the Ethereum blockchain forever.","image":"',
                string(svgBase64),
                '","external_url":"https://ice64.com/photo/',
                id.toString(),
                '","attributes":[{"trait_type":"Size","value":"64x64px"},{"trait_type":"Border","value":"32px"},{"trait_type":"Colors","value":"64"}]}'
            )
        );

        jsonBase64.appendSafe("data:application/json;base64,");
        jsonBase64.appendSafe(bytes(Base64.encode(json)));

        return string(jsonBase64);
    }
}
