// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";

import "./IWeth.sol";
import "./IERC721.sol";
import "./IQuoter.sol";
import "./IUniswapV3Pool.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract onthisUniV3Swapper is OwnableUpgradeable {
    address public constant UNISWAP_V3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant QOUTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public pool;
    address public tokenOut;
    uint24 public fee;
    uint256 public slippage;

    uint256[50] private _gap;

    function initialize(
        address _tokenOut,
        address _pool,
        uint24 _fee,
        uint256 _slippage
    ) public initializer {
        __Ownable_init();
        pool = _pool;
        tokenOut = _tokenOut;
        fee = _fee;
        slippage = _slippage;
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        IERC721(token).safeTransferFrom(address(this), to, tokenId, "0x");
    }

    function setSlippage(uint256 _slippage) public onlyOwner {
        slippage = _slippage;
    }

    function _swap(uint256 amountIn, uint256 amountOutMinimum) private returns(uint256){
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

       return ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(params);
    }

    function _contractTokenBalance(address token) private returns (uint256) {
        return IWeth(token).balanceOf(address(this));
    }

    receive() external payable {
        uint256 wethBalanceBefore = _contractTokenBalance(WETH);

        IWeth(WETH).deposit{value: msg.value}();
        IWeth(WETH).approve(UNISWAP_V3_ROUTER, _contractTokenBalance(WETH));
        
        uint256 wethBalanceAfter = _contractTokenBalance(WETH);
        uint256 amountToSwap = wethBalanceAfter - wethBalanceBefore;

        uint256 amountOut = IQuoter(QOUTER).quoteExactInputSingle(
            WETH,
            tokenOut,
            fee,
            amountToSwap,
            0
        );

        uint256 amountOutMin = amountOut - ((amountOut * slippage)) / 100;
        uint256 resulAmountOut = _swap(amountToSwap, amountOutMin);
        
        IERC20(tokenOut).transfer(msg.sender, resulAmountOut);
    }
}
