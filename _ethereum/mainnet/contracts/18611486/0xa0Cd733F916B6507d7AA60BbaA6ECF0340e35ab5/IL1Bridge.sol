// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL1Bridge {
    function transferETH(uint16 dstChainId_, uint256 amount_, address recipient_) external payable;

    function transferETHFromVault(uint16 dstChainId_, address recipient_) external payable;

    function transferERC20(uint16 dstChainId_, address l1Token_, uint256 amount_, address recipient_)
        external
        payable;

    function transferERC20FromVault(uint16 dstChainId_, address l1Token_, uint256 amount_, address recipient_)
        external;

    function fees(uint16 dstChainId_) external view returns (uint256);
}
