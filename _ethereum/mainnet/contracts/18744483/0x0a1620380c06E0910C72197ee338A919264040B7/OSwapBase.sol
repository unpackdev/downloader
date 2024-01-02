// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Ownable.sol";
import "./Interfaces.sol";

contract OSwapBase is Ownable {
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    uint256 internal traderate0; // For one token0 in, how many token1 we give out. 1e36
    uint256 internal traderate1; // For one token1 in, how many token0 we give out. 1e36

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        _setOwner(address(0)); // Revoke owner for implementation contract at deployment
    }

    /*
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible.
     * msg.sender should have already given the oswap contract an allowance of
     * at least amountIn on the input token.
     *
     * @param inToken Input token.
     * @param outToken Output token.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param to Recipient of the output tokens.
     */
    function swapExactTokensForTokens(
        IERC20 inToken,
        IERC20 outToken,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external {
        uint256 price;
        if (inToken == token0) {
            require(outToken == token1, "OSwap: Invalid token");
            price = traderate0;
        } else if (inToken == token1) {
            require(outToken == token0, "OSwap: Invalid token");
            price = traderate1;
        } else {
            revert("OSwap: Invalid token");
        }
        uint256 amountOut = amountIn * price / 1e36;
        require(amountOut >= amountOutMin, "OSwap: Insufficient output amount");

        inToken.transferFrom(msg.sender, address(this), amountIn);
        outToken.transfer(to, amountOut);
    }

    /*
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     *
     * @param inToken Input token.
     * @param outToken Output token.
     * @param amountOut The amount of output tokens to receive.
     * @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param to Recipient of the output tokens.
     */
    function swapTokensForExactTokens(
        IERC20 inToken,
        IERC20 outToken,
        uint256 amountOut,
        uint256 amountInMax,
        address to
    ) external {
        uint256 price;
        if (inToken == token0) {
            require(outToken == token1, "OSwap: Invalid token");
            price = traderate0;
        } else if (inToken == token1) {
            require(outToken == token0, "OSwap: Invalid token");
            price = traderate1;
        } else {
            revert("OSwap: Invalid token");
        }
        uint256 amountIn = ((amountOut * 1e36) / price) + 1; // +1 to always round in our favor
        require(amountIn <= amountInMax, "OSwap: Excess input amount");

        inToken.transferFrom(msg.sender, address(this), amountIn);
        outToken.transfer(to, amountOut);
    }

    /*
     * @notice Set exchange rates.
     */
    function setTraderates(uint256 _traderate0, uint256 _traderate1) external onlyOwner {
        require((1e72 / (_traderate0)) > _traderate1, "OSwap: Price cross");
        traderate0 = _traderate0;
        traderate1 = _traderate1;
    }

    /*
     * @notice Rescue token.
     */
    function transferToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /*
     * @notice Rescue ETH.
     */
    function transferEth(address to, uint256 amount) external onlyOwner {
        (bool success,) = to.call{value: amount}(new bytes(0));
        require(success, "OSwap: ETH transfer failed");
    }
}
