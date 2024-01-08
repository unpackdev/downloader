// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./base64.sol";
import "./render.sol";


library Bitfield {
    function setBit(bytes32 self, uint8 bit) internal pure returns (bytes32) {
        return self | bytes32(1 << (255 - bit));
    }

    function getBit(bytes32 self, uint8 bit) internal pure returns (bool) {
        return uint256((self << bit) >> 255) == 1;
    }
}

contract Measurable {
    event Measurement(
        string name,
        uint256 gas
    );

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(1 != chainId);
    }

    modifier measured(string memory name) {
        uint256 before = gasleft();
        _;
        emit Measurement(name, before - gasleft());
    }
}

library TokenAttributes {
    /*
    +-------+----------+-------+-------+-------+
    | color | negative | left  | nose  | right |
    +-------+----------+-------+-------+-------+
    | uint7 | uint1    | uint8 | uint8 | uint8 |
    +-------+----------+-------+-------+-------+
    */

    function newFace(
        bool negative,
        uint8 color,
        uint8 leftEye,
        uint8 nose,
        uint8 rightEye
    ) internal pure returns (uint32) {
        uint32 face = (uint32(color) << 25)
            | (uint32(leftEye) << 16)
            | (uint32(nose) << 8)
            | uint32(rightEye);

        if (negative) {
            face |= 0x01000000;
        }

        return face;
    }

    function faceColor(uint32 self) internal pure returns (uint8) {
        return uint8(self >> 25);
    }

    function faceNegative(uint32 self) internal pure returns (bool) {
        return 0 != (self & 0x01000000);
    }

    function faceLeftEye(uint32 self) internal pure returns (uint8) {
        return uint8(self >> 16);
    }

    function faceRightEye(uint32 self) internal pure returns (uint8) {
        return uint8(self);
    }

    function faceNose(uint32 self) internal pure returns (uint8) {
        return uint8(self >> 8);
    }

    function faceBit(uint32 self) internal pure returns (uint8) {
        unchecked {
            return uint8(self >> 16) + (7 * uint8(self >> 8)) + (21 * uint8(self));
        }
    }
}

abstract contract Attributes {
    using TokenAttributes for uint32;
    using Bitfield for bytes32;

    uint8 constant internal COLORS = 7;
    uint8 constant internal EYES = 7;
    uint8 constant internal NOSES = 3;

    bytes32 internal unique;

    function takeFace(bytes32 input, uint32 face) private pure returns (bool success, bytes32 output) {
        uint8 bit = face.faceBit();

        if (input.getBit(bit)) {
            success = false;
            output = input;
        } else {
            success = true;
            output = input.setBit(bit);
        }
    }

    // (274 bytes)
    function pickEye(uint8 seed) private pure returns (uint8) {
        if (seed < 80) return 0;
        if (seed < 144) return 1;
        if (seed < 184) return 2;
        if (seed < 224) return 3;
        if (seed < 246) return 4;
        if (seed < 254) return 5;
        return 6;
    }

    // (98 bytes)
    function pickNose(uint8 seed) private pure returns (uint8) {
        if (seed < 156) return 0;
        if (seed < 244) return 1;
        return 2;
    }

    // (137 bytes)
    function pickColor(uint8 seed) private pure returns (uint8) {
        return seed % COLORS;
    }

    // (20 bytes)
    function pickNegative(uint8 seed) private pure returns (bool) {
        return seed >= 254;
    }

    function pickFace(bytes32 seed) private pure returns (uint32) {
        return TokenAttributes.newFace(
            pickNegative(uint8(seed[0])),
            pickColor(uint8(seed[1])),
            pickEye(uint8(seed[2])),
            pickNose(uint8(seed[3])),
            pickEye(uint8(seed[4]))
        );
    }

    function random(bytes32 uni) private view returns (bytes32) {
        // Oh look, random number generation on-chain. What could go wrong?

        unchecked {
            uint256 bitfield;


            for (uint ii = 1; ii < 257; ii++) {
                uint256 bits = uint256(blockhash(block.number - ii));
                bitfield |= bits & (1 << (ii - 1));
            }

            uint256 value = uint256(keccak256(abi.encodePacked(bytes32(bitfield))));
            value ^= uint256(keccak256(abi.encodePacked(uni)));

            return bytes32(value);
        }
    }

    function roll() internal returns (uint32) {
        bytes32 mem = unique;
        bytes32 seed = random(mem);

        bool success;
        uint32 face;

        while (true) {
            face = pickFace(seed);

            (success, mem) = takeFace(mem, face);

            if (success) {
                break;
            }

            seed = keccak256(abi.encodePacked(seed));
        }

        unique = mem;
        return face;
    }

    function steal(uint32 face) internal {
        bool success;
        (success, unique) = takeFace(unique, face);
        require(success, "nice try");
    }
}

