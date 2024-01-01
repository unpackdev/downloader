// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Consts.sol";

library Types {
    function toHex(address addr) internal pure returns (string memory) {
        bytes memory ret = new bytes(42);
        uint ptr;
        assembly {
            mstore(add(ret, 0x20), "0x")
            ptr := add(ret, 0x22)
        }
        for (uint160 i = 0; i < 20; i++) {
            uint160 n = (uint160(addr) & (uint160(0xff) << ((20 - 1 - i) * 8))) >> ((20 - 1 - i) * 8);
            uint first = (n / 16);
            uint second = n % 16;
            bytes1 symbol1 = hexByte(first);
            bytes1 symbol2 = hexByte(second);
            assembly {
                mstore(ptr, symbol1)
                ptr := add(ptr, 1)
                mstore(ptr, symbol2)
                ptr := add(ptr, 1)
            }
        }
        return string(ret);
    }

    function hexByte(uint i) internal pure returns (bytes1) {
        require(i < 16, "wrong hex");
        if (i < 10) {
            // number ascii start from 48
            return bytes1(uint8(48 + i));
        }
        // charactor ascii start from 97
        return bytes1(uint8(97 + i - 10));
    }

    function encodeAdapterParams(uint64 extraGas) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes2(0x0001), uint256(extraGas));
    }

    function encodeNftBridgeParams(
        uint256 srcChainId,
        bool isERC1155,
        address addr,
        uint256 tokenId,
        address from,
        address recipient,
        bytes memory extraData
    ) internal pure returns (bytes memory) {
        require(srcChainId < type(uint64).max, "too large chain id");
        bytes1 flag = isERC1155 ? Consts.FLAG_ERC1155 : Consts.FLAG_ERC721;
        return abi.encodePacked(flag, abi.encode(uint64(srcChainId), addr, tokenId, from, recipient, extraData));
    }

    function decodeNftBridgeParams(
        bytes calldata data
    )
        internal
        pure
        returns (
            uint64 srcChainId,
            bool isERC1155,
            address addr,
            uint256 tokenId,
            address from,
            address recipient,
            bytes memory extraData
        )
    {
        bytes1 flag = bytes1(data);
        require(uint8(flag) <= 1);
        isERC1155 = flag == Consts.FLAG_ERC1155;
        (srcChainId, addr, tokenId, from, recipient, extraData) = abi.decode(
            data[1:data.length],
            (uint64, address, uint256, address, address, bytes)
        );
    }
}
