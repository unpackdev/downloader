// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "./Sanitize.sol";
import "./IIconRenderer.sol";
import "./Strings.sol";

contract IconRenderer is IIconRenderer {
    using Strings for uint8;
    using Strings for uint256;
    using Sanitize for string;

    string constant DATA_URL_SVG_IMAGE = "data:image/svg+xml;utf8,";

    function imageURL(uint256 tokenID, string calldata style)
        external
        pure
        override
        returns (string memory)
    {
        return string.concat(DATA_URL_SVG_IMAGE, svg(tokenID, style));
    }

    function svg(uint256 tokenID, string memory style)
        public
        pure
        returns (string memory)
    {
        string memory s = string.concat(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>"
            "<style>svg{background:white} rect{fill:black;stroke:black;stroke-width:.0001px;width:1px;height:1px;shape-rendering:crispedges} ",
            style,
            "</style>"
        );

        for (uint256 i = 0; i < 256; ++i) {
            uint256 shift = i;
            if (tokenID & (1 << shift) != 0) {
                string memory x = (i % 16).toString();
                string memory y = (i / 16).toString();
                s = string.concat(
                    s,
                    "<rect class='x",
                    x,
                    " y",
                    y,
                    "' x='",
                    x,
                    "' y='",
                    y,
                    "'/>"
                );
            }
        }
        return string.concat(s, "</svg>");
    }
}
