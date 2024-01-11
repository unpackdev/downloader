// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IACL.sol";

contract InterfacePrinter {
    function acl() external pure returns (bytes4) {
        // solhint-disable-previous-line comprehensive-interface
        return bytes4(type(IACL).interfaceId);
    }
}
