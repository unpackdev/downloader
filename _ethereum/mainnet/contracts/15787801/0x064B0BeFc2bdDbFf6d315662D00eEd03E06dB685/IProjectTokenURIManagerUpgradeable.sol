// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC165Upgradeable.sol";

/**
 * @dev Implement this if you want your manager to have overloadable URI's
 */
interface IProjectTokenURIManagerUpgradeable is IERC165Upgradeable {
    /**
     * Get the uri for a given project/tokenId
     */
    function tokenURI(address project, uint256 tokenId) external view returns (string memory);
}
