// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./ISwapRouter.sol";
import "./IExchangeAdapter.sol";

contract UniswapV3Exchange is OwnableUpgradeable, IExchangeAdapter {
    ISwapRouter public router;

    function __UniswapV3Exchange_init(address _router) external initializer {
        __Ownable_init();
        router = ISwapRouter(_router);
    }

    function swapExactInputSingle(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24 _poolFee
    ) external payable override returns (uint256) {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(_tokenIn),
            _msgSender(),
            address(this),
            _amountIn
        );
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_tokenIn), address(router), _amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: _poolFee,
                recipient: _recipient,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        return router.exactInputSingle(params);
    }

    function swapExactInput(
        address _tokenIn,
        address _via,
        address _tokenOut,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24 _poolFeeA,
        uint24 _poolFeeB
    ) external payable override returns (uint256) {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(_tokenIn),
            _msgSender(),
            address(this),
            _amountIn
        );
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_tokenIn), address(router), _amountIn);
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    _tokenIn,
                    _poolFeeA,
                    _via,
                    _poolFeeB,
                    _tokenOut
                ),
                recipient: _recipient,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum
            });
        return router.exactInput(params);
    }

    // @dev swap a minimum possible amount of one token
    // for a fixed amount of another token.
    function exactOutputSingle(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint24 _poolFee
    ) external payable override returns (uint256 _amountIn) {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(_tokenIn),
            _msgSender(),
            address(this),
            _amountInMaximum
        );
        SafeERC20Upgradeable.safeApprove(
            IERC20Upgradeable(_tokenIn),
            address(router),
            _amountInMaximum
        ); // max amount to spend

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: _poolFee,
                recipient: _recipient,
                deadline: block.timestamp,
                amountOut: _amountOut,
                amountInMaximum: _amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        _amountIn = router.exactOutputSingle(params);
        if (_amountIn < _amountInMaximum) {
            SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_tokenIn), address(router), 0);
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(_tokenIn),
                _msgSender(),
                _amountInMaximum - _amountIn
            );
        }
    }

    function exactOutput(
        address _tokenIn,
        address _via,
        address _tokenOut,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint24 _poolFeeA,
        uint24 _poolFeeB
    ) external payable override returns (uint256 _amountIn) {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(_tokenIn),
            _msgSender(),
            address(this),
            _amountInMaximum
        );
        SafeERC20Upgradeable.safeApprove(
            IERC20Upgradeable(_tokenIn),
            address(router),
            _amountInMaximum
        );

        ISwapRouter.ExactOutputParams memory params = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(
                    _tokenOut,
                    _poolFeeA,
                    _via,
                    _poolFeeB,
                    _tokenIn
                ),
                recipient: _recipient,
                deadline: block.timestamp,
                amountOut: _amountOut,
                amountInMaximum: _amountInMaximum
            });

        // Executes the swap, returning the amountIn actually spent.
        _amountIn = router.exactOutput(params);
        if (_amountIn < _amountInMaximum) {
            SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_tokenIn), address(router), 0);
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(_tokenIn),
                _msgSender(),
                _amountInMaximum - _amountIn
            );
        }
    }
}
