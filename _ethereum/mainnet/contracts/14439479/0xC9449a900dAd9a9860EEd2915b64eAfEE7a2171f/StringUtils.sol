// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library StringUtils {
    function isEmptyOrNull(string memory s) external pure returns (bool) {
        // TODO: what other processing does this need for empty check?
        if (bytes(s).length == 0) return true;
        return false;
    }

    function uint2str(uint256 _i) public pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    function getRandomColors()
        external
        view
        returns (string memory, string memory)
    {
        uint256 r = uint256(
            keccak256(abi.encodePacked(msg.sender, msg.value))
        ) % 255;
        uint256 g = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.difficulty)
            )
        ) % 255;
        uint256 b = uint256(
            keccak256(abi.encodePacked(block.gaslimit, block.coinbase))
        ) % 255;

        string memory tc;
        if (r * 299 + g * 587 + b * 114 > 186000) {
            tc = "#000000";
        } else {
            tc = "#FFFFFF";
        }

        return (
            tc,
            string(
                abi.encodePacked(
                    "rgb(",
                    uint2str(r),
                    ",",
                    uint2str(g),
                    ",",
                    uint2str(b),
                    ")"
                )
            )
        );
    }

    function isValidString(bytes memory b) external pure returns (bool) {
        // (char >= 0x20 && char <= 0x25) => sp!"#$%
        // (char >= 0x27 && char <= 0x3B) => '{}*+,-./0-9:;
        // (char == 0x3D) => =
        // (char >= 0x3F && char <= 0x7E) => ?@A-Z[\]^_`a-z{|}~
        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            // skip control chars (except space) and &<>
            if (
                char < 0x20 ||
                char == 0x26 ||
                char == 0x3C ||
                char == 0x3E ||
                char > 0x7E
            ) return false;
        }

        return true;
    }
}
