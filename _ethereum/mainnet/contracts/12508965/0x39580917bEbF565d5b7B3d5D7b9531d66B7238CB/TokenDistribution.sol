// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC20.sol";
import "./AggregatorV3Interface.sol";

pragma solidity ^0.8.0;

contract TokenDistribution is Ownable {

    address public token;
    address public oracle;
    
    // price format is 8 decimals precision: $1 = 100000000, $0.01 = 1000000
    uint256 public tokenPriceUSD     = 5000000; // 0.05 USD
    uint256 public minLimitUSD   = 50000000000; // 500 USD
    uint256 public maxLimitUSD = 2000000000000; // 20 000 USD

    uint256 public weiRaised;
    uint256 public notClaimedTokens;

    uint256 public presaleStartsAt;
    uint256 public presaleEndsAt;
    uint256 public claimStartsAt;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public preBoughtTokens;
    mapping(address => uint256) public contributionInUSD;

    event Withdraw(address indexed owner, uint256 indexed amount);
    event BuyTokens(address indexed buyer, uint256 indexed tokens, uint256 indexed pricePerToken, uint256 buyingPower);
    event PreBuyTokens(address indexed buyer, uint256 indexed tokens, uint256 indexed pricePerToken, uint256 buyingPower);
    event ClaimedTokens(address indexed buyer, uint256 indexed tokens);

    constructor(
        address _token, 
        address _oracle,
        uint256 _presaleStartsAt,
        uint256 _presaleEndsAt,
        uint256 _claimStartsAt
        ) public {

        require(_token != address(0));
        require(_oracle != address(0));
        
        require(_presaleStartsAt > block.timestamp, "Presale should start now or in the future");
        require(_presaleStartsAt < _presaleEndsAt, "Presale cannot start after end date");
        require(_presaleEndsAt < _claimStartsAt, "Presale end date cannot be after claim date");

        token = _token;
        oracle = _oracle;

        presaleStartsAt = _presaleStartsAt;
        presaleEndsAt = _presaleEndsAt;
        claimStartsAt = _claimStartsAt;
    }

    modifier isWhitelisted {
        require(whitelisted[msg.sender], "User is not whitelisted");

        _;
    }

    modifier isPresale {
        require(block.timestamp >= presaleStartsAt && block.timestamp <= presaleEndsAt, "It's not presale period");

        _;
    }

    modifier hasTokensToClaim {
        require(preBoughtTokens[msg.sender] > 0, "User has NO tokens");

        _;
    }

    modifier claimStart {
        require(block.timestamp >= claimStartsAt, "Claim period not started");

        _;
    }

    receive() external payable {
        buyTokens();
    }

    function claimTokens() public claimStart hasTokensToClaim {
        
        uint256 usersTokens = preBoughtTokens[msg.sender];
        preBoughtTokens[msg.sender] = 0;

        notClaimedTokens -= usersTokens;

        IERC20(token).transfer(msg.sender, usersTokens);
        emit ClaimedTokens(msg.sender, usersTokens);
    }

    function withdraw() external onlyOwner {

        uint256 amount = address(this).balance;
        address payable ownerPayable = payable(msg.sender);
        ownerPayable.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function withdrawTokens() external onlyOwner claimStart {
        uint256 unsoldTokens = IERC20(token).balanceOf(address(this));

        IERC20(token).transfer(msg.sender, unsoldTokens - notClaimedTokens);
    }

    function buyTokens() public payable isPresale isWhitelisted {
        
        (uint256 tokens, uint256 pricePerTokenEth) = calculateNumberOfTokens(msg.value);
        require(tokens > 0, "Insufficient funds");

        uint256 tradeAmountInUSD = (tokens * tokenPriceUSD) / 10 ** 18;
        
        require(tradeAmountInUSD >= minLimitUSD, "Send amount is below min limit");
        require(tradeAmountInUSD + contributionInUSD[msg.sender] <= maxLimitUSD, "Send amount is above max limit");

        preBoughtTokens[msg.sender] += tokens;
        contributionInUSD[msg.sender] += tradeAmountInUSD;
        weiRaised += msg.value;
        notClaimedTokens += tokens;

        emit PreBuyTokens(msg.sender, tokens, pricePerTokenEth, msg.value);
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

    function whitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }
}
