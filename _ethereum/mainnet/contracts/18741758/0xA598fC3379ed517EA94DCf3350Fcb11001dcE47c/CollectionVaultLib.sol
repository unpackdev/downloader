// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library CollectionVaultLib {
    function collectionAddress() internal view returns (address) {
        bytes memory footer = new bytes(0x20);

        assembly {
            // copy 0x20 bytes from end of footer
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x6d)
        }

        return abi.decode(footer, (address));
    }

    function salt() internal view returns (uint256) {
        bytes memory footer = new bytes(0x20);

        assembly {
            // copy 0x20 bytes from beginning of footer
            extcodecopy(address(), add(footer, 0x20), 0x2d, 0x4d)
        }

        return abi.decode(footer, (uint256));
    }
}
