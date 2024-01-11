// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC1155ProjectBurnableManager.sol";
import "./ERC165.sol";

/**
 * @dev Your manager is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the manager created is
 * burned
 */
abstract contract ERC1155ProjectBurnableManager is IERC1155ProjectBurnableManager, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155ProjectBurnableManager).interfaceId || super.supportsInterface(interfaceId);
    }
}
