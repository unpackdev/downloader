// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IACL.sol";
import "./IFragmentMiniGame.sol";

contract InterfacePrinter {
    function acl() external pure returns (bytes4) {
        // solhint-disable-previous-line comprehensive-interface
        return bytes4(type(IACL).interfaceId);
    }

    function fragmentMiniGame() external pure returns (bytes4) {
        // solhint-disable-previous-line comprehensive-interface
        return bytes4(type(IFragmentMiniGame).interfaceId);
    }
}
