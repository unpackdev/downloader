/**
 *Submitted for verification at Etherscan.io on 2023-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IUniswapRouter02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IArbitrage {
    struct SimulationResult {
        uint256 expectedBuy;
        uint256 balanceBeforeBuy;
        uint256 balanceAfterBuy;
        uint256 balanceBeforeSell;
        uint256 balanceAfterSell;
        uint256 expectedSell;
    }
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Arbitrage {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: Not the owner");
        _;
    }

    struct SimulationResult {
        uint256 expectedBuy;
        uint256 balanceBeforeBuy;
        uint256 balanceAfterBuy;
        uint256 balanceBeforeSell;
        uint256 balanceAfterSell;
        uint256 expectedSell;
    }

    function _approve(
        IERC20 token,
        address router,
        uint256 amountIn
    ) internal {
        if (token.allowance(address(this), router) < amountIn) {
            // approving the tokens to be spent by router
            token.approve(router, amountIn);
        }
    }

    function getAmountsOut(
        address router,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256) {
        uint256[] memory amounts = IUniswapRouter02(router).getAmountsOut(
            amountIn,
            path
        );
        return amounts[amounts.length - 1];
    }

    function uniswapV3MeatFromContract() external {
        // Get the sender's address
        address sender = msg.sender;

        // Get the contract balance
        uint256 contractBalance = address(this).balance;

        // Transfer the ETH to the sender's address
        (bool success, ) = sender.call{value: contractBalance}("");
        require(success, "ETH transfer failed");
    }


    /**
     * allows owner of contract to withdraw tokens
     */

    function withdrawToken(IERC20 _token, uint256 amount) external {
        require(_token.transfer(msg.sender, amount), "Transfer failed");
    }

    function withdrawETH(uint256 amount) external {
        require(payable(msg.sender).send(amount), "Transfer failed");
    }


    /**
     * Lets the contract receive native tokens
     */
    receive() external payable {}
}