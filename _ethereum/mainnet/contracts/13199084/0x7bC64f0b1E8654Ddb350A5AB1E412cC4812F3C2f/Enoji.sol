//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./NPass.sol";

import "./IEnojiDictionary.sol";
import "./IEnojiSVG.sol";
import "./IEnoji.sol";

/**
 * @title Enoji contract
 * @author @ulydev, @KnavETH
 * @notice This contract allows n-project holders to mint an Enoji
 *  1   2   3   4   5   6   7   8
 * [emo1 ] [emo2 ] [col1 ] [col2 ]
 */
contract Enoji is NPass, IEnoji {
    using Strings for uint256;

    IEnojiDictionary public dictionary;

    IEnojiSVG[] public svgVersions;
    mapping(uint256 => uint256) private svgVersionByToken;

    constructor(
        address _n,
        uint256 _priceInWei,
        address _dictionary,
        address _svg
    ) NPass("Enoji", "ENOJI", _n, _priceInWei) {
        dictionary = IEnojiDictionary(_dictionary);
        svgVersions.push(IEnojiSVG(_svg));
    }

    uint256 private constant N_BASE = 15;

    function getEmojis(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory, string memory)
    {
        uint256 i0 =
            (n.getFirst(_tokenId) + n.getSecond(_tokenId) * N_BASE) %
                dictionary.emojisCount();
        uint256 i1 =
            (n.getThird(_tokenId) + n.getFourth(_tokenId) * N_BASE) %
                dictionary.emojisCount();
        return (dictionary.emoji(i0), dictionary.emoji(i1));
    }

    function getColors(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory, string memory)
    {
        bool hasSecondColor =
            (n.getFirst(_tokenId) +
                n.getSecond(_tokenId) +
                n.getThird(_tokenId) +
                n.getFourth(_tokenId) +
                n.getFifth(_tokenId) +
                n.getSixth(_tokenId) +
                n.getSeventh(_tokenId) +
                n.getEight(_tokenId)) %
                4 ==
                0; // 1 in 4
        uint256 i0 =
            (n.getFifth(_tokenId) + n.getSixth(_tokenId) * N_BASE) %
                dictionary.colorsCount();
        uint256 i1 =
            !hasSecondColor
                ? i0
                : (((n.getFifth(_tokenId) + n.getSixth(_tokenId) * N_BASE) %
                    (dictionary.colorsCount() - 1)) + i0) %
                    dictionary.colorsCount();
        return (dictionary.color(i0), dictionary.color(i1));
    }

    function tokenSVG(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            svgVersions[svgVersionByToken[_tokenId]].tokenSVG(this, _tokenId);
    }

    function upgrade(uint256 _tokenId) external {
        require(n.ownerOf(_tokenId) == msg.sender, "Enoji:INVALID_OWNER");
        require(
            svgVersionByToken[_tokenId] < svgVersions.length - 1,
            "Enoji:NO_UPGRADE"
        );
        svgVersionByToken[_tokenId] = svgVersions.length - 1;
    }

    function addSVG(address _svg) external onlyOwner {
        svgVersions.push(IEnojiSVG(_svg));
    }

    function setDictionary(address _dictionary) external onlyOwner {
        dictionary = IEnojiDictionary(_dictionary);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        if (_from == address(0)) {
            svgVersionByToken[_tokenId] = svgVersions.length - 1; // set latest version on mint
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory json =
            string(
                abi.encodePacked(
                    '{"name": "Enoji #',
                    toString(_tokenId),
                    '", "description": "Enojis are generated and stored on-chain using N tokens.", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(tokenSVG(_tokenId)))
                )
            );

        (string memory emoji0, string memory emoji1) = getEmojis(_tokenId);
        (string memory color0, string memory color1) = getColors(_tokenId);

        json = string(
            abi.encodePacked(
                json,
                '", "attributes": [{"trait_type": "Emoji 1", "value": "',
                emoji0,
                '"}, {"trait_type": "Emoji 2", "value": "',
                emoji1,
                '"}, {"trait_type": "Color 1", "value": "',
                color0,
                '"}, {"trait_type": "Color 2", "value": "',
                color1,
                '"}, {"trait_type": "Version", "value": "',
                toString(svgVersionByToken[_tokenId]),
                '"}]}'
            )
        );

        string memory output =
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );

        return output;
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

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
