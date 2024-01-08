// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC20.sol";
import "./AggregatorV3Interface.sol";

pragma solidity ^0.8.0;

contract TokenDistribution is Ownable {

    address public token;
    address public oracle;
    
    // price format is 8 decimals precision: $1 = 100000000, $0.01 = 1000000
    uint256 public tokenPriceUSD     = 10000000; // 0.10 USD
    uint256 public minLimitUSD    = 50000000000; // 500 USD
    uint256 public maxLimitUSD  = 2500000000000; // 25 000 USD

    uint256 public weiRaised;

    mapping(address => uint256) public contributionInUSD;

    event Withdraw(address indexed owner, uint256 indexed amount);
    event WithdrawTokens(address indexed owner, uint256 indexed amount);
    event BoughtTokens(address indexed buyer, uint256 indexed tokens, uint256 indexed pricePerToken, uint256 buyingPower);

    constructor (
        address _token, 
        address _oracle
        ) public {

        require(_token != address(0));
        require(_oracle != address(0));
        
        token = _token;
        oracle = _oracle;
    }

    receive() external payable {
        buyTokens();
    }

    function withdraw() external onlyOwner {

        uint256 amount = address(this).balance;
        address payable ownerPayable = payable(msg.sender);
        ownerPayable.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function withdrawTokens() external onlyOwner {
        uint256 unsoldTokens = IERC20(token).balanceOf(address(this));

        IERC20(token).transfer(msg.sender, unsoldTokens);
        
        emit WithdrawTokens(msg.sender, unsoldTokens);
    }

    function buyTokens() public payable {
        
        (uint256 tokens, uint256 pricePerTokenEth) = calculateNumberOfTokens(msg.value);
        require(tokens > 0, "Insufficient funds");

        uint256 tradeAmountInUSD = (tokens * tokenPriceUSD) / 10 ** 18;
        
        require(tradeAmountInUSD >= minLimitUSD, "Send amount is below min limit");
        require(tradeAmountInUSD + contributionInUSD[msg.sender] <= maxLimitUSD, "Send amount is above max limit");

        contributionInUSD[msg.sender] += tradeAmountInUSD;
        weiRaised += msg.value;

        IERC20(token).transfer(msg.sender, tokens);
        emit BoughtTokens(msg.sender, tokens, pricePerTokenEth, msg.value);
    }

    function calculateNumberOfTokens(uint256 _wei) public view returns(uint256, uint256){

        uint256 pricePerTokenETH = getPriceInEthPerToken();
        uint256 numberOfTokens = divide(_wei, pricePerTokenETH, 18);
        if (numberOfTokens == 0) {
            return(0,0);
        }

        return (numberOfTokens, pricePerTokenETH);
    }

    function getPriceInEthPerToken() public view returns(uint256) {
        int oraclePriceTemp = getLatestPriceETHUSD();
        require(oraclePriceTemp > 0, "Invalid price");

        uint256 oraclePriceETHUSD = uint256(oraclePriceTemp);

        // returned value format is in 18 decimals precision
        return divide(tokenPriceUSD, oraclePriceETHUSD, 18);
    }

    function getLatestPriceETHUSD() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(oracle).latestRoundData();

        return price;
    }

    function getDecimalOracle() public view returns (uint8) {
        (
            uint8 decimals
        ) = AggregatorV3Interface(oracle).decimals();

        return decimals;
    }

    function divide(uint a, uint b, uint precision) private pure returns ( uint) {
        return (a * (10**precision)) / b;
    }

}
