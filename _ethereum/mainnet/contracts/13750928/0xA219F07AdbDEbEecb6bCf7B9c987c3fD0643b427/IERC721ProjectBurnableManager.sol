// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC165.sol";

/**
 * @dev Your manager is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the manager created is
 * burned
 */
interface IERC721ProjectBurnableManager is IERC165 {
    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256 tokenId) external;
}
