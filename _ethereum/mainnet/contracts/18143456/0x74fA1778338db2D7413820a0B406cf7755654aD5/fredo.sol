// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";
import "./Ownable.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract ArbitrageBot is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    bool public isPaused = false;
    IUniswapV2Router public uniswapRouter;
    mapping(address => bool) public trustedOracles;

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    event TradeExecuted(address indexed sourceToken, address indexed destinationToken, uint amount);
    event Withdrawn(address indexed to, uint amount);

    constructor(address _uniswapRouter) {
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
    }

    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }

    function addOracle(address _oracle) external onlyOwner {
        trustedOracles[_oracle] = true;
    }

    function removeOracle(address _oracle) external onlyOwner {
        trustedOracles[_oracle] = false;
    }

    function getPriceFromOracle(address _priceFeedAddress) public view returns (uint256) {
        require(trustedOracles[_priceFeedAddress], "Oracle not trusted");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddress);
        (, int price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Price is non-positive");
        return uint256(price);
    }

    function executeTrade(
        address sourceToken,
        address destinationToken,
        address sourceTokenPriceFeed,
        address destinationTokenPriceFeed,
        uint256 slippageTolerance
    )
        external onlyOwner whenNotPaused nonReentrant
    {
        uint256 sourcePrice = getPriceFromOracle(sourceTokenPriceFeed);
        uint256 destinationPrice = getPriceFromOracle(destinationTokenPriceFeed);

        uint256 tokenDecimals = IERC20(sourceToken).decimals();
        uint256 amountIn = 1 * (10 ** tokenDecimals);
        uint256 amountOutMin = destinationPrice.mul(amountIn).div(sourcePrice);

        (uint112 reserveSource, uint112 reserveDest) = checkLiquidity(sourceToken, destinationToken);
        require(reserveSource >= amountIn, "Not enough liquidity in the source token");
        require(reserveDest >= amountOutMin, "Not enough liquidity in the destination token");

        address[] memory path = new address[](2);
        path[0] = sourceToken;
        path[1] = destinationToken;

        IERC20(sourceToken).transferFrom(msg.sender, address(this), amountIn);
        IERC20(sourceToken).approve(address(uniswapRouter), amountIn);

        uint256 adjustedAmountOutMin = amountOutMin.mul(10000 - slippageTolerance).div(10000);
        uniswapRouter.swapExactTokensForTokens(amountIn, adjustedAmountOutMin, path, msg.sender, block.timestamp + 120);

        emit TradeExecuted(sourceToken, destinationToken, amountIn);
    }

    function checkLiquidity(address tokenA, address tokenB) public view returns (uint112 reserveA, uint112 reserveB) {
        IUniswapV2Pair uniswapPair = IUniswapV2Pair(IUniswapV2Router(uniswapRouter).getPair(tokenA, tokenB));
        (uint112 reserve0, uint112 reserve1, ) = uniswapPair.getReserves();
        address pairToken0 = uniswapPair.token0();
        if (tokenA == pairToken0) {
            return (reserve0, reserve1);
        } else {
            return (reserve1, reserve0);
        }
    }

    function withdraw() external onlyOwner {
        uint amount = address(this).balance;
        payable(owner()).transfer(amount);
        emit Withdrawn(owner(), amount);
    }

    function retrieveTokens(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to retrieve");
        require(token.transfer(owner(), balance), "Token transfer failed");
    }

    receive() external payable {}
}
