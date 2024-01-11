// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract EasyConverter {
    using SafeERC20 for IERC20;

    address public uniswapV2Router;
    address public wrappedNativeAddress;
    address public sourceToken;
    address public destinationToken;

    constructor(
        address _uniswapV2Router,
        address _wrappedNativeAddress,
        address _sourceToken,
        address _destinationToken
    ) {
        uniswapV2Router = _uniswapV2Router;
        wrappedNativeAddress = _wrappedNativeAddress;
        sourceToken=_sourceToken;
        destinationToken=_destinationToken;
    }
    
    function convert(uint256 amount) external {
        require(IERC20(sourceToken).balanceOf(address(this)) >= amount, "amount not enough");
        IERC20(sourceToken).safeApprove(uniswapV2Router, amount);
        address[] memory paths;
        paths = new address[](3);
        paths[0] = sourceToken;
        paths[1] = wrappedNativeAddress;
        paths[2] = destinationToken;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokens(
                    amount,
                    0,
                    paths,
                    msg.sender,
                    block.timestamp);
    }
}
