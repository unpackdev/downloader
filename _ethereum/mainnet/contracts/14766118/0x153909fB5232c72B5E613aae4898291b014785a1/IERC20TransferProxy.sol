// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "./IERC20Upgradeable.sol";

/**
 * @dev interface for transfering ERC20 tokens,
 * contracts that implement this interface must support erc20safeTransferFrom method
 */
interface IERC20TransferProxy {
    function erc20safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) external;
}
