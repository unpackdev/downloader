// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BaseBurner.sol";
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

contract UniswapV2Burner is BaseBurner, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public uniswapV2Router;
    address public wrappedNativeAddress;

    constructor(
        address _receiver,
        address _uniswapV2Router,
        address _wrappedNativeAddress
    ) BaseBurner(_receiver) {
        uniswapV2Router = _uniswapV2Router;
        wrappedNativeAddress = _wrappedNativeAddress;
    }

    /* User functions */

    /*
     * @notice Burn token for targetToken
     * @notice This function assumes there exists a token-wrappedNative LP and a wrappedNative-targetToken LP in the dex
     * @param token The token to be burned
     * @return Total targetToken sent to receiver after successfully executing this function
     */
    function burn(address token)
        external
        onlyBurnableToken(token)
        nonReentrant
        returns (uint256)
    {
        require(receiver != address(0), "receiver not set");
        uint256 msgSenderBalance = IERC20(token).balanceOf(msg.sender);
        if (msgSenderBalance != 0) {
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                msgSenderBalance
            );
        }
        uint256 amountToBurn = IERC20(token).balanceOf(address(this));
        uint256 actualAmountOut;
        address targetToken = burnableTokens[token];
        if (amountToBurn != 0) {
            IERC20(token).safeApprove(uniswapV2Router, amountToBurn);
            address[] memory paths;
            if (token == wrappedNativeAddress) {
                paths = new address[](2);
                paths[0] = token;
                paths[1] = targetToken;
            } else {
                paths = new address[](3);
                paths[0] = token;
                paths[1] = wrappedNativeAddress;
                paths[2] = targetToken;
            }
            actualAmountOut = IUniswapV2Router(uniswapV2Router)
                .swapExactTokensForTokens(
                    amountToBurn,
                    0,
                    paths,
                    receiver,
                    block.timestamp
                )[paths.length - 1];
        }

        uint256 targetTokenBalance = IERC20(targetToken).balanceOf(
            address(this)
        );
        IERC20(targetToken).safeTransfer(receiver, targetTokenBalance);
        return targetTokenBalance;
    }

    /* Admin functions */

    /*
     * @notice set the uniswapV2Router address
     * @param _uniswapV2Router The router address
     */
    function setUniswapV2Router(address _uniswapV2Router) external onlyOwner {
        uniswapV2Router = _uniswapV2Router;
    }
}
