// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./base64.sol";
import "./Image.sol";
import "./HotChainSVG.sol";

contract MetadataV1 is Image, Metadata {
    function uri(uint256 tokenId, string memory name)
        external
        pure
        returns (string memory)
    {
        address collection = address(uint160(tokenId));
        uint96 value = uint96(tokenId >> 160);
        uint8 level = getLevel(value);

        string memory image = Base64.encode(
            bytes(render(name, collection, level))
        );
        string memory json = string.concat(
            '{"name":"',
            escape(name),
            ' is using Hot Chain SVG","attributes":[{"trait_type":"Level","value":',
            utils.uint2str(level + 1),
            '}],"image": "data:image/svg+xml;base64,',
            image,
            '"}'
        );
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            );
    }

    function escape(string memory name) internal pure returns (string memory) {
        bytes memory chars = bytes(name);
        for (uint256 i = 0; i < chars.length; i++) {
            if (uint8(chars[i]) == 34) {
                chars[i] = bytes1(uint8(39));
            }
        }
        return name;
    }

    function getLevel(uint96 value) internal pure returns (uint8) {
        if (value >= 2 ether) {
            return 4;
        }
        if (value >= 1 ether) {
            return 3;
        }
        if (value >= 0.1 ether) {
            return 2;
        }
        if (value >= 0.01 ether) {
            return 1;
        }
        return 0;
    }
}
