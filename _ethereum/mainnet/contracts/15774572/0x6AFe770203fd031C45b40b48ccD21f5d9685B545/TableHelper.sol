// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OneHiTable.sol";

library TableHelper {
    function getBytecode(address implTableAddr) public pure returns (bytes memory) {
        bytes memory bytecode = type(OneHiTable).creationCode;
        return abi.encodePacked(bytecode, abi.encode(implTableAddr));
    }
}
