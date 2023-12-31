// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./ITradeContract.sol";
import "./IV3SwapRouter.sol";
import "./IWETH9.sol";

contract TradeContract is ITradeContract, Pausable, Ownable {
    struct BuyV2Params {
        address router;
        address[] path;
        uint256 amountBuyInETH;
        uint256 times;
        address to;
    }

    struct ExactInputParam {
        address router;
        address[] path;
        uint24[] fee;
        uint256 amountIn;
        uint256 times;
        address to;
    }

    struct SellV2Params {
        address router;
        address[] path;
        uint256 amountSellInTokens;
        uint256 times;
        address to;
    }

    uint256 public immutable MAX_PERCENTAGE = 10000;

    constructor() {}

    receive() external payable {}

    fallback() external payable {}

    function buyV2(BuyV2Params calldata params) external payable {
        IWETH9 weth = IWETH9(params.path[0]);
        IUniswapV2Router02 router = IUniswapV2Router02(params.router);

        if (msg.value > 0) {
            weth.deposit{ value: address(this).balance }();
        }

        require(
            weth.balanceOf(address(this)) >
                params.amountBuyInETH * params.times,
            "TradeContract::not enough eth"
        );

        weth.approve(address(router), type(uint256).max);

        for (uint8 i = 0; i < params.times; i++) {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                params.amountBuyInETH,
                0,
                params.path,
                address(this),
                block.timestamp + 1 minutes
            );
        }
    }

    function sellV2(SellV2Params calldata params) external {
        IERC20 token = IERC20(params.path[params.path.length - 1]);
        IUniswapV2Router02 router = IUniswapV2Router02(params.router);

        token.approve(address(router), type(uint256).max);

        for (uint8 i = 0; i < params.times; i++) {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                params.amountSellInTokens,
                0,
                reversePath(params.path),
                address(this),
                block.timestamp + 1 minutes
            );
        }
    }

    function exactInput(ExactInputParam calldata params) external payable {
        IV3SwapRouter router = IV3SwapRouter(params.router);
        IWETH9 weth = IWETH9(params.path[0]);
        weth.approve(params.router, type(uint256).max);

        if (msg.value > 0) {
            weth.deposit{ value: address(this).balance }();
        }

        bytes memory _path = "";

        for (uint8 i = 0; i < params.fee.length; i++) {
            _path = bytes.concat(
                _path,
                bytes20(params.path[i]),
                bytes3(params.fee[i]),
                bytes20(params.path[i + 1])
            );
        }

        for (uint8 i = 0; i < params.times; i++) {
            router.exactInput(
                IV3SwapRouter.ExactInputParams({
                    path: _path,
                    recipient: address(this),
                    amountIn: params.amountIn,
                    amountOutMinimum: 0
                })
            );
        }
    }

    function balance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function withdraw(address _weth) external onlyOwner {
        IWETH9 weth = IWETH9(_weth);
        weth.withdraw(weth.balanceOf(address(this)));
        _withdraw(_msgSender(), address(this).balance);
    }

    function transferWeth(address _weth) external onlyOwner {
        IWETH9 weth = IWETH9(_weth);
        weth.approve(address(this), type(uint256).max);
        weth.transfer(_msgSender(), weth.balanceOf(address(this)));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
