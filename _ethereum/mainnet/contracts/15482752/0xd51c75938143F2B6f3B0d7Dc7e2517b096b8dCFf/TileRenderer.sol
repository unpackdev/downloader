// SPDX-License-Identifier: MIT

/*
 *                ,dPYb,   I8         ,dPYb,
 *                IP'`Yb   I8         IP'`Yb
 *                I8  8I88888888 gg   I8  8I
 *                I8  8'   I8    ""   I8  8'
 *   ,ggg,,ggg,   I8 dP    I8    gg   I8 dP   ,ggg,     ,g,
 *  ,8" "8P" "8,  I8dP     I8    88   I8dP   i8" "8i   ,8'8,
 *  I8   8I   8I  I8P     ,I8,   88   I8P    I8, ,8I  ,8'  Yb
 * ,dP   8I   Yb,,d8b,_  ,d88b,_,88,_,d8b,_  `YbadP' ,8'_   8)
 * 8P'   8I   `Y8PI8"888 8P""Y88P""Y88P'"Y88888P"Y888P' "YY8P8P
 *                I8 `8,
 *                I8  `8,
 *                I8   8I
 *                I8   8I
 *                I8, ,8'
 *                 "Y8P'
 */

pragma solidity ^0.8.4;

import "./ERC165.sol";
import "./base64.sol";
import "./ITileRenderer.sol";

contract TileRenderer is ITileRenderer, ERC165 {
    uint24[] palette = [
        0x000000,
        0x959595,
        0xe89c9f,
        0xf4c892,
        0xfff8a5,
        0x92c8a0,
        0x86cdf2,
        0x9d87ba,
        0xf0f0f0,
        0x6f4e2b,
        0xda3832,
        0xea983e,
        0xfff34a,
        0x00a359,
        0x006fb6,
        0x5f308c
    ];

    function renderTileMetadata(uint256 number, uint256 _id)
        external
        view
        returns (string memory)
    {
        string memory tileNumber = uint2str(number);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Tile ',
                                tileNumber,
                                '", "description":"Tile ',
                                tileNumber,
                                ' is an on-chain canvas", "image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(renderTile(_id, palette))),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function renderTile(uint256 _id) external view returns (string memory) {
        return renderTile(_id, palette);
    }

    function renderTile(uint256 _colors, uint24[] memory _palette)
        internal
        pure
        returns (string memory)
    {
        string memory tile;
        tile = string(
            '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" shape-rendering="crispEdges">'
        );
        for (uint8 i = 0; i < 8; i = i + 1) {
            tile = string(
                abi.encodePacked(tile, renderRow(_colors, i, _palette))
            );
        }
        tile = string(abi.encodePacked(tile, "</svg>"));
        return tile;
    }

    function renderRow(
        uint256 _colors,
        uint8 _row,
        uint24[] memory _palette
    ) internal pure returns (string memory) {
        string memory row;
        for (uint8 i = 0; i < 8; i = i + 1) {
            // The data is encoded as 64 4-bit integers.
            uint8 colorIndex = uint8(_colors >> (((8 * _row) + i) * 4)) & 0x0f;
            string memory color = uint24tohexstr(_palette[colorIndex]);
            row = string(
                abi.encodePacked(
                    row,
                    '<rect x="',
                    uint8tohexchar(uint8(i & 0x0f)),
                    '00" y="',
                    uint8tohexchar(uint8(_row & 0x0f)),
                    '00" width="100" height="100" style="fill:#',
                    color,
                    ';" />'
                )
            );
        }
        return row;
    }

    function uint8tohexchar(uint8 i) internal pure returns (uint8) {
        return (i > 9) ? (i + 87) : (i + 48);
    }

    function uint24tohexstr(uint24 i) internal pure returns (string memory) {
        bytes memory o = new bytes(6);
        uint24 mask = 0x00000f;
        o[5] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[4] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[3] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[2] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[1] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[0] = bytes1(uint8tohexchar(uint8(i & mask)));
        return string(o);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(ITileRenderer).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