contract FaceDotPng is Attributes, ERC721, Ownable {
    using TokenAttributes for uint32;

    bytes constant private COLOR_VALUES = hex"cc0000f15d2264cf00006fff2222ccad7fa834e2e2";

    Render immutable public RENDERER;

    uint256 public price = 130000000000000;

    constructor(Render renderer) ERC721("face.png", "PNG") {
        RENDERER = renderer;

        // My avatar.
        genesisSteal(msg.sender, 0xc020000);
    }

    // (357 bytes)
    function color(uint8 index, bool negative) private pure returns (bytes3) {
        index *= 3;
        uint24 result =
            (uint24(uint8(COLOR_VALUES[index])) << 16)
            | (uint24(uint8(COLOR_VALUES[index + 1])) << 8)
            | uint24(uint8(COLOR_VALUES[index + 2]));

        if (negative) {
            result = ~result;
        }

        return bytes3(result);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "PNG: nonexistent");

        uint32 face = uint32(tokenId);
        bool isNegative = face.faceNegative();

        bytes3 bg = bytes3(isNegative ? 0xFFFFFF : 0x000000);

        bytes memory png = RENDERER.png(
            bg,
            color(face.faceColor(), isNegative),
            face.faceLeftEye(),
            face.faceNose(),
            face.faceRightEye()
        );

        bytes memory svg = abi.encodePacked(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
            "<svg version=\"1.1\" viewBox=\"0 0 48 48\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">"
            "<image style=\"image-rendering:crisp-edges;image-rendering:pixelated\" xlink:href=\"data:image/png;base64,",
            Base64.encode(png),
            "\"/></svg>"
        );

        bytes memory name = abi.encodePacked(
            RENDERER.eyeName(face.faceLeftEye()),
            RENDERER.noseName(face.faceNose()),
            RENDERER.eyeName(face.faceRightEye()),
            ".png"
        );

        bytes memory json = abi.encodePacked(
            "{\"description\":\"\",\"name\":\"",
            name,
            "\",\"attributes\":[{\"trait_type\":\"Left Eye\",\"value\":\"",
            RENDERER.eyeName(face.faceLeftEye()),
            "\"},{\"trait_type\":\"Nose\",\"value\":\"",
            RENDERER.noseName(face.faceNose()),
            "\"},{\"trait_type\":\"Right Eye\",\"value\":\"",
            RENDERER.eyeName(face.faceRightEye()),
            "\"},{\"trait_type\":\"Base Color\",\"value\":\"",
            face.faceColor() + 48, // Convert to ASCII digit.
            "\"},{\"trait_type\":\"Negative\",\"value\":\"",
            face.faceNegative() ? "Yes" : "No",
            "\"}],\"image\":\"data:image/svg+xml;base64,",
            Base64.encode(svg),
            "\"}"
        );

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(json)
        ));
    }

    function genesisSteal(address to, uint32 face) private {
        steal(face);
        _mint(to, face);
    }

    function preMint() private returns (uint256) {
        require(msg.sender == tx.origin, "EOAs only"); // fuck 3074
        require(msg.value >= price, "not enough");
        price = (price * 1082) / 1000;
        return roll();
    }

    function mint(address to) external payable {
        _mint(to, preMint());
    }

    function safeMint(address to) external payable {
        _safeMint(to, preMint());
    }

    function withdraw(address payable to) external onlyOwner {
        (bool success,) = to.call{value:address(this).balance}("");
        require(success, "could not send");
    }
}