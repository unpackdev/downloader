// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IProjectTokenURIManager.sol";
import "./ERC165.sol";

/**
 * @dev Implement this if you want your manager to have overloadable URI's
 */
abstract contract ProjectTokenURIManager is IProjectTokenURIManager, ERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IProjectTokenURIManager).interfaceId || super.supportsInterface(interfaceId);
    }
}
