//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721.sol";

abstract contract Resolver {
    function addr(bytes32 node) public view virtual returns (address);
}

abstract contract ENS {
    function resolver(bytes32 node) public view virtual returns (Resolver);
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

contract Respek is ERC721 {
    mapping(uint256 => string) public respekFrom;
    mapping(uint256 => string) public respekTo;

    mapping(bytes32 => uint256) public colors;
    mapping(bytes32 => uint256) public available;
    mapping(bytes32 => uint256) public lastMint;

    uint256 public defaultMint = 6;
    uint256 public mintFreq = 7 days;

    uint256 public lastTokenId = 0;

    address EnsAddress = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    ENS EnsResolver = ENS(EnsAddress);

    event Respeks(
        string indexed _fromEns,
        string indexed _toEns,
        uint256 tokenId
    );

    constructor() ERC721("RESPEK", "RSPK") {}

    function contractURI() public pure returns (string memory) {
        return "https://meta.putrespek.xyz/";
    }

    function computeNamehash(string memory _name)
        public
        pure
        returns (bytes32 namehash)
    {
        namehash = 0x0;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked("eth")))
        );

        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }

    function resolve(string memory ensName) public view returns (address) {
        bytes32 node = computeNamehash(ensName);
        Resolver ensResolver = EnsResolver.resolver(node);
        return ensResolver.addr(node);
    }

    function setColor(
        string memory ensName,
        uint256 r,
        uint256 g,
        uint256 b
    ) public {
        address ensOwner = resolve(ensName);
        require(ensOwner == msg.sender, "Sender does not own the address");
        require(r < 256 && g < 256 && b < 256, "Invalid color");
        uint256 color = r * 256 * 256 + g * 256 + b;
        bytes32 lookupKey = keccak256(bytes(ensName));
        colors[lookupKey] = color;
    }

    function getColor(string memory ensName)
        public
        view
        returns (
            uint256 r,
            uint256 g,
            uint256 b
        )
    {
        bytes32 lookupKey = keccak256(bytes(ensName));
        uint256 colorCode = colors[lookupKey];
        b = colorCode % 256;
        g = (colorCode / 256) % 256;
        r = (colorCode / (256 * 256)) % 256;
    }

    function getColorString(
        uint256 r,
        uint256 g,
        uint256 b
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "rgb(",
                    Strings.toString(r),
                    ",",
                    Strings.toString(g),
                    ",",
                    Strings.toString(b),
                    ")"
                )
            );
    }

    function giveRespek(string memory ensFrom, string memory ensTo) public {
        require(
            keccak256(bytes(ensFrom)) != keccak256(bytes(ensTo)),
            "Sender != Receiver."
        );
        uint256 availableCount = availableRespek(ensFrom);
        require(availableCount > 0, "No Respeks available.");
        address ensFromAddress = resolve(ensFrom);
        require(ensFromAddress == msg.sender, "Invalid owner.");
        address ensToAddress = resolve(ensTo);
        require(ensToAddress != address(0), "ENS does not exist.");

        respekFrom[lastTokenId] = ensFrom;
        respekTo[lastTokenId] = ensTo;

        _safeMint(ensToAddress, lastTokenId);
        emit Respeks(ensFrom, ensTo, lastTokenId);

        lastTokenId += 1;

        bytes32 lookupKey = keccak256(bytes(ensFrom));
        available[lookupKey] = availableCount - 1;

        if (lastMint[lookupKey] > 0) {
            uint256 timeBased = (block.timestamp - lastMint[lookupKey]) /
                mintFreq;
            lastMint[lookupKey] = lastMint[lookupKey] + timeBased * mintFreq;
        } else {
            lastMint[lookupKey] = block.timestamp;
        }
    }

    function availableRespek(string memory ensName)
        public
        view
        returns (uint256)
    {
        bytes32 lookupKey = keccak256(bytes(ensName));

        uint256 lastTime = block.timestamp;
        if (lastMint[lookupKey] != 0) {
            lastTime = lastMint[lookupKey];
        }
        uint256 timeBased = (block.timestamp - lastTime) / mintFreq;

        if (lastMint[lookupKey] == 0) {
            return defaultMint + timeBased;
        }
        if (available[lookupKey] > 0) {
            return available[lookupKey] + timeBased;
        }

        return timeBased;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "No token");

        (uint256 rFrom, uint256 gFrom, uint256 bFrom) = getColor(
            respekFrom[tokenId]
        );
        if (rFrom == 0 && gFrom == 0 && bFrom == 0) {
            rFrom = 255;
        }

        (uint256 rTo, uint256 gTo, uint256 bTo) = getColor(respekTo[tokenId]);
        if (rTo == 0 && gTo == 0 && bTo == 0) {
            rTo = 255;
            gTo = 191;
            bTo = 80;
        }

        string memory fullEnsFrom = string(
            abi.encodePacked(respekFrom[tokenId], ".eth")
        );

        string memory fullEnsTo = string(
            abi.encodePacked(respekTo[tokenId], ".eth")
        );
        string
            memory f = '<feGaussianBlur stdDeviation="80" result="blur"></feGaussianBlur>';
        string memory fx4 = string(abi.encodePacked(f, f, f, f));
        string
            memory mid = ' x="50%" dominant-baseline="middle" text-anchor="middle">';

        string memory output = string(
            abi.encodePacked(
                '<svg width="800" height="800" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 800 800">',
                "<style>svg { background-color: white; } .shadow {filter: drop-shadow( 3px 3px 4px rgba(0, 0, 0, .3));} .name {fill: #111; font-size: 240%; font-family: monospace;}</style>",
                '<defs><filter id="bbblurry-filter" color-interpolation-filters="sRGB">',
                fx4,
                fx4,
                "</filter></defs>",
                '<g filter="url(#bbblurry-filter)">',
                '<ellipse rx="300" ry="300" cx="90%" cy="10%" fill="',
                getColorString(rFrom, gFrom, bFrom),
                '"></ellipse>',
                '<ellipse rx="300" ry="300" cx="10%" cy="90%" fill="',
                getColorString(rTo, gTo, bTo),
                '"></ellipse>',
                '</g><text class="shadow name" y="25%"',
                mid,
                fullEnsFrom,
                '</text><text class="shadow" font-size="800%" y="50%"',
                mid,
                unicode"🤝",
                '</text><text class="shadow name" y="75%"',
                mid,
                fullEnsTo,
                "</text></svg>"
            )
        );

        string memory attributes = string(
            abi.encodePacked(
                '"attributes": [{"trait_type": "from", "value": "',
                fullEnsFrom,
                '"}, {"trait_type": "to", "value": "',
                fullEnsTo,
                '"}]'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        fullEnsFrom,
                        " ",
                        unicode"🤝",
                        " ",
                        fullEnsTo,
                        '", "description": "Respek", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '",',
                        attributes,
                        "}"
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
}
