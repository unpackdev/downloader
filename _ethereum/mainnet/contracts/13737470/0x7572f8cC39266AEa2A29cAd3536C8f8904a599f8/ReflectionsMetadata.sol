// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Base64.sol";

interface ICorruptionsMetadata {
    function tokenURI(uint256 tokenId, uint256 amount)
        external
        view
        returns (string memory);
}

interface ICorruptionsDataMapper {
    function valueFor(uint256 mapIndex, uint256 key)
        external
        view
        returns (uint256);
}

interface ICorruptionsDeviationWriter {
    function drawCanvas(uint256 tokenId, uint256 amount)
        external
        pure
        returns (string[32] memory);
}

interface ICorruptionsFont {
    function font() external view returns (string memory);
}

struct DeviationInfo {
    string name;
    address contractAddress;
    uint256 extraData;
}

interface ICorruptionsDeviationRegistry {
    function valueFor(uint256 index)
        external
        view
        returns (DeviationInfo memory);
}

struct InsightMap {
    uint256 savedXP;
    uint256 lastSaveBlock;
}

interface ICorruptions {
    function insightMap(uint256 tokenID)
        external
        view
        returns (InsightMap memory);
}

contract ReflectionsMetadata is Ownable, ICorruptionsMetadata {
    string public description;
    ICorruptionsFont private font =
        ICorruptionsFont(0xdf8A48979F33f12952Ab4cF6f960EA4071fc656b);
    ICorruptionsDataMapper private dataMapper =
        ICorruptionsDataMapper(0x7A96d95a787524a27a4df36b64a96910a2fDCF5B);
    ICorruptionsDeviationRegistry private deviationRegistry =
        ICorruptionsDeviationRegistry(
            0x40f7ad19c7F37AcD76958d61Cbc783c77411cd9b
        );
    ICorruptions private corruptions =
        ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E);

    struct RandParts {
        string border;
        string corruptor;
        string phrase;
        string checker;
        bool omitInsight;
        uint16 reduction;
        bool alternate;
    }

    constructor() Ownable() {
        description = "Unknown";
    }

    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }

    function setFont(address fontAddress) public onlyOwner {
        font = ICorruptionsFont(fontAddress);
    }

    function _blank(string[32] memory canvas)
        public
        pure
        returns (string[32] memory)
    {
        for (uint8 i = 0; i < 32; i++) {
            canvas[
                i
            ] = "&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;&#x0002e;";
        }
        return canvas;
    }

    function _insert(
        bytes memory canvasLine,
        uint256 offset,
        bytes memory str,
        bool singleChar
    ) private pure {
        canvasLine[offset * 9 + 0] = str[0];
        if (singleChar) {
            canvasLine[offset * 9 + 1] = "<";
            canvasLine[offset * 9 + 2] = "!";
            canvasLine[offset * 9 + 3] = "-";
            canvasLine[offset * 9 + 4] = "-";
            canvasLine[offset * 9 + 5] = " ";
            canvasLine[offset * 9 + 6] = "-";
            canvasLine[offset * 9 + 7] = "-";
            canvasLine[offset * 9 + 8] = ">";
        } else {
            canvasLine[offset * 9 + 1] = str[1];
            canvasLine[offset * 9 + 2] = str[2];
            canvasLine[offset * 9 + 3] = str[3];
            canvasLine[offset * 9 + 4] = str[4];
            canvasLine[offset * 9 + 5] = str[5];
            canvasLine[offset * 9 + 6] = str[6];
            canvasLine[offset * 9 + 7] = str[7];
            canvasLine[offset * 9 + 8] = str[8];
        }
    }

    function _box(
        string[32] memory canvas,
        string memory char,
        uint256 x,
        uint256 y,
        uint256 w,
        uint256 h,
        bool singleChar
    ) public pure returns (string[32] memory) {
        bytes memory str = bytes(char);
        for (uint256 iy = 0; iy < h; iy++) {
            bytes memory canvasLine = bytes(canvas[iy + y]);
            for (uint256 ix = 0; ix < w; ix++) {
                _insert(canvasLine, ix + x, str, singleChar);
            }
        }
        return canvas;
    }

    function _checkeredBox(
        string[32] memory canvas,
        string memory char,
        string memory char2,
        uint256 x,
        uint256 y,
        uint256 w,
        uint256 h,
        bool singleChar
    ) public pure returns (string[32] memory) {
        bytes memory str = bytes(char);
        bytes memory str2 = bytes(char2);
        for (uint256 iy = 0; iy < h; iy++) {
            bytes memory canvasLine = bytes(canvas[iy + y]);
            for (uint256 ix = 0; ix < w; ix++) {
                _insert(
                    canvasLine,
                    ix + x,
                    ((iy + y) + (ix + x)) % 2 == 0 ? str : str2,
                    singleChar
                );
            }
        }
        return canvas;
    }

    function _drawCircle(
        string[32] memory canvas,
        string memory char,
        uint256 xc,
        uint256 yc,
        uint256 x,
        uint256 y,
        bool singleChar
    ) public pure returns (string[32] memory) {
        bytes memory str = bytes(char);

        _insert(bytes(canvas[yc + y]), xc + x, str, singleChar);
        _insert(bytes(canvas[yc + y]), xc - x, str, singleChar);
        _insert(bytes(canvas[yc - y]), xc + x, str, singleChar);
        _insert(bytes(canvas[yc - y]), xc - x, str, singleChar);
        _insert(bytes(canvas[yc + x]), xc + y, str, singleChar);
        _insert(bytes(canvas[yc + x]), xc - y, str, singleChar);
        _insert(bytes(canvas[yc - x]), xc + y, str, singleChar);
        _insert(bytes(canvas[yc - x]), xc - y, str, singleChar);

        return canvas;
    }

    function _circle(
        string[32] memory canvas,
        string memory char,
        uint256 xc,
        uint256 yc,
        int8 r,
        bool singleChar
    ) public pure returns (string[32] memory) {
        // https://www.geeksforgeeks.org/bresenhams-circle-drawing-algorithm/

        int256 x = 0;
        int256 y = int256(r);
        int256 d = 3 - 2 * r;
        canvas = _drawCircle(
            canvas,
            char,
            xc,
            yc,
            uint256(x),
            uint256(y),
            singleChar
        );
        while (y >= x) {
            x++;

            if (d > 0) {
                y--;
                d = d + 4 * (x - y) + 10;
            } else {
                d = d + 4 * x + 6;
            }
            canvas = _drawCircle(
                canvas,
                char,
                xc,
                yc,
                uint256(x),
                uint256(y),
                singleChar
            );
        }

        return canvas;
    }

    function _middleBox(
        string[32] memory canvas,
        string memory char,
        string memory char2,
        uint256 size,
        bool singleChar
    ) public pure returns (string[32] memory) {
        canvas = _checkeredBox(
            canvas,
            char,
            char2,
            15 - size,
            15 - size,
            size * 2 + 1,
            size * 2 + 1,
            singleChar
        );
        return canvas;
    }

    function _text(
        string[32] memory canvas,
        string memory message,
        uint256 messageLength,
        uint256 x,
        uint256 y
    ) public pure returns (string[32] memory) {
        bytes memory canvasLine = bytes(canvas[y]);
        for (uint256 i = 0; i < messageLength; i++) {
            _insert(
                canvasLine,
                x + i,
                abi.encodePacked(bytes(message)[i]),
                true
            );
        }

        return canvas;
    }

    function _richText(
        string[32] memory canvas,
        string memory message,
        uint256 messageLength,
        uint256 x,
        uint256 y
    ) public pure returns (string[32] memory) {
        bytes memory canvasLine = bytes(canvas[y]);
        for (uint256 i = 0; i < messageLength / 9; i++) {
            bytes memory sequence = abi.encodePacked(
                abi.encodePacked(
                    bytes(message)[i * 9],
                    bytes(message)[i * 9 + 1],
                    bytes(message)[i * 9 + 2],
                    bytes(message)[i * 9 + 3],
                    bytes(message)[i * 9 + 4],
                    bytes(message)[i * 9 + 5]
                ),
                bytes(message)[i * 9 + 6],
                bytes(message)[i * 9 + 7],
                bytes(message)[i * 9 + 8]
            );
            _insert(canvasLine, x + i, sequence, false);
        }

        return canvas;
    }

    function draw(
        uint256 tokenId,
        uint256 amount,
        string[32] memory oCanvas
    ) public view returns (string memory) {
        string[31] memory lookup = [
            "20",
            "31",
            "42",
            "53",
            "64",
            "75",
            "86",
            "97",
            "108",
            "119",
            "130",
            "141",
            "152",
            "163",
            "174",
            "185",
            "196",
            "207",
            "218",
            "229",
            "240",
            "251",
            "262",
            "273",
            "284",
            "295",
            "306",
            "317",
            "328",
            "339",
            "350"
        ];

        string[40] memory randomStrings = [
            "/",
            "$",
            "|",
            "8",
            "_",
            "?",
            "#",
            "%",
            "^",
            "~",
            ":",
            "#0D1302",
            "#020A13",
            "#130202",
            "#1A1616",
            "#000000",
            "#040A27",
            "#022FB7",
            "#262A36",
            "#A802B7",
            "#3CB702",
            "#B76F02",
            "#B70284",
            "BLOODLINE",
            "COLLECTIVE",
            "REFLECTION",
            "COMPLETION",
            "OMNIPOTENT",
            "DREAMWORLD",
            "REDEMPTION",
            "RESOLUTION",
            "ABSOLUTION",
            "LIBERATION",
            "|",
            "-",
            "=",
            "+",
            "\\",
            ":",
            "~"
        ];

        RandParts memory randParts;

        randParts.border = randomStrings[
            uint256(keccak256(abi.encodePacked("BORDER", tokenId))) % 11
        ];
        randParts.corruptor = randomStrings[
            uint256(keccak256(abi.encodePacked("CORRUPTOR", tokenId))) % 11
        ];
        randParts.phrase = randomStrings[
            23 + (uint256(keccak256(abi.encodePacked("PHRASE", tokenId))) % 10)
        ];
        randParts.checker = randomStrings[
            33 + (uint256(keccak256(abi.encodePacked("CHECKER", tokenId))) % 7)
        ];

        string[32] memory canvas;

        if (bytes(oCanvas[0]).length > 32) {
            canvas = _blank(canvas);

            randParts.omitInsight = true;
            randParts.reduction = 64 + uint8(bytes(oCanvas[0])[tokenId % 32]);
            randParts.alternate = true;

            for (uint256 i = 0; i < 32; i++) {
                canvas = _richText(
                    canvas,
                    oCanvas[i],
                    bytes(oCanvas[i]).length,
                    0,
                    i
                );
            }
        } else if (bytes(oCanvas[0]).length > 0) {
            canvas = _blank(canvas);

            randParts.omitInsight = true;
            randParts.reduction = 64;

            for (uint256 i = 0; i < 32; i++) {
                canvas = _text(
                    canvas,
                    oCanvas[i],
                    bytes(oCanvas[i]).length,
                    0,
                    i
                );
            }
        } else {
            canvas = _blank(canvas);

            canvas = _box(canvas, randParts.border, 0, 0, 31, 1, true);
            canvas = _box(canvas, randParts.border, 0, 30, 31, 1, true);
            canvas = _box(canvas, randParts.border, 0, 0, 1, 31, true);
            canvas = _box(canvas, randParts.border, 30, 0, 1, 31, true);

            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[0])),
                15,
                15,
                12,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[1])),
                15,
                15,
                11,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[2])),
                15,
                15,
                10,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[3])),
                15,
                15,
                9,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[4])),
                15,
                15,
                8,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[5])),
                15,
                15,
                7,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[6])),
                15,
                15,
                6,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[7])),
                15,
                15,
                5,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[8])),
                15,
                15,
                4,
                true
            );
            canvas = _circle(
                canvas,
                string(abi.encodePacked(bytes(randParts.phrase)[9])),
                15,
                15,
                3,
                true
            );
        }

        uint256 iterations = uint256(
            keccak256(abi.encodePacked("CORRUPTION", tokenId))
        ) % 1024;
        if (randParts.reduction > 0) {
            iterations = iterations % randParts.reduction;
        }
        for (uint256 i = 0; i < iterations; i++) {
            if (randParts.alternate && i % 2 == 0) {
                canvas = _box(
                    canvas,
                    randParts.border,
                    uint256(keccak256(abi.encodePacked("X", i, tokenId))) % 30,
                    uint256(keccak256(abi.encodePacked("Y", i, tokenId))) % 30,
                    1,
                    1,
                    true
                );
            } else {
                canvas = _box(
                    canvas,
                    randParts.corruptor,
                    uint256(keccak256(abi.encodePacked("X", i, tokenId))) % 30,
                    uint256(keccak256(abi.encodePacked("Y", i, tokenId))) % 30,
                    1,
                    1,
                    true
                );
            }
        }

        if (!randParts.omitInsight) {
            uint256 length = 8 + bytes(toString(amount)).length;
            canvas = _text(
                canvas,
                string(abi.encodePacked("INSIGHT ", toString(amount))),
                length,
                31 - length,
                30
            );

            for (uint256 i = 10; i > 0; i--) {
                if (amount >= i * 2) {
                    canvas = _middleBox(
                        canvas,
                        string(
                            abi.encodePacked(bytes(randParts.phrase)[i - 1])
                        ),
                        randParts.checker,
                        i,
                        true
                    );
                }
            }
        }

        string memory output;
        for (uint8 i = 0; i < 31; i++) {
            output = string(
                abi.encodePacked(
                    output,
                    '<text x="10" y="',
                    lookup[i],
                    '" class="base">',
                    canvas[i],
                    "</text>"
                )
            );
        }

        string[12] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 820 1460" class="reflection"><style>@font-face { font-family: CorruptionsFont; src: url("';
        parts[1] = font.font();
        parts[2] = '") format("opentype"); } .base { fill: ';
        parts[3] = randomStrings[
            11 + (uint256(keccak256(abi.encodePacked("BGCOLOR", tokenId))) % 6)
        ];
        parts[
            4
        ] = '; font-family: CorruptionsFont; font-size: 10px; } .reflection g { -moz-transform: scale(-4, 4); -webkit-transform: scale(-4, 4); -o-transform: scale(-4, 4); -ms-transform: scale(-4, 4); transform: scale(-4, 4); }</style><g transform="scale(-4 4)" transform-origin="164 0"><rect width="205" height="365" fill="';
        parts[5] = amount >= 2
            ? randomStrings[
                17 +
                    (uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) %
                        6)
            ]
            : randomStrings[
                27 +
                    (uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) %
                        6)
            ];
        parts[6] = '" />';
        parts[7] = output;
        parts[8] = "";
        parts[9] = "";
        parts[10] = "";
        parts[11] = "</g></svg>";

        if (amount >= 2) {
            parts[8] = "<!-- ";
            parts[9] = randomStrings[
                27 +
                    (uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) %
                        6)
            ];
            parts[10] = " -->";
        }

        output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[7],
                parts[8],
                parts[9],
                parts[10],
                parts[11]
            )
        );
        return Base64.encode(bytes(output));
    }

    function tokenURI(uint256 tokenId, uint256 amount)
        external
        view
        override
        returns (string memory)
    {
        InsightMap memory insightMap = corruptions.insightMap(tokenId);
        if (insightMap.lastSaveBlock <= 13604851 && tokenId != 3193) {
            amount += 1; // fix early transfer bug
        }
        string memory json;
        string[32] memory emptyCanvas;
        DeviationInfo memory info = deviationRegistry.valueFor(
            dataMapper.valueFor(0, tokenId)
        );
        json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "0x',
                        toHexString(tokenId),
                        '", "description": "',
                        description,
                        '", "image": "data:image/svg+xml;base64,',
                        draw(tokenId, amount, emptyCanvas),
                        '", "attributes": [{"trait_type": "Deviation", "value": "',
                        info.name,
                        '"}, {"trait_type": "Insight", "value": "',
                        toString(amount),
                        '"}]}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 i) internal pure returns (string memory) {
        // https://stackoverflow.com/a/69302348/424107

        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint256 mask = 15;
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (i != 0) {
            uint256 curr = (i & mask);
            bstr[--k] = curr > 9
                ? bytes1(uint8(55 + curr))
                : bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }
}
