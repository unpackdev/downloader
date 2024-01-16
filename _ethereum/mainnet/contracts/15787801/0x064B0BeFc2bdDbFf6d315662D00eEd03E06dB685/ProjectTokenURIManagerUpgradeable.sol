// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IProjectTokenURIManagerUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./IERC165Upgradeable.sol";

/**
 * @dev Implement this if you want your manager to have overloadable URI's
 */
abstract contract ProjectTokenURIManagerUpgradeable is IProjectTokenURIManagerUpgradeable, ERC165Upgradeable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IProjectTokenURIManagerUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
}
