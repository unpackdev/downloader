// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Strings.sol";

library VerboseReverts {
    function _revertWithAddress(string memory message, address user) internal pure {
        revert(string(abi.encodePacked(message, ": ", Strings.toHexString(uint160(user), 20))));
    }

    function _revertWithUint(string memory message, uint256 value) internal pure {
        revert(string(abi.encodePacked(message, ": ", Strings.toHexString(value, 32))));
    }
}
