// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./IERC20Upgradeable.sol";

interface IERC20TransferProxy {
    function erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) external;
}
