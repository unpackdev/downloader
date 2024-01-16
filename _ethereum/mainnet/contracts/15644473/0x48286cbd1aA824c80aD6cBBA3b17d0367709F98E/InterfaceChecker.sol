// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./IERC165.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC20.sol";

library InterfaceChecker {
    function isERC1155(address check) internal view returns(bool) {
        try IERC165(check).supportsInterface(type(IERC1155).interfaceId) returns (bool is1155) {
           return is1155;
        } catch { 
            return false;
        }
    }
    function isERC721(address check) internal view returns(bool) {
        try IERC165(check).supportsInterface(type(IERC721).interfaceId) returns (bool is721) {
            return is721;
        } catch {
            return false;
        }
    }
    function isERC20(address check) internal view returns(bool) {
        if (isERC721(check)) { return false; }

        try IERC20(check).balanceOf(address(0)) returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }
}