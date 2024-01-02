// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Strings.sol";
import "./Network.sol";

error CallFailed();

library Utils {
    function addressToHexString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }

    function hexStringToAddress(string memory addr) internal pure returns (address) {
        bytes memory tmp = bytes(addr);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function isBitSet(bytes32 data, uint256 position) internal pure returns (bool) {
        return (uint256(data) & (uint256(1) << position)) != 0;
    }

    function normalizeAmountToOriginalFormat(uint256 amount, uint256 decimals) internal pure returns (uint256) {
        uint256 difference = (10 ** (18 - decimals));
        return amount / difference;
    }

    function normalizeAmountToProtocolFormat(uint256 amount, uint256 decimals) internal pure returns (uint256) {
        uint256 difference = (10 ** (18 - decimals));
        return amount * difference;
    }

    function normalizeAmountToProtocolFormatOnCurrentNetwork(
        uint256 amount,
        uint256 decimals,
        bytes4 networkId
    ) internal view returns (uint256) {
        return Network.isCurrentNetwork(networkId) ? normalizeAmountToProtocolFormat(amount, decimals) : amount;
    }

    function sendEther(address to, uint256 amount) internal {
        (bool sent, ) = to.call{value: amount}("");
        if (!sent) {
            revert CallFailed();
        }
    }
}
