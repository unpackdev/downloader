// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.22;

import "./Strings.sol";
import "./Base64.sol";
import "./DynamicBuffer.sol";

contract StarSky {
    using Strings for uint8;
    using Strings for uint16;
    using Strings for uint256;

    string constant html1 =
        "<!DOCTYPE html><html lang='en'> <head> <meta charset='UTF-8'> <meta name='viewport' content='width=device-width, initial-scale=1.0, viewport-fit=cover'> <title>Advent Stars</title> <style> * { margin: 0; padding: 0; border: 0; } body { overflow: hidden; } </style></head><body>";
    string constant html2 = "</body></html>";

    bytes constant svg1 =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' width='100%' height='100%'> <defs><style> @keyframes ifl { 0% { opacity: 1 } 40% { opacity: 0.3; }  100% { opacity: 0.8; } } #star { animation: ifl 20s infinite alternate-reverse; } #sky {transform-origin: center;} .year {font: 20px Times;fill: rgb(153,153,153);} .t {fill: transparent; } .sg { stroke: rgb(153,153,153) } .p { font: 25px Times; } .w { fill: white; }</style> <clipPath id='frame'><circle cx='300' cy='300' r='420' /></clipPath><filter id='blur' filterUnits='userSpaceOnUse' x='-50%' y='-50%' width='200%' height='200%'> <feGaussianBlur in='SourceGraphic' stdDeviation='5' result='blur5' /> <feGaussianBlur in='SourceGraphic' stdDeviation='10' result='blur10' /> <feGaussianBlur in='SourceGraphic' stdDeviation='20' result='blur30' /> <feMerge result='merged'> <feMergeNode in='blur10' /> <feMergeNode in='blur30' /> </feMerge> <feMerge > <feMergeNode in='blur5' /> <feMergeNode in='merged' /> </feMerge> </filter> ";
    bytes constant svg2 =
        " </defs> <rect x='0' y='0' width='600' height='600' class='sg' fill='black' />  <g id='sky' transform='rotate(";
    bytes constant svg3 = ") scale(0.7)' clip-path='url(#frame)'>";
    bytes constant svg4 =
        "</g> <circle cx='300' cy='300' r='294' class='t sg' />";
    bytes constant svg5 =
        "<line class='sg' x1='0' x2='40' y1='0' y2='40' /> <line class='sg' x1='600' x2='560' y1='0' y2='40' /> <line class='sg' x1='0' x2='40' y1='600' y2='560' /> <line class='sg' x1='600' x2='560' y1='600' y2='560' /></svg>";

    bytes constant text1 =
        "<circle cx='49' cy='51' r='13' class='t sg' /><text class='year' x='44' y='57'>";
    bytes constant text2 =
        "<circle cx='551' cy='51' r='13' class='t sg' /><text class='year' x='546' y='57'>";
    bytes constant text3 =
        "<circle cx='49' cy='549' r='13' class='t sg' /><text class='year' x='44' y='556'>";
    bytes constant text4 =
        "<circle cx='551' cy='549' r='13' class='t sg' /><text class='year' x='546' y='556'>";
    bytes constant textClose = "</text>";
    bytes constant frame =
        "<rect x='0' y='0' width='600' height='600' class='t sg' />";

    bytes constant placeholder0 =
        "<circle cx='300' cy='300' r='50' filter='url(#pb)' id='star' fill='hsl(";
    bytes constant placeholder1 =
        ",100%,60%)' /><circle cx='300' cy='300' r='30' filter='url(#pbc)' id='star' fill='rgba(255,255,255,0.5)' /><text text-anchor='middle' x='50%' y='47%' width='600' heigh='50' class='p w'>The first Star will appear on the</text> <text text-anchor='middle' x='50%' y='53%' width='600' heigh='50' class='p w'>first of December</text>";
    bytes constant placeholderBlur =
        "<filter id='pb' filterUnits='userSpaceOnUse' x='-50%' y='-50%' width='200%' height='200%'> <feGaussianBlur in='SourceGraphic' stdDeviation='50' result='b1' /> <feGaussianBlur in='SourceGraphic' stdDeviation='70' result='b2' /> <feGaussianBlur in='SourceGraphic' stdDeviation='120' result='b3' /> <feMerge result='m'> <feMergeNode in='b1' /> <feMergeNode in='b2' /> </feMerge> <feMerge> <feMergeNode in='b3' /> <feMergeNode in='m' /> </feMerge> </filter><filter id='pbc' filterUnits='userSpaceOnUse' x='-50%' y='-50%' width='200%' height='200%'> <feGaussianBlur in='SourceGraphic' stdDeviation='10' result='b1' /> <feGaussianBlur in='SourceGraphic' stdDeviation='30' result='b2' /> <feGaussianBlur in='SourceGraphic' stdDeviation='40' result='b3' /> <feMerge result='m'> <feMergeNode in='b1' /> <feMergeNode in='b2' /> </feMerge> <feMerge> <feMergeNode in='b3' /> <feMergeNode in='m' /> </feMerge> </filter>";

    bytes constant star0 = "<circle cx='";
    bytes constant star1 = "' cy='";
    bytes constant star2 = "' r='";
    bytes constant star3 = "' id='star' style='animation-duration:";
    bytes constant star4 = "s;' fill='rgba(";
    bytes constant starComma = ",";
    bytes constant star5 = ")' filter='url(#blur)' />";

    bytes constant starCore0 = "<circle cx='";
    bytes constant starCore1 = "' cy='";
    bytes constant starCore2 = "' r='";
    bytes constant starCore3 = "' class='w' />";

    bytes constant dustFilter0 = "<filter id='d";
    bytes constant dustFilter1 =
        "' filterUnits='userSpaceOnUse' x='-50%' y='-50%' width='200%' height='200%'> <feGaussianBlur in='SourceGraphic' stdDeviation='";
    bytes constant dustFilter2 =
        "' result='b1' /> <feGaussianBlur in='SourceGraphic' stdDeviation='";
    bytes constant dustFilter3 =
        "' result='b2' /> <feGaussianBlur in='SourceGraphic' stdDeviation='";
    bytes constant dustFilter4 =
        "' result='b3' /> <feMerge result='b'> <feMergeNode in='b1' /> <feMergeNode in='b2' /> <feMergeNode in='b3' /> </feMerge> <feColorMatrix result='cb' in='b' type='matrix' values=' ";
    bytes constant dustFilter5 = " 0 0 0 0 0 ";
    bytes constant dustFilter6 = " 0 0 0 0 0 ";
    bytes constant dustFilter7 = " 0 0 0 0 0 ";
    bytes constant dustFilter8 = " 0' /> </filter>";

    bytes constant dust0 = "<path d='M ";
    bytes constant dust1 = "' filter='url(#d";
    bytes constant dust2 = ")' stroke='white' stroke-width='";
    bytes constant dust3 = "px' />";

    uint256 constant STAR_TRAITS = 8;
    uint256 constant STAR_TRAIT_SIZE = 256 / STAR_TRAITS;
    uint256 constant STAR_TRAIT_MASK = 2 ** STAR_TRAIT_SIZE - 1;

    uint256 constant CONSTELLATION_TRAITS = 10;
    uint256 constant CONSTELLATION_TRAIT_SIZE = 256 / CONSTELLATION_TRAITS;
    uint256 constant CONSTELLATION_TRAIT_MASK =
        2 ** CONSTELLATION_TRAIT_SIZE - 1;

    struct Star {
        uint8 r;
        uint8 g;
        uint8 b;
        uint8 a;
        uint16 xRand;
        uint16 yRand;
        uint16 radius;
        uint16 duration;
        uint256 seed;
    }

    struct Constellation {
        bool incRand;
        uint8 keepProb;
        uint16 rotation;
        uint16 maxDust;
        uint16 startX;
        uint16 startY;
        uint16 minX;
        uint16 minY;
        uint16 maxX;
        uint16 maxY;
    }

    constructor() {}

    function _renderName(
        uint256 randomness
    ) internal pure returns (bytes memory) {
        uint256 lettersCount = (_starTrait(randomness, 0) % 4) + 1;
        uint256 numbersCount = (_starTrait(randomness, 1) % 5) + 1;
        bytes memory letters;
        for (uint8 i = 2; i < lettersCount + 2; i++) {
            letters = abi.encodePacked(
                letters,
                uint8((randomness >> i) % 25) + 65
            );
        }
        bytes memory numbers;
        for (uint8 i = 7; i < 7 + numbersCount; i++) {
            numbers = abi.encodePacked(
                numbers,
                uint8((randomness >> i) % 10) + 48
            );
        }

        return abi.encodePacked(letters, " ", numbers);
    }

    function _renderFloat(bytes memory buffer, uint16 number) internal pure {
        bytes memory numberStr = bytes(number.toString());
        if (numberStr.length == 4) {
            DynamicBuffer.appendUnchecked(
                buffer,
                abi.encodePacked(
                    numberStr[0],
                    numberStr[1],
                    ".",
                    numberStr[2],
                    numberStr[3]
                )
            );
        } else if (numberStr.length == 3) {
            DynamicBuffer.appendUnchecked(
                buffer,
                abi.encodePacked(numberStr[0], ".", numberStr[1], numberStr[2])
            );
        } else if (numberStr.length == 2) {
            DynamicBuffer.appendUnchecked(
                buffer,
                abi.encodePacked("0.", numberStr[0], numberStr[1])
            );
        } else {
            DynamicBuffer.appendUnchecked(
                buffer,
                abi.encodePacked("0.0", numberStr[0])
            );
        }
    }

    function _render(
        uint256 seed,
        uint256 day,
        uint256 year
    ) internal pure returns (string memory) {
        Constellation memory constellation = _constellation(seed);
        return string(_renderSVG(seed, day, year, constellation));
    }

    function _json(
        uint256 tokenId,
        uint256 seed,
        uint256 day,
        uint256 year
    ) internal pure returns (string memory) {
        Constellation memory constellation = _constellation(seed);
        bytes memory attributes = abi.encodePacked(
            '","attributes":',
            '[{"trait_type":"Cluster Density","value":"',
            (6 - constellation.keepProb).toString(),
            '"},{"trait_type":"Incremental","value":"',
            (constellation.incRand ? "True" : "False"),
            '"},{"trait_type":"Rotation","value":"',
            constellation.rotation.toString(),
            '"},{"trait_type":"Max Dust","value":"',
            constellation.maxDust.toString(),
            '"}]}'
        );

        bytes memory image = _renderSVG(seed, day, year, constellation);
        string memory imageAnimated = Base64.encode(image);
        image[188] = "c";
        string memory imageStatic = Base64.encode(image);

        bytes memory name = _renderName(seed);
        bytes memory description;
        if (day == 0) {
            description = abi.encodePacked(
                "The Star Cluster **",
                name,
                "** will start forming on 1st Dec. ",
                year.toString()
            );
        } else {
            description = abi.encodePacked(
                "View of the Star Cluster **",
                name,
                "** on ",
                day.toString(),
                "/12/",
                year.toString()
            );
        }
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"#',
                            tokenId.toString(),
                            " - ",
                            name,
                            '", "description":"',
                            description,
                            '","image":"data:image/svg+xml;base64,',
                            imageStatic,
                            '","animation_url":"data:image/svg+xml;base64,',
                            imageAnimated,
                            attributes
                        )
                    )
                )
            );
    }

    function _renderSVG(
        uint256 seed,
        uint256 day,
        uint256 year,
        Constellation memory constellation
    ) internal pure returns (bytes memory) {
        bytes memory starsRender = DynamicBuffer.allocate(100000);
        bytes memory filters = DynamicBuffer.allocate(100000);
        bytes memory dusts;
        bytes memory dustsFilters;

        if (day > 0) {
            uint16[2][25] memory points;
            Star[] memory stars = new Star[](25);
            uint8 i = 0;
            for (; i < day; i++) {
                uint256 seedRound = uint256(
                    keccak256(abi.encodePacked(seed, i + 1))
                );
                Star memory star = _decode(seedRound);
                stars[i] = star;

                uint16 newX;
                uint16 newY;

                if (constellation.incRand) {
                    newX = star.xRand;
                    newY = star.yRand;
                } else {
                    constellation.startX =
                        ((constellation.startX +
                            (star.xRand % constellation.maxX) +
                            constellation.minX) % 581) +
                        10;
                    constellation.startY =
                        ((constellation.startY +
                            (star.yRand % constellation.maxY) +
                            constellation.minY) % 581) +
                        10;
                    newX = constellation.startX;
                    newY = constellation.startY;
                }
                points[i] = [newX, newY];

                DynamicBuffer.appendUnchecked(starsRender, star0);
                DynamicBuffer.appendUnchecked(
                    starsRender,
                    bytes(newX.toString())
                );
                DynamicBuffer.appendUnchecked(starsRender, star1);
                DynamicBuffer.appendUnchecked(
                    starsRender,
                    bytes(newY.toString())
                );
                DynamicBuffer.appendUnchecked(starsRender, star2);
                _renderFloat(starsRender, star.radius + 300);
                DynamicBuffer.appendUnchecked(starsRender, star3);
                _renderFloat(starsRender, star.duration);
                DynamicBuffer.appendUnchecked(starsRender, star4);
                DynamicBuffer.appendUnchecked(
                    starsRender,
                    bytes(
                        (100 + (((uint256(star.r) * 1000) / 256) * 156) / 1000)
                            .toString()
                    )
                );
                DynamicBuffer.appendUnchecked(starsRender, starComma);
                DynamicBuffer.appendUnchecked(
                    starsRender,
                    bytes(
                        (100 + (((uint256(star.g) * 1000) / 256) * 156) / 1000)
                            .toString()
                    )
                );
                DynamicBuffer.appendUnchecked(starsRender, starComma);
                DynamicBuffer.appendUnchecked(
                    starsRender,
                    bytes(
                        (100 + (((uint256(star.b) * 1000) / 256) * 156) / 1000)
                            .toString()
                    )
                );
                DynamicBuffer.appendUnchecked(starsRender, starComma);
                _renderFloat(starsRender, star.a);
                DynamicBuffer.appendUnchecked(starsRender, star5);

                DynamicBuffer.appendUnchecked(starsRender, starCore0);
                DynamicBuffer.appendUnchecked(
                    starsRender,
                    bytes(newX.toString())
                );
                DynamicBuffer.appendUnchecked(starsRender, starCore1);
                DynamicBuffer.appendUnchecked(
                    starsRender,
                    bytes(newY.toString())
                );
                DynamicBuffer.appendUnchecked(starsRender, starCore2);
                _renderFloat(starsRender, star.radius);
                DynamicBuffer.appendUnchecked(starsRender, starCore3);
            }

            (dusts, dustsFilters) = _renderDust(
                points,
                i,
                stars,
                constellation
            );
        }

        bytes memory svg = DynamicBuffer.allocate(1000000);
        DynamicBuffer.appendUnchecked(svg, svg1);
        if (day == 0) {
            DynamicBuffer.appendUnchecked(svg, placeholderBlur);
        }
        DynamicBuffer.appendUnchecked(svg, filters);
        DynamicBuffer.appendUnchecked(svg, dustsFilters);
        DynamicBuffer.appendUnchecked(svg, svg2);
        DynamicBuffer.appendUnchecked(
            svg,
            bytes(constellation.rotation.toString())
        );
        DynamicBuffer.appendUnchecked(svg, svg3);
        DynamicBuffer.appendUnchecked(svg, dusts);
        DynamicBuffer.appendUnchecked(svg, starsRender);
        DynamicBuffer.appendUnchecked(svg, svg4);
        DynamicBuffer.appendUnchecked(svg, _renderYear(year, day));
        if (day == 0) {
            uint16 h = uint16(seed % 360);
            DynamicBuffer.appendUnchecked(svg, placeholder0);
            DynamicBuffer.appendUnchecked(svg, bytes(h.toString()));
            DynamicBuffer.appendUnchecked(svg, placeholder1);
        }
        DynamicBuffer.appendUnchecked(svg, svg5);

        return svg;
    }

    function _renderYear(
        uint256 year,
        uint256 day
    ) internal pure returns (bytes memory) {
        bytes memory yearBytes = bytes(year.toString());
        bytes memory dayBytes = bytes(day.toString());
        bytes memory text = DynamicBuffer.allocate(320);

        DynamicBuffer.appendUnchecked(text, text1);
        if (dayBytes.length == 2) {
            DynamicBuffer.appendUnchecked(text, abi.encodePacked(dayBytes[0]));
            DynamicBuffer.appendUnchecked(text, textClose);
            DynamicBuffer.appendUnchecked(text, text2);
            DynamicBuffer.appendUnchecked(text, abi.encodePacked(dayBytes[1]));
        } else {
            DynamicBuffer.appendUnchecked(text, bytes("0"));
            DynamicBuffer.appendUnchecked(text, textClose);
            DynamicBuffer.appendUnchecked(text, text2);
            DynamicBuffer.appendUnchecked(text, abi.encodePacked(dayBytes[0]));
        }
        DynamicBuffer.appendUnchecked(text, textClose);
        DynamicBuffer.appendUnchecked(text, text3);
        DynamicBuffer.appendUnchecked(text, abi.encodePacked(yearBytes[2]));
        DynamicBuffer.appendUnchecked(text, textClose);
        DynamicBuffer.appendUnchecked(text, text4);
        DynamicBuffer.appendUnchecked(text, abi.encodePacked(yearBytes[3]));
        DynamicBuffer.appendUnchecked(text, textClose);
        DynamicBuffer.appendUnchecked(text, frame);

        return text;
    }

    function _renderDust(
        uint16[2][25] memory points,
        uint8 length,
        Star[] memory stars,
        Constellation memory constellation
    ) internal pure returns (bytes memory, bytes memory) {
        bytes memory dusts = DynamicBuffer.allocate(100000);
        bytes memory dustsFilters = DynamicBuffer.allocate(100000);
        points = _sortPointsByDistance(points, length, [uint16(0), 0]);
        for (uint16 i = 0; i < length; i++) {
            uint16[2][25] memory subarray = createSubArray(points, length, i);
            uint16[2][25] memory sortedPoints = _sortPointsByDistance(
                subarray,
                length - i,
                points[i]
            );

            _buildDust(
                dusts,
                dustsFilters,
                sortedPoints,
                length - i,
                i,
                stars[i],
                constellation
            );
        }

        return (dusts, dustsFilters);
    }

    function _buildDust(
        bytes memory dusts,
        bytes memory dustsFilters,
        uint16[2][25] memory points,
        uint16 length,
        uint16 i,
        Star memory star,
        Constellation memory constellation
    ) internal pure {
        if (i % constellation.keepProb != 0) {
            return;
        }

        bytes memory pathPoints = DynamicBuffer.allocate(3200);
        _constructPath(pathPoints, points[0][0], points[0][1]);

        for (uint16 j = 1; j < length; j++) {
            uint16 diffX = absDiff(points[j][0], points[j - 1][0]);
            uint16 diffY = absDiff(points[j][1], points[j - 1][1]);

            if (diffX <= 200 && diffY <= 200) {
                _constructPath(pathPoints, points[j][0], points[j][1]);
            } else if (j > 3) {
                _constructDust(dusts, pathPoints, i, j, constellation);
                _constructDustsFilters(dustsFilters, i, star);
                break;
            } else {
                break;
            }
        }
    }

    function _constellationTrait(
        uint256 randomness,
        uint8 index
    ) internal pure returns (uint256) {
        return ((randomness >> (CONSTELLATION_TRAIT_SIZE * index)) &
            CONSTELLATION_TRAIT_MASK);
    }

    function _constellation(
        uint256 randomness
    ) internal pure returns (Constellation memory constellation) {
        constellation.rotation = uint16(
            _constellationTrait(randomness, 0) % 360
        );
        constellation.incRand = _constellationTrait(randomness, 1) % 2 == 0;
        constellation.maxDust = uint16(
            (_constellationTrait(randomness, 2) % 401) + 100
        );
        constellation.startX = uint16(
            (_constellationTrait(randomness, 3) % 581) + 10
        );
        constellation.startY = uint16(
            (_constellationTrait(randomness, 4) % 581) + 10
        );
        constellation.keepProb = uint8(
            (_constellationTrait(randomness, 5) % 6) + 1
        );
        constellation.minX = uint16(
            (_constellationTrait(randomness, 6) % 91) + 10
        );
        constellation.minY = uint16(
            (_constellationTrait(randomness, 7) % 91) + 10
        );
        constellation.maxX =
            uint16(
                (_constellationTrait(randomness, 8) %
                    (251 - constellation.minX))
            ) +
            1;
        constellation.maxY =
            uint16(
                (_constellationTrait(randomness, 9) %
                    (251 - constellation.minY))
            ) +
            1;
    }

    function absDiff(uint16 a, uint16 b) private pure returns (uint16) {
        if (a > b) {
            return a - b;
        } else {
            return b - a;
        }
    }

    function createSubArray(
        uint16[2][25] memory array,
        uint16 length,
        uint16 startIndex
    ) private pure returns (uint16[2][25] memory subArray) {
        uint16 newArrayLength = length - startIndex;
        for (uint16 i = 0; i < newArrayLength; i++) {
            subArray[i][0] = array[startIndex + i][0];
            subArray[i][1] = array[startIndex + i][1];
        }
    }

    function _constructPath(
        bytes memory buffer,
        uint16 x,
        uint16 y
    ) internal pure {
        DynamicBuffer.appendUnchecked(buffer, bytes(" "));
        DynamicBuffer.appendUnchecked(buffer, bytes(x.toString()));
        DynamicBuffer.appendUnchecked(buffer, bytes(","));
        DynamicBuffer.appendUnchecked(buffer, bytes(y.toString()));
    }

    function _constructDust(
        bytes memory buffer,
        bytes memory path,
        uint16 index,
        uint16 pathLength,
        Constellation memory constellation
    ) internal pure {
        uint16 thickness = constellation.maxDust / pathLength;

        DynamicBuffer.appendUnchecked(buffer, dust0);
        DynamicBuffer.appendUnchecked(buffer, path);
        DynamicBuffer.appendUnchecked(buffer, dust1);
        DynamicBuffer.appendUnchecked(buffer, bytes(index.toString()));
        DynamicBuffer.appendUnchecked(buffer, dust2);
        DynamicBuffer.appendUnchecked(buffer, bytes(thickness.toString()));
        DynamicBuffer.appendUnchecked(buffer, dust3);
    }

    function _constructDustsFilters(
        bytes memory buffer,
        uint16 index,
        Star memory star
    ) internal pure {
        uint16 baseDust = uint16((star.seed % 80) + 40);
        DynamicBuffer.appendUnchecked(buffer, dustFilter0);
        DynamicBuffer.appendUnchecked(buffer, bytes(index.toString()));
        DynamicBuffer.appendUnchecked(buffer, dustFilter1);
        DynamicBuffer.appendUnchecked(buffer, bytes(baseDust.toString()));
        DynamicBuffer.appendUnchecked(buffer, dustFilter2);
        DynamicBuffer.appendUnchecked(
            buffer,
            bytes((baseDust + 50).toString())
        );
        DynamicBuffer.appendUnchecked(buffer, dustFilter3);
        DynamicBuffer.appendUnchecked(
            buffer,
            bytes((baseDust + 100).toString())
        );
        DynamicBuffer.appendUnchecked(buffer, dustFilter4);
        _renderFloat(buffer, (uint16(star.r) * 100) / 256);
        DynamicBuffer.appendUnchecked(buffer, dustFilter5);
        _renderFloat(buffer, (uint16(star.g) * 100) / 256);
        DynamicBuffer.appendUnchecked(buffer, dustFilter6);
        _renderFloat(buffer, (uint16(star.b) * 100) / 256);
        DynamicBuffer.appendUnchecked(buffer, dustFilter7);
        _renderFloat(buffer, star.a);
        DynamicBuffer.appendUnchecked(buffer, dustFilter8);
    }

    function _sortPointsByDistance(
        uint16[2][25] memory points,
        uint16 length,
        uint16[2] memory origin
    ) internal pure returns (uint16[2][25] memory) {
        _quickSort(points, origin, 0, length - 1);
        return points;
    }

    function _quickSort(
        uint16[2][25] memory arr,
        uint16[2] memory origin,
        uint16 left,
        uint16 right
    ) internal pure {
        int16 i = int16(left);
        int16 j = int16(right);
        if (i == j) return;
        int256 pivot = _distanceSquared(
            arr[uint16(left + (right - left) / 2)],
            origin
        );
        while (i <= j) {
            while (_distanceSquared(arr[uint16(i)], origin) < pivot) i++;
            while (pivot < _distanceSquared(arr[uint16(j)], origin)) j--;
            if (i <= j) {
                (arr[uint16(i)], arr[uint16(j)]) = (
                    arr[uint16(j)],
                    arr[uint16(i)]
                );
                i++;
                j--;
            }
        }
        if (int16(left) < j) _quickSort(arr, origin, left, uint16(j));
        if (i < int16(right)) _quickSort(arr, origin, uint16(i), right);
    }

    function _distanceSquared(
        uint16[2] memory p,
        uint16[2] memory origin
    ) internal pure returns (int256) {
        return
            (int256(int16(p[0])) - int256(int16(origin[0]))) ** 2 +
            (int256(int16(p[1])) - int256(int16(origin[1]))) ** 2;
    }

    function _starTrait(
        uint256 randomness,
        uint8 index
    ) internal pure returns (uint256) {
        return ((randomness >> (STAR_TRAIT_SIZE * index)) & STAR_TRAIT_MASK);
    }

    function _decode(
        uint256 randomness
    ) internal pure returns (Star memory star) {
        star.r = uint8(_starTrait(randomness, 0) % 256);
        star.g = uint8(_starTrait(randomness, 1) % 256);
        star.b = uint8(_starTrait(randomness, 2) % 256);
        star.a = uint8((_starTrait(randomness, 3) % 101) + 1);
        star.xRand = uint16((_starTrait(randomness, 4) % 581) + 10);
        star.yRand = uint16((_starTrait(randomness, 5) % 581) + 10);
        star.radius = uint16((_starTrait(randomness, 6) % 500) + 100);
        star.duration = uint16((_starTrait(randomness, 7) % 1001) + 100);
        star.seed = randomness;
    }
}
