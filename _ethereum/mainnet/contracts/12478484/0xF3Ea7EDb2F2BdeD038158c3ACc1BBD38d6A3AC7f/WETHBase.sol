// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./IWETH.sol";

contract WETHBase {

    IWETH public immutable WETH;

    /**
     * @notice Constructor sets the immutable WETH address.
     */
    constructor(address weth) {
        WETH = IWETH(weth);
    }

    /**
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }    
}