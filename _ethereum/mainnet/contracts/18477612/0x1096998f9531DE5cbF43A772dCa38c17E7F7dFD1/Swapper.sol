// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface IUniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract Swapper {

    event BuyTransactions(address indexed forAccount, int256 amountBought);

    AggregatorV3Interface private constant ETH_USD_FEED = AggregatorV3Interface(
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );
    
    IUniswapV2Router private constant UNISWAP_V2_ROUTER = IUniswapV2Router(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant AAPX = 0xbfD815347d024F449886c171f78Fa5B8E6790811;

    address public owner;
    int256 public txPriceUsdc;

    mapping(address => int256) public txCount;

    constructor(address _owner, int256 _txPriceUSDC) {
        owner = _owner;
        txPriceUsdc = _txPriceUSDC;
    }

    function updateTxPrice(int256 newTxPriceInUsdc) external {
        require(msg.sender == owner, "Only owner can update tx price.");
        txPriceUsdc = newTxPriceInUsdc;
    }
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner can transfer ownership.");
        owner = newOwner;
    }

    function emergencyWithdraw(uint256 amount) external {
        require(msg.sender == owner, "Only owner can call emergency withdraw.");
        payable(msg.sender).transfer(amount);
    }

    function txPriceUsdcDecimals() external view returns (uint256) {
        return ETH_USD_FEED.decimals();
    }

    function buyTransactions(address forAccount) public payable {
        (,int ethUsdcPrice,,,) = ETH_USD_FEED.latestRoundData();
        int256 txs = ((int256(msg.value) * ethUsdcPrice) / 1e18) / txPriceUsdc;
        txCount[forAccount] += txs;
        swap();
        emit BuyTransactions(forAccount, txs);
    }

    function swap() public {
        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = AAPX;
        UNISWAP_V2_ROUTER.swapExactETHForTokens{
            value: address(this).balance 
        }(0, path, address(this), block.timestamp);
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {
        buyTransactions(msg.sender);
    }

}