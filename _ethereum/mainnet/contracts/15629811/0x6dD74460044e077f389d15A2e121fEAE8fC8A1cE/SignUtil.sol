// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity 0.8.4;

import "./ECDSA.sol";

/**
 * Used to verify that the signature is correct
 */
library SignUtil {
    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue1 signed by one of user1, user2, user3
     * @param signedValue2 signed by one of user1, user2, user3
     * @param user1 user1
     * @param user2 user2
     * @param user3 user3
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue1,
        bytes memory signedValue2,
        address user1,
        address user2,
        address user3
    ) internal pure returns (bool) {
        // if sign1 equals sign2, return false
        if (_compareBytes(signedValue1, signedValue2)) {
            return false;
        }

        // address must be one of user1, user2, user3
        address address1 = ECDSA.recover(hashValue, signedValue1);
        if (address1 != user1 && address1 != user2 && address1 != user3) {
            return false;
        }
        address address2 = ECDSA.recover(hashValue, signedValue2);
        if (address2 != user1 && address2 != user2 && address2 != user3) {
            return false;
        }
        return true;
    }

    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue1 signed by one of user1, user2
     * @param signedValue2 signed by one of user1, user2
     * @param user1 user1
     * @param user2 user2
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue1,
        bytes memory signedValue2,
        address user1,
        address user2
    ) internal pure returns (bool) {
        // if sign1 equals sign2, return false
        if (_compareBytes(signedValue1, signedValue2)) {
            return false;
        }

        // address must be one of user1, user2
        address address1 = ECDSA.recover(hashValue, signedValue1);
        if (address1 != user1 && address1 != user2) {
            return false;
        }
        address address2 = ECDSA.recover(hashValue, signedValue2);
        if (address2 != user1 && address2 != user2) {
            return false;
        }
        return true;
    }

    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue signed by user
     * @param user User to be verified
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue,
        address user
    ) internal pure returns (bool) {
        address signedAddress = ECDSA.recover(hashValue, signedValue);
        if (signedAddress != user) {
            return false;
        }
        return true;
    }

    /**
     * compare bytes
     * @param a param1
     * @param b param2
     */
    function _compareBytes(bytes memory a, bytes memory b) private pure returns (bool) {
        bytes32 s;
        bytes32 d;
        assembly {
            s := mload(add(a, 32))
            d := mload(add(b, 32))
        }
        return (s == d);
    }
}
