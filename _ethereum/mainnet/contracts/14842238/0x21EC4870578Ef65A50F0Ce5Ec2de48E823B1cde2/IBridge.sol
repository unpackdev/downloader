// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridge {
    function transferERC20(
        uint256 destinationNetworkId,
        address tokenIn,
        uint256 amount,
        address destinationAddress,
        bytes calldata data
    ) external;

    function transferNative(
        uint256 destinationNetworkId,
        uint256 amount,
        address destinationAddress,
        bytes calldata data
    ) external payable;
}
