// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;
import "./IUniswapV2.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SwapHelper is Ownable {
    IUniswapV2 public uniRouterV2;
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address[] public usdcToWeth;
    using SafeMath for uint256;

    constructor(address[] memory _usdcToWeth, IUniswapV2 _uniRouterV2) {
        usdcToWeth = _usdcToWeth;
        uniRouterV2 = _uniRouterV2;
        USDC.approve(address(uniRouterV2), uint256(-1));
    }

    function swap(uint256 swapAmount, uint256 minOutputAmount) external {
        USDC.transferFrom(msg.sender, address(this), swapAmount);
        uniRouterV2.swapExactTokensForTokens(
            swapAmount,
            minOutputAmount,
            usdcToWeth,
            msg.sender,
            block.timestamp.add(1800)
        );
    }

    function setSwapPath(address[] memory _newPath) external onlyOwner {
        usdcToWeth = _newPath;
    }
}
