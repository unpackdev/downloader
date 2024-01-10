// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC165.sol";

/**
 * @dev Implement this if you want your manager to have overloadable URI's
 */
interface IProjectTokenURIManager is IERC165 {
    /**
     * Get the uri for a given project/tokenId
     */
    function tokenURI(address project, uint256 tokenId) external view returns (string memory);
}
