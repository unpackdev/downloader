// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Base64.sol";
import "./LibString.sol";
import "./LibPRNG.sol";

contract EthscriptionCreator {
    using LibString for *;
    using LibPRNG for LibPRNG.PRNG;

    uint256 public totalSupply;
    uint public constant esip3StartBlock = 18130000;
    uint public constant mintEndBlock = esip3StartBlock + (24 hours / 12);

    struct SvgArgs {
        uint256 circleRadius;
        uint256 rectWidth;
        uint256 rectHeight;
        uint256 nextId;
        string circleColor;
        string rectColor;
        string bgColor;
        string textColor;  
    }

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );

    function createEthscription() public {
        require(block.number >= esip3StartBlock, "Not yet started");
        require(block.number <= mintEndBlock, "It's over");

        uint256 nextId = ++totalSupply;

        LibPRNG.PRNG memory prng = LibPRNG.PRNG(
            uint160(msg.sender) + nextId
        );

        SvgArgs memory s = SvgArgs({
            circleRadius: prng.uniform(100),
            rectWidth: prng.uniform(100),
            rectHeight: prng.uniform(100),
            nextId: nextId,
            circleColor: generateRandomColor(prng),
            rectColor: generateRandomColor(prng),
            bgColor: generateRandomColor(prng),
            textColor: generateRandomColor(prng)
        });

        bytes memory svgContent = generateSVG(s, prng);

        string memory dataURI = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svgContent)
            )
        );

        emit ethscriptions_protocol_CreateEthscription(msg.sender, dataURI);
    }

    function generateSVG(SvgArgs memory s, LibPRNG.PRNG memory prng)
        internal
        pure
        returns (bytes memory)
    {
        uint circleX = prng.uniform(100);
        uint circleY = prng.uniform(100);

        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" height="1200" width="1200" viewbox="0 0 1200 1200">',
                // Linear gradient for circle
                "<defs>",
                '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%">',
                '<stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1" />',
                '<stop offset="100%" style="stop-color:',
                s.circleColor,
                ';stop-opacity:1" />',
                "</linearGradient>",
                '<linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%">',
                '<stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1" />',
                '<stop offset="100%" style="stop-color:',
                s.bgColor,
                ';stop-opacity:1" />',
                "</linearGradient>",
                "</defs>",
                '<rect width="100%" height="100%" fill="url(#grad)" />',
                // Circle with gradient
                '<circle cx="',
                LibString.toString(circleX),
                '%" cy="',
                LibString.toString(circleY),
                '%" r="',
                LibString.toString(s.circleRadius),
                '%" fill="url(#grad1)" stroke="black" stroke-width="2"/>',
                // Rectangle with solid color
                '<rect x="60" y="60" rx="15" ry="15" width="',
                LibString.toString(s.rectWidth),
                '%" height="',
                LibString.toString(s.rectHeight),
                '%" fill="',
                s.rectColor,
                '" stroke="black" stroke-width="2" />',
                '<text fill="', s.textColor,'" x="1170" y="1170" font-size="200%" text-anchor="end" font-family="helvetica neue, helvetica, arial, san-serif">',
                "ESIP-3 Welcome POAP #",
                s.nextId.toString(),
                "</text>"
                "</svg>"
            );
    }

    function generateRandomColor(LibPRNG.PRNG memory prng)
        internal
        pure
        returns (string memory)
    {
        uint256 red = prng.uniform(255);
        uint256 green = prng.uniform(255);
        uint256 blue = prng.uniform(255);
        return
            string(
                abi.encodePacked(
                    "rgb(",
                    LibString.toString(red),
                    ",",
                    LibString.toString(green),
                    ",",
                    LibString.toString(blue),
                    ")"
                )
            );
    }
}
