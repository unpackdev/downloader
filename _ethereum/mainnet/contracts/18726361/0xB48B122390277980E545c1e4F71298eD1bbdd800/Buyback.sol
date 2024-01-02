// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.21;

import "./Math.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";

/// @dev This contract is the contract that will be used to execute buybacks.
contract Buyback is Ownable {
    using Math for uint256;
    using SafeERC20 for ERC20;

    /// @dev The Uniswap V2 Router.
    IUniswapV2Router02 public immutable uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /// @dev The Lucky8 token.
    address private constant _LUCKY8 = 0x8880111018C364912dBe5Ee61D98942647680888;

    /// @dev The USDC token.
    address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /// @dev The token pair.
    address pair = 0xe0384Fd8C9fb7b546bF80153AC9F262Df596E62C;

    /// @dev The operator.
    address public operator;

    /// @dev The team wallet.
    address public teamWallet = 0xb1CD7D5D51482B5E334B97E668f446f745f80718;

    /// @dev The lottery address.
    address public lottery = 0xCaC93d18f237e355B71eC00293Ae93aE186257Ea;

    /// @dev Event emitted when the operator is updated.
    event SetOperator(address indexed operator);

    /// @dev Event emitted when the team wallet is updated.
    event SetTeamWallet(address indexed teamWallet);

    /// @dev Event emitted when the lottery address is updated.
    event SetLottery(address indexed lottery);

    /// @dev Event emitted when the treasury address is updated.
    event SetTreasury(address indexed treasury);

    /// @dev The constructor
    constructor(address _operator) Ownable(msg.sender) {
        operator = _operator;
        emit SetOperator(_operator);
    }

    /// @dev This function is used to set a new operator.
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
        emit SetOperator(_operator);
    }

    /// @dev This function is used to set the team wallet.
    function setTeamWallet(address _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
        emit SetTeamWallet(teamWallet);
    }

    /// @dev This function is used to set the lottery address.
    function setLottery(address _lottery) external onlyOwner {
        lottery = _lottery;
        emit SetLottery(lottery);
    }

    /// @dev This function is used to get the optimal amount of tokens to swap to LP.
    function getSwapAmount(uint256 r, uint256 a) public pure returns (uint256) {
        return (Math.sqrt(r * (r * 3_988_009 + a * 3_988_000)) - r * 1997) / 1994;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minOut) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        ERC20(tokenIn).approve(address(uniswapRouter), amountIn);

        uint256 balanceBefore = ERC20(tokenOut).balanceOf(address(this));

        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, minOut, path, address(this), block.timestamp
        );

        uint256 balanceAfter = ERC20(tokenOut).balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        internal
        returns (uint256)
    {
        ERC20(tokenA).approve(address(uniswapRouter), amountADesired);
        ERC20(tokenB).approve(address(uniswapRouter), amountBDesired);

        (,, uint256 liquidityOut) = IUniswapV2Router02(uniswapRouter).addLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, 0, 0, address(this), block.timestamp
        );

        return liquidityOut;
    }

    /// @dev This function is used to sell fees and redistribute.
    function distributeFees(uint256 _amountIn, uint256 _minOut) external {
        require(msg.sender == operator || msg.sender == owner(), "Buyback: forbidden");

        // Swap 90% and send to lottery contract and team wallet.
        uint256 sellAmount = _amountIn.mulDiv(9e17, 1e18);
        uint256 amountOut = swap(_LUCKY8, _USDC, sellAmount, _minOut);

        // 11% of the amountOut is sent to the team wallet.
        uint256 teamAmount = amountOut.mulDiv(11e16, 1e18);
        uint256 lotteryAmount = amountOut - teamAmount;

        ERC20(_USDC).safeTransfer(teamWallet, teamAmount);
        ERC20(_USDC).safeTransfer(lottery, lotteryAmount);

        // Get optimal input for LP tokens.
        uint256 remainingAmount = _amountIn - sellAmount;
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 reserveIn = IUniswapV2Pair(pair).token0() == _LUCKY8 ? reserve0 : reserve1;
        uint256 amountToSwap = getSwapAmount(reserveIn, remainingAmount);

        uint256 usdcOut = swap(_LUCKY8, _USDC, amountToSwap, 0);
        uint256 liquidityAmount = addLiquidity(_LUCKY8, _USDC, remainingAmount - amountToSwap, usdcOut);
        ERC20(pair).safeTransfer(owner(), liquidityAmount);
    }

    /// @dev This function is used to execute a buyback.
    function buyback(uint256 _amountIn, uint256 _minOut) external {
        require(msg.sender == operator, "Buyback: forbidden");
        swap(_USDC, _LUCKY8, _amountIn, _minOut);
    }

    /// @dev This function is used to transfer any tokens stored here to the owner.
    function transferToken(address _token, uint256 _amount) public {
        require(msg.sender == owner() || msg.sender == operator, "Buyback: forbidden");
        ERC20(_token).transfer(owner(), _amount);
    }
}
