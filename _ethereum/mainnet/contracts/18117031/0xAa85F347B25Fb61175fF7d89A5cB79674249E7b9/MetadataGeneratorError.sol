// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Base64.sol";
import "./Strings.sol";

library MetadataGeneratorError {
    string internal constant SVG_PREFIX = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 768 768\">"
        "<style>.t{font:bold 13px monospace}</style>"
        "<rect width=\"768\" height=\"768\" style=\"fill:#e5e5e5;stroke:#000;stroke-width:1.5px;\"/>"
        "<text class=\"t\" x=\"1\" y=\"300\">Unable to make LP NFT Image. Funds are unaffected by this error.</text>";
    string internal constant SVG_POSTFIX = "</svg>";

    ///@notice A human readable description of the item.
    string internal constant DESCRIPTION =
        "Ditto is a gas-efficient, DeFi-optimized automated market maker (AMM) that enables efficient and seamless trading between NFTs and ERC-20 tokens. "
        "Users can effortlessly create on-chain pools for trading NFTs, allowing for more composable NFT liquidity provision. "
        "Ditto streamlines the process of exchanging digital assets in the ever-growing NFT market and makes them more compatible with the growing vertical at the intersection of DeFi and NFTs.";

    function uint8ToHexChar(uint8 raw) internal pure returns (uint8) {
        return (raw > 9)
            ? (raw + (0x61 - 0xa)) // ascii lowercase a
            : (raw + 0x30); // ascii 0
    }

    function bytesToHexString(bytes memory buffer) internal pure returns (string memory) {
        bytes memory hexBuffer = new bytes(buffer.length * 2);
        for (uint256 i = 0; i < buffer.length; i++) {
            uint8 raw = uint8(buffer[i]);
            uint8 highNibble = raw >> 4;
            uint8 lowNibble = raw & 0x0f;
            hexBuffer[i * 2] = bytes1(uint8ToHexChar(highNibble));
            hexBuffer[i * 2 + 1] = bytes1(uint8ToHexChar(lowNibble));
        }
        return string(abi.encodePacked("0x", hexBuffer));
    }

    function generateLpIdString(uint256 lpId_) internal pure returns (string memory) {
        return string.concat("<text class=\"t\" x=\"1\" y=\"350\">LpId: ", Strings.toString(lpId_), "</text>");
    }

    function generatePoolString(address pool_) internal pure returns (string memory) {
        return
            string.concat("<text class=\"t\" x=\"1\" y=\"375\">Pool: ", Strings.toHexString(uint160(pool_)), "</text>");
    }

    function generateTokenCount(uint256 tokenCount_) internal pure returns (string memory) {
        return
            string.concat("<text class=\"t\" x=\"1\" y=\"400\">Token Count: ", Strings.toString(tokenCount_), "</text>");
    }

    function generateNftCount(uint256 nftCount_) internal pure returns (string memory) {
        return string.concat("<text class=\"t\" x=\"1\" y=\"425\">NFT Count: ", Strings.toString(nftCount_), "</text>");
    }

    function generateErrorComment(bytes memory reasonCode_) internal pure returns (string memory) {
        return string.concat("<!-- Error Reason Code: ", bytesToHexString(reasonCode_), "-->");
    }

    function _generateImage(
        uint256 lpId_,
        address pool_,
        uint256 tokenCount_,
        uint256 nftCount_,
        bytes memory reasonCode_
    ) internal pure returns (string memory) {
        return string.concat(
            SVG_PREFIX,
            generateLpIdString(lpId_),
            generatePoolString(pool_),
            generateTokenCount(tokenCount_),
            generateNftCount(nftCount_),
            generateErrorComment(reasonCode_),
            SVG_POSTFIX
        );
    }

    function errorTokenUri(
        uint256 lpId_,
        address pool_,
        uint256 tokenCount_,
        uint256 nftCount_,
        bytes memory reasonCode_
    ) internal pure returns (string memory) {
        string memory image = Base64.encode(bytes(_generateImage(lpId_, pool_, tokenCount_, nftCount_, reasonCode_)));
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            string(abi.encodePacked("Ditto V1 LP Position #", Strings.toString(lpId_))),
                            '", "description":"',
                            DESCRIPTION,
                            '", "image": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }
}
