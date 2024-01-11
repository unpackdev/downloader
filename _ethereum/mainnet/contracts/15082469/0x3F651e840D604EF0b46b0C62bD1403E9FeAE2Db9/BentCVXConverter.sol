// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Errors.sol";
import "./IUniswapV2Router.sol";
import "./IBentCVX.sol";
import "./IBentCVXConverter.sol";

contract BentCVXConverter is Ownable, IBentCVXConverter {
    using Address for address;
    using SafeERC20 for IERC20;

    struct SwapPath {
        address router;
        address[] path;
    }
    address public cvx;
    address public bentCVX;
    mapping(address => SwapPath) public swapPaths; // token => swap path

    constructor(address _cvx, address _bentCVX) Ownable() {
        cvx = _cvx;
        bentCVX = _bentCVX;
    }

    function setSwapPath(
        address inToken,
        address router,
        address[] memory path
    ) external onlyOwner {
        require(path[path.length - 1] == cvx, Errors.INVALID_PATH);

        swapPaths[inToken] = SwapPath(router, path);
    }

    function quoteToBentCVX(address inToken, uint256 amount)
        external
        view
        returns (uint256 amountCVX)
    {
        SwapPath memory swapPath = swapPaths[inToken];

        require(swapPath.router != address(0), Errors.INVALID_PATH);

        uint256[] memory amountsOut = IUniswapV2Router(swapPath.router)
            .getAmountsOut(amount, swapPath.path);

        amountCVX = amountsOut[amountsOut.length - 1];
    }

    // via uniswap v2 interface
    function convertToBentCVX(
        address inToken,
        uint256 amount,
        uint256 amountOutMin
    ) external payable override {
        SwapPath memory swapPath = swapPaths[inToken];

        require(swapPath.router != address(0), Errors.INVALID_PATH);

        if (inToken == address(0)) {
            require(amount == msg.value, Errors.INVALID_AMOUNT);
            IUniswapV2Router(swapPath.router).swapExactETHForTokens{
                value: amount
            }(amountOutMin, swapPath.path, address(this), block.timestamp);
        } else {
            IERC20(inToken).safeTransferFrom(msg.sender, address(this), amount);
            if (inToken != cvx) {
                IERC20(inToken).safeApprove(swapPath.router, amount);
                IUniswapV2Router(swapPath.router).swapExactTokensForTokens(
                    amount,
                    amountOutMin,
                    swapPath.path,
                    address(this),
                    block.timestamp
                );
            }
        }

        _convertAndSend(msg.sender);
    }

    // via uniswap v2 interface
    function convertToBentCVXWithOwnPath(
        address inToken,
        uint256 amount,
        uint256 amountOutMin,
        SwapPath memory swapPath
    ) external payable {
        if (inToken == address(0)) {
            require(amount == msg.value, Errors.INVALID_AMOUNT);
            IUniswapV2Router(swapPath.router).swapExactETHForTokens{
                value: amount
            }(amountOutMin, swapPath.path, address(this), block.timestamp);
        } else {
            IERC20(inToken).safeTransferFrom(msg.sender, address(this), amount);
            if (inToken != cvx) {
                IERC20(inToken).safeApprove(swapPath.router, amount);
                IUniswapV2Router(swapPath.router).swapExactTokensForTokens(
                    amount,
                    amountOutMin,
                    swapPath.path,
                    address(this),
                    block.timestamp
                );
            }
        }

        _convertAndSend(msg.sender);
    }

    // via extra contract call
    function convertToBentCVXWithCall(
        address inToken,
        uint256 amount,
        uint256 amountOutMin,
        address to,
        bytes calldata data
    ) external payable {
        if (inToken == address(0)) {
            require(amount == msg.value, Errors.INVALID_AMOUNT);
            to.functionCallWithValue(data, amount);
        } else {
            IERC20(inToken).safeTransferFrom(msg.sender, address(this), amount);
            if (inToken != cvx) {
                IERC20(inToken).safeApprove(to, amount);
                to.functionCall(data);
            }
        }

        require(
            IERC20(cvx).balanceOf(address(this)) >= amountOutMin,
            Errors.EXCEED_EXPECTED_OUTPUT
        );
        _convertAndSend(msg.sender);
    }

    function _convertAndSend(address user) internal {
        uint256 amountCVX = IERC20(cvx).balanceOf(address(this));
        IERC20(cvx).approve(bentCVX, amountCVX);
        IBentCVX(bentCVX).deposit(amountCVX);
        IERC20(bentCVX).safeTransfer(user, amountCVX);
    }
}
