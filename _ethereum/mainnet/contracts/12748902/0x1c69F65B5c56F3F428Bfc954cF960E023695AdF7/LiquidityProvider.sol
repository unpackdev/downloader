//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./ILiquidityProvider.sol";
import "./IOneUp.sol";


contract LiquidityProvider is ILiquidityProvider, Ownable {
    using SafeMath for uint256;

    uint256 public lock;
    uint256 public constant UNISWAP_TOKEN_PRICE = 120000; // 1 ETH = 120,000 1-UP
    uint256 public constant LP_TOKENS_LOCK_DELAY = 180 days;

    IOneUp public immutable oneUpToken;
    IUniswapV2Router02 public immutable uniswap;

    event Provided(uint256 token, uint256 amount);
    event Recovered(address token, uint256 amount);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    constructor(address oneUpToken_, address uniswapRouter_) {
        oneUpToken = IOneUp(oneUpToken_);
        uniswap = IUniswapV2Router02(uniswapRouter_);
    }

    receive() external payable {
        // Silence
    }

    // ------------------------
    // SETTERS (OWNABLE)
    // ------------------------

    /// @notice Owner can add liquidity to the 1-UP/ETH pool
    /// @dev If ETH balance of the contract is 0 transaction will be declined
    function addLiquidity() public override onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'addLiquidity: ETH balance is zero!');

        uint256 amountTokenDesired = balance.mul(UNISWAP_TOKEN_PRICE);
        oneUpToken.mint(address(this), amountTokenDesired);
        oneUpToken.approve(address(uniswap), amountTokenDesired);

        uniswap.addLiquidityETH{value: (balance)}(
            address(oneUpToken),
            amountTokenDesired,
            amountTokenDesired,
            balance,
            address(this),
            block.timestamp.add(2 hours)
        );

        lock = block.timestamp;
        emit Provided(amountTokenDesired, balance);
    }

    /// @notice Owner can recover LP tokens after LP_TOKENS_LOCK_DELAY from adding liquidity
    /// @dev If time does not reached method will be failed
    /// @param lpTokenAddress Address of 1-UP/ETH LP token
    /// @param receiver Address who should receive tokens
    function recoverERC20(address lpTokenAddress, address receiver) public override onlyOwner {
        require(lock != 0, 'recoverERC20: Liquidity not added yet!');
        require(block.timestamp >= lock.add(LP_TOKENS_LOCK_DELAY), 'recoverERC20: You can claim LP tokens after 180 days!');

        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.transfer(receiver, balance);

        emit Recovered(lpTokenAddress, balance);
    }
}
