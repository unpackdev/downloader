// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IExchangeAdapter.sol";
import "./IWETH.sol";
import "./ISwapRouter.sol";

contract UniswapV3Exchange is OwnableUpgradeable, IExchangeAdapter {
    ISwapRouter public router;
    IWETH public wethToken;

    function __UniswapV3Exchange_init(address _router, address _wethToken) external initializer {
        __Ownable_init();
        router = ISwapRouter(_router);
        wethToken = IWETH(_wethToken);
    }

    function swapExactInputSingle(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24 _poolFee
    ) external payable override returns (uint256) {
        _transferFromSender(_tokenIn, _amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
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
        address[] memory _path,
        address _tokenOut,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24[] memory _poolFees
    ) external payable override returns (uint256) {
        _transferFromSender(_tokenIn, _amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: _defineExactInputPath(_tokenIn, _path, _poolFees, _tokenOut),
            recipient: _recipient,
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: _amountOutMinimum
        });
        return router.exactInput(params);
    }

    function _transferFromSender(address _tokenIn, uint256 _amount) internal {
        if (_tokenIn == address(wethToken)) {
            wethToken.transferFrom(_msgSender(), address(this), _amount);
            wethToken.approve(address(router), _amount);
        } else {
            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(_tokenIn),
                _msgSender(),
                address(this),
                _amount
            );
            SafeERC20Upgradeable.safeApprove(
                IERC20Upgradeable(_tokenIn),
                address(router),
                _amount
            ); // max amount to spend
        }
    }

    // @notice encode exactInput path
    // @param  Array of intermediary pools
    // @param Array of intermediary pool fees
    // @return ecoded path for up to 3 hops swap
    function _defineExactInputPath(
        address _tokenIn,
        address[] memory _viaPath,
        uint24[] memory _poolFees,
        address _tokenOut
    ) internal pure returns (bytes memory _path) {
        if (_poolFees.length == 2) {
            _path = abi.encodePacked(_tokenIn, _poolFees[0], _viaPath[0], _poolFees[1], _tokenOut);
        }
        if (_poolFees.length == 3) {
            _path = abi.encodePacked(
                _tokenIn,
                _poolFees[0],
                _viaPath[0],
                _poolFees[1],
                _viaPath[1],
                _poolFees[2],
                _tokenOut
            );
        }
    }

    // @notice Check and transfer remaining funds after exactOut swap
    function _returnRemainingFunds(address _tokenIn) internal {
        if (wethToken.balanceOf(address(this)) > 0) {
            wethToken.approve(address(router), 0);
            wethToken.transfer(_msgSender(), wethToken.balanceOf(address(this)));
        } else if (IERC20Upgradeable(_tokenIn).balanceOf(address(this)) > 0) {
            IERC20Upgradeable(_tokenIn).approve(address(router), 0);
            IERC20Upgradeable(_tokenIn).transfer(
                _msgSender(),
                IERC20Upgradeable(_tokenIn).balanceOf(address(this))
            );
        }
    }
}
