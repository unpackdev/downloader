// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC20.sol";

library InterfaceChecker {
    function isERC1155(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC1155).interfaceId);
    }
    function isERC721(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC721).interfaceId);
    }
    function isERC20(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC20).interfaceId);
    }
}
