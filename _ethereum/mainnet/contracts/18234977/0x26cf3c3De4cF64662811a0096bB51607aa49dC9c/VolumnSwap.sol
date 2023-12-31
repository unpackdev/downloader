// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IVolumnSwap.sol";
import "./IV3SwapRouter.sol";
import "./IWETH9.sol";

contract VolumnSwap is IVolumnSwap, Pausable, Ownable {
    uint256 public immutable MAX_PERCENTAGE = 10000;

    constructor() {}

    receive() external payable {}

    fallback() external payable {}

    function createVolETHV2(
        CreateVolV2Params calldata params
    ) external payable override(IVolumnSwap) whenNotPaused {
        require(msg.value == params.amountIn, "VolumnSwap::not enough amount");

        // Avoid mev bot in first transaction
        IWETH9(params.path[0]).deposit{ value: address(this).balance }();

        _createVolETHV2(params);
    }

    function createVolETHV2NoSlippage(
        CreateVolV2NoSlippageParams calldata params
    ) external payable override(IVolumnSwap) whenNotPaused {
        require(msg.value == params.amountIn, "VolumnSwap::not enough amount");

        // Avoid mev bot in first transaction
        IWETH9(params.path[0]).deposit{ value: address(this).balance }();

        _createVolETHV2NoSlippage(params);
    }

    function buyVolETHV2(BuyVolV2Params calldata params) external payable {
        require(
            msg.value == params.amountIn * params.to.length,
            "VolumnSwap::not enough eth"
        );
        IUniswapV2Router02 router = IUniswapV2Router02(params.router);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: params.amountIn
        }(
            (params.minFirstAmountOut * (MAX_PERCENTAGE - params.slippage)) /
                MAX_PERCENTAGE,
            params.path,
            params.to[0],
            block.timestamp + 1 minutes
        );

        for (uint256 i = 1; i < params.to.length; i++) {
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: params.amountIn
            }(0, params.path, params.to[i], block.timestamp + 1 minutes);
        }
    }

    function createVolETHV3(
        CreateVolV3Params calldata params
    ) external payable override(IVolumnSwap) whenNotPaused {
        require(msg.value == params.amountIn, "VolumnSwap::not enough amount");
        require(
            params.path.length == params.fee.length + 1,
            "VolumnSwap::not enough length"
        );
        require(
            params.path.length <= type(uint32).max,
            "VolumnSwap::overflow path length"
        );

        IWETH9(params.path[0]).deposit{ value: address(this).balance }();

        _createVolETHV3(params);
    }

    function withdraw(address _weth) external onlyOwner {
        IWETH9 weth = IWETH9(_weth);
        weth.withdraw(weth.balanceOf(address(this)));
        _withdraw(_msgSender(), address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _createVolETHV2(CreateVolV2Params calldata params) private {
        IUniswapV2Router02 router = IUniswapV2Router02(params.router);
        IERC20 token = IERC20(params.path[params.path.length - 1]);
        IWETH9 weth = IWETH9(params.path[0]);
        weth.approve(params.router, type(uint256).max);
        token.approve(params.router, type(uint256).max);

        for (uint32 i = 0; i < params.loopTimes; i++) {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                weth.balanceOf(address(this)),
                0,
                params.path,
                address(this),
                block.timestamp + 1 minutes
            );

            if (i == 0) {
                uint256 minAmountOut = (params.minFirstAmountOut *
                    (MAX_PERCENTAGE - params.slippage)) / (MAX_PERCENTAGE);
                require(
                    token.balanceOf(address(this)) >= minAmountOut,
                    "VolumnSwap::mev bot comming..."
                );
            }

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                token.balanceOf(address(this)),
                0,
                reversePath(params.path),
                address(this),
                block.timestamp + 1 minutes
            );
        }
    }

    function _createVolETHV2NoSlippage(
        CreateVolV2NoSlippageParams calldata params
    ) private {
        IUniswapV2Router02 router = IUniswapV2Router02(params.router);
        IERC20 token = IERC20(params.path[params.path.length - 1]);
        IWETH9 weth = IWETH9(params.path[0]);
        weth.approve(params.router, type(uint256).max);
        token.approve(params.router, type(uint256).max);

        for (uint32 i = 0; i < params.loopTimes; i++) {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                weth.balanceOf(address(this)),
                0,
                params.path,
                address(this),
                block.timestamp + 1 minutes
            );

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                token.balanceOf(address(this)),
                0,
                reversePath(params.path),
                address(this),
                block.timestamp + 1 minutes
            );
        }
    }

    // 0xc35DADB65012eC5796536bD9864eD8773aBc74C4
    function _createVolETHV3(CreateVolV3Params calldata params) private {
        IV3SwapRouter router = IV3SwapRouter(params.swapRouter);
        IERC20 token = IERC20(params.path[params.path.length - 1]);
        IWETH9 weth = IWETH9(params.path[0]);
        weth.approve(params.swapRouter, type(uint256).max);
        token.approve(params.swapRouter, type(uint256).max);

        bytes memory _path = "";

        for (uint8 i = 0; i < params.fee.length; i++) {
            _path = bytes.concat(
                _path,
                bytes20(params.path[i]),
                bytes3(params.fee[i]),
                bytes20(params.path[i + 1])
            );
        }

        bytes memory _reversePath = "";

        for (uint8 i = uint8(params.fee.length); i >= 1; i--) {
            _reversePath = bytes.concat(
                _reversePath,
                bytes20(params.path[i]),
                bytes3(params.fee[i - 1]),
                bytes20(params.path[i - 1])
            );
        }

        for (uint32 i = 0; i < params.loopTimes; i++) {
            router.exactInput(
                IV3SwapRouter.ExactInputParams({
                    path: _path,
                    recipient: address(this),
                    amountIn: weth.balanceOf(address(this)),
                    amountOutMinimum: 0
                })
            );

            if (i == 0) {
                uint256 minAmountOut = (params.minFirstAmountOut *
                    (MAX_PERCENTAGE - params.slippage)) / (MAX_PERCENTAGE);
                require(
                    token.balanceOf(address(this)) >= minAmountOut,
                    "VolumnSwap::mev bot comming..."
                );
            }

            router.exactInput(
                IV3SwapRouter.ExactInputParams({
                    path: _reversePath,
                    recipient: address(this),
                    amountIn: token.balanceOf(address(this)),
                    amountOutMinimum: 0
                })
            );
        }
    }

    function _withdraw(address _to, uint256 _amount) internal {
        (bool success, ) = payable(_to).call{ value: _amount }("");
        require(success, "VolumnSwap::withdraw failed");
    }

    function reversePath(
        address[] calldata _array
    ) internal pure returns (address[] memory) {
        uint256 length = _array.length;
        address[] memory reversedArray = new address[](length);
        uint256 j = 0;
        for (uint256 i = length; i >= 1; i--) {
            reversedArray[j] = _array[i - 1];
            j++;
        }
        return reversedArray;
    }
}
