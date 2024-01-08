// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Base64.sol";

error MaxMintsReached();
error PriceNotMet();

contract Waves is ERC721, ERC721Enumerable, Ownable {
    constructor() ERC721("Waves", "WAVES") {}

    uint256 public constant MAX_MINTS = 1000;
    uint256 public constant price = 0.01 ether;
    string public constant DESCRIPTION =
        "A soothing, colorful & wavy NFT randomly generated on-chain!";

    // Only half is shown, but rest is used for animation
    uint256 constant WIDTH = 800;
    uint256 constant HEIGHT = 400;

    struct Color {
        int256 hue;
        int256 saturation;
        int256 lightness;
    }

    struct DrawInput {
        uint256 waveCount;
        uint256 pulseWidth;
        uint256 amplitude;
        uint256 slope;
        uint256 offset;
        Color startColor;
        Color endColor;
    }

    struct Point {
        int256 x;
        int256 y;
    }

    function _mint(address destination) private {
        if (totalSupply() >= MAX_MINTS) {
            revert MaxMintsReached();
        }

        uint256 tokenId = totalSupply();
        _safeMint(destination, tokenId);
    }

    function mintForSelf() external payable {
        if (msg.value < price) {
            revert PriceNotMet();
        }
        _mint(msg.sender);
    }

    function mintForFriend(address walletAddress) external payable {
        if (msg.value < price) {
            revert PriceNotMet();
        }
        _mint(walletAddress);
    }

    function withdrawAll() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }

    function random(
        uint256 tokenId,
        string memory key,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked("mainnet", tokenId, key))) % (max - min)) +
            min;
    }

    function randomColor(
        uint256 tokenId,
        uint256 hMin,
        uint256 hMax,
        uint256 sMin,
        uint256 sMax,
        uint256 lMin,
        uint256 lMax
    ) internal pure returns (Color memory) {
        return
            Color(
                int256(random(tokenId, "hue", hMin, hMax)),
                int256(random(tokenId, "saturation", sMin, sMax)),
                int256(random(tokenId, "lightness", lMin, lMax))
            );
    }

    function maximum(int256 a, int256 b) internal pure returns (int256) {
        if (a > b) {
            return a;
        }
        return b;
    }

    function minimum(int256 a, int256 b) internal pure returns (int256) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function gradient(
        Color memory start,
        Color memory end,
        uint256 _current,
        uint256 _max
    ) internal pure returns (Color memory) {
        int256 current = int256(_current);
        int256 max = int256(_max);

        int256 h = start.hue + ((current * (end.hue - start.hue)) / max);
        int256 s = start.saturation +
            ((current * (end.saturation - start.saturation)) / max);
        int256 l = start.lightness +
            ((current * (end.lightness - start.lightness)) / max);

        return Color(h, s, l);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(totalSupply() >= tokenId, "MUST_BE_MINTED");
        uint256 waveCount = random(tokenId, "waveCount", 5, 9);
        uint256 pulseWidth = random(tokenId, "pulseWidth", 50, 90);
        uint256 amplitude = random(tokenId, "amplitude", 20, 40);
        uint256 slope = random(tokenId, "slope", 2, 4);
        uint256 offset = random(tokenId, "offset", 0, 30);
        Color memory startColor = randomColor(tokenId, 0, 359, 40, 100, 30, 40);
        Color memory endColor = randomColor(
            tokenId,
            uint256(
                maximum(
                    0,
                    startColor.hue - int256(random(tokenId, "endHueMin", 5, 15))
                )
            ),
            uint256(
                minimum(
                    359,
                    startColor.hue + int256(random(tokenId, "endHueMax", 5, 15))
                )
            ),
            70,
            90,
            60,
            75
        );

        DrawInput memory input = DrawInput(
            waveCount,
            pulseWidth,
            amplitude,
            slope,
            offset,
            startColor,
            endColor
        );

        bytes memory svg = draw(input);

        string memory colorAttributes = string(
            abi.encodePacked(
                '{"trait_type":"startHue", "value": ',
                toStringSigned(startColor.hue),
                '},{"trait_type":"startSaturation", "value": ',
                toStringSigned(startColor.saturation),
                '},{"trait_type":"startLightness", "value": ',
                toStringSigned(startColor.lightness),
                '},{"trait_type":"endHue", "value": ',
                toStringSigned(endColor.hue),
                '},{"trait_type":"endSaturation", "value": ',
                toStringSigned(endColor.saturation),
                '},{"trait_type":"endLightness", "value": ',
                toStringSigned(endColor.lightness),
                "}"
            )
        );

        string memory attributes = string(
            abi.encodePacked(
                '[{"trait_type":"waveCount", "value": ',
                toString(input.waveCount),
                '},{"trait_type":"pulseWidth", "value": ',
                toString(input.pulseWidth),
                '},{"trait_type":"amplitude", "value": ',
                toString(input.amplitude),
                '},{"trait_type":"slope", "value": ',
                toString(input.slope),
                '},{"trait_type":"offset", "value": ',
                toString(input.offset),
                "},",
                colorAttributes,
                "]"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"Waves #',
                        toString(tokenId + 1),
                        '","attributes":',
                        attributes,
                        ',"description":"',
                        DESCRIPTION,
                        '","image": "data:image/svg+xml;base64,',
                        Base64.encode(svg),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function draw(DrawInput memory input) internal pure returns (bytes memory) {
        string memory output = string(
            abi.encodePacked(
                '<svg width="',
                toString(WIDTH / 2),
                '" height="',
                toString(HEIGHT),
                '" viewBox="0 0 ',
                toString(WIDTH / 2),
                " ",
                toString(HEIGHT),
                '" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg">'
            )
        );

        string memory background = string(
            abi.encodePacked(
                '<rect width="100%" height="100%" fill="',
                toStringColor(input.startColor),
                '" />'
            )
        );

        output = string(abi.encodePacked(output, background));

        for (uint256 i = 0; i < input.waveCount; i++) {
            int256 overflow = int256(input.offset) * int256(input.waveCount);
            Color memory color = gradient(
                input.startColor,
                input.endColor,
                i + 1,
                input.waveCount
            );
            Point[] memory points = calculateWavePoints(input, overflow, i);
            output = string(
                abi.encodePacked(
                    output,
                    drawWave(points, overflow, input.slope, color)
                )
            );
        }

        output = string(abi.encodePacked(output, "</svg>"));

        return bytes(abi.encodePacked(output));
    }

    function calculateWavePoints(
        DrawInput memory input,
        int256 overflow,
        uint256 waveNumber
    ) internal pure returns (Point[] memory) {
        uint256 startY = (HEIGHT / input.waveCount) * waveNumber;
        bool direction = false;

        int256 x = -overflow + int256(input.offset) * int256(waveNumber);
        uint256 pointsLength = (WIDTH + uint256(abs(x))) / input.pulseWidth;
        Point[] memory points = new Point[](pointsLength + 1);
        points[0] = Point(x, int256(startY));
        for (uint256 i = 1; i < pointsLength; i++) {
            x = x + int256(input.pulseWidth);
            int256 y = int256(input.amplitude) *
                (direction == true ? int8(1) : -1) +
                int256(startY);
            direction = !direction;
            points[i] = Point(x, y);
        }

        points[pointsLength] = Point(int256(WIDTH) + overflow, int256(startY));

        return points;
    }

    function drawWaveInternal(
        Point[] memory points,
        int256 overflow,
        uint256 slope
    ) internal pure returns (bytes memory) {
        string memory output = string(
            abi.encodePacked(
                "M ",
                toStringSigned(-overflow),
                " ",
                toStringSigned(int256(HEIGHT) + overflow)
            )
        );

        string memory first = string(
            abi.encodePacked(
                " L ",
                toStringSigned(points[0].x),
                " ",
                toStringSigned(points[0].y)
            )
        );

        output = string(abi.encodePacked(output, first));

        for (uint256 i = 1; i < points.length; i++) {
            // Destination point
            Point memory currentPoint = points[i];
            // Previous destination point
            Point memory prevPoint = points[i - 1];

            // By using the same y, diff effectively determines slope of wave via control points
            int256 diff = (currentPoint.x - prevPoint.x) / int256(slope);

            // Start of Bezier curve control point
            int256 x1 = prevPoint.x + diff;

            // End of Bezier curve control point
            int256 x2 = currentPoint.x - diff;

            string memory curve = string(
                abi.encodePacked(
                    "C ",
                    toStringSigned(x1),
                    " ",
                    toStringSigned(prevPoint.y),
                    ", ",
                    toStringSigned(x2),
                    " ",
                    toStringSigned(currentPoint.y),
                    ", ",
                    toStringSigned(currentPoint.x),
                    " ",
                    toStringSigned(currentPoint.y),
                    " "
                )
            );
            output = string(abi.encodePacked(output, curve));
        }

        string memory secondLast = string(
            abi.encodePacked(
                "L ",
                toStringSigned(points[points.length - 1].x),
                " ",
                toStringSigned(points[points.length - 1].y)
            )
        );

        string memory last = string(
            abi.encodePacked(
                "L ",
                toStringSigned(int256(WIDTH) + overflow),
                " ",
                toStringSigned(int256(HEIGHT) + overflow),
                " Z"
            )
        );

        output = string(abi.encodePacked(output, secondLast, last));

        return bytes(abi.encodePacked(output));
    }

    function drawWave(
        Point[] memory points,
        int256 overflow,
        uint256 slope,
        Color memory color
    ) internal pure returns (bytes memory) {
        string memory output = string(
            abi.encodePacked(
                '<path d="',
                drawWaveInternal(points, overflow, slope),
                '" fill="',
                toStringColor(color),
                '">'
            )
        );

        output = string(
            abi.encodePacked(
                output,
                '<animateMotion path="M0 0 H -200 0Z" dur="20s" repeatCount="indefinite" />'
            )
        );

        output = string(abi.encodePacked(output, "</path>"));
        return bytes(abi.encodePacked(output));
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

    function toStringSigned(int256 value)
        internal
        pure
        returns (string memory)
    {
        if (value < 0) {
            uint256 unsigned = uint256(value * -1);
            string memory output = toString(unsigned);
            return string(abi.encodePacked("-", output));
        }
        return toString(uint256(value));
    }

    function toStringColor(Color memory color)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "hsl(",
                    toStringSigned(color.hue),
                    ",",
                    toStringSigned(color.saturation),
                    "%,",
                    toStringSigned(color.lightness),
                    "%)"
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
