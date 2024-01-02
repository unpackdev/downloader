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

contract PolyflowSwapper {

    event PaySubscription(bytes32 indexed user, int256 usdcAmount, uint256 timestamp);

    AggregatorV3Interface private constant ETH_USD_FEED = AggregatorV3Interface(
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );
    
    IUniswapV2Router private constant UNISWAP_V2_ROUTER = IUniswapV2Router(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant AAPX = 0xbfD815347d024F449886c171f78Fa5B8E6790811;

    address public owner;

    struct Payment {
        int256 usdcAmount;
        uint256 timestamp;
    }

    mapping(bytes32 => Payment[]) public payments;

    constructor(address _owner) {
        owner = _owner;
    }

    function getPaymentsAmount(bytes32 forUser) external view returns (uint256) {
        return payments[forUser].length;
    }
    function getAllPayments(bytes32 forUser) external view returns (Payment[] memory) {
        return payments[forUser];
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner can transfer ownership.");
        owner = newOwner;
    }

    function emergencyWithdraw(uint256 amount) external {
        require(msg.sender == owner, "Only owner can call emergency withdraw.");
        payable(msg.sender).transfer(amount);
    }

    function paySubscription(bytes32 forUser) public payable {
        (,int ethUsdcPrice,,,) = ETH_USD_FEED.latestRoundData();
        int256 usdcAmount = ((int256(msg.value) * ethUsdcPrice) / 1e18);
        payments[forUser].push(Payment(usdcAmount, block.timestamp));
        emit PaySubscription(forUser, usdcAmount, block.timestamp);
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

}