// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router01.sol";
import "./IWETH.sol";

contract UniswapV2RawTokenConverter is ReentrancyGuard, Context {
    event ConvertDone(
        address indexed from,
        address indexed to,
        uint256 amtFrom,
        uint256 amtTo
    );

    IUniswapV2Router01 public uniRouter;

    constructor(IUniswapV2Router01 _uniRouter) {
        uniRouter = _uniRouter;
    }

    receive() external payable {
        require(
            _msgSender() == address(uniRouter) ||
                _msgSender() == uniRouter.WETH(),
            "TC: NOT_ALLOWED"
        );
    }

    function convertToETH(IERC20[] calldata tokens) external {
        convertToETH(tokens, _msgSender());
    }

    function convertToETH(
        IERC20[] calldata tokens,
        address receiver
    ) public nonReentrant {
        require(receiver != address(0), "TC: ZERO_ADDRESS");

        address weth9 = uniRouter.WETH();

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            uint256 amountIn = token.balanceOf(_msgSender());
            IERC20(token).transferFrom(_msgSender(), address(this), amountIn);
            if (weth9 == address(token)) {
                IWETH(weth9).withdraw(amountIn);
                emit ConvertDone(weth9, address(0), amountIn, amountIn);
            } else {
                address[] memory path = new address[](2);
                path[0] = address(token);
                path[1] = weth9;
                uint256[] memory amounts = uniRouter.getAmountsOut(
                    amountIn,
                    path
                );
                IERC20(token).approve(address(uniRouter), amountIn);
                uniRouter.swapExactTokensForETH(
                    amountIn,
                    amounts[path.length - 1],
                    path,
                    address(this),
                    block.timestamp + 10
                );
                emit ConvertDone(
                    address(token),
                    address(0),
                    amountIn,
                    amounts[path.length - 1]
                );
            }
        }

        uint256 amountToWithdraw = address(this).balance;

        require(amountToWithdraw > 0, "TC: ZERO_AMOUNT");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = receiver.call{value: amountToWithdraw}("");
        require(success, "TC: SEND_REVERTED");
    }
}
