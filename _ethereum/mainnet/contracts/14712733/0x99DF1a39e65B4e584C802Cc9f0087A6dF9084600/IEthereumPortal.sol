// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IERC20.sol";

/// @title Main contract which serves as the entry point on Ethereum
interface IEthereumPortal {
    function initialize(address _polygonContract) external;

    function depositERC20(
        IERC20 tokenIn,
        uint256 amountIn,
        address routerAddress,
        bytes calldata routerArguments,
        bytes calldata calls
    ) external;

    function depositEther(
        address routerAddress,
        bytes calldata routerArguments,
        bytes calldata calls
    ) external payable;
}
