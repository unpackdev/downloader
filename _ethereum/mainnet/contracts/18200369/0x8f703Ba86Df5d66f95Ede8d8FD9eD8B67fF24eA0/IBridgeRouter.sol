// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IBridgeRouter {
    event Enter(
        address indexed token,
        address indexed exitor,
        address indexed originSender,
        address router,
        uint256 amount,
        uint256 amountMin,
        uint256 deadline,
        uint256 nonce,
        uint256 localChainId,
        uint256 targetChainId,
        bytes callData
    );

    event Exit(
        address indexed token,
        address indexed exitor,
        address indexed executor,
        uint256 amount,
        bytes32 commitment,
        uint256 localChainId,
        uint256 extChainId
    );

    // ===== packs =====

    struct ExitData {
        address extTokenAddr;
        address exitor;
        address originSender;
        address originRouter;
        address executor;
        uint256 amount;
        uint256 amountMin;
        uint256 deadline;
        uint256 localChainId;
        uint256 extChainId;
        bytes callData;
    }

    struct ProcessorParams {
        uint256 gasLimit;
        uint256 minFee;
        bool useRelay;
    }

    function weth9() external returns (IERC20);

    // enter amount of tokens to protocol
    function enter(
        address token,
        uint256 amount,
        uint256 amountMin,
        uint256 deadline,
        uint256 targetChainId,
        address to,
        bytes calldata data
    ) external;

    // enter amount of system currency to protocol
    function enterETH(
        uint256 amountMin,
        uint256 deadline,
        uint256 targetChainId,
        address to,
        bytes calldata data
    ) external payable;

    // exit amount of tokens from protocol
    function exit(
        bytes calldata data,
        bytes[] calldata signatures,
        ProcessorParams calldata params
    ) external;
}
