// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Security {
    function checkSecretCode(string memory providedCode, string storage storedCode) internal pure returns (bool) {
        return keccak256(abi.encodePacked(providedCode)) == keccak256(abi.encodePacked(storedCode));
    }
}
