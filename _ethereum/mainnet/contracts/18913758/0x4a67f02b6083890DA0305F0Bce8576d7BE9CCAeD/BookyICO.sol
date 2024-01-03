// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./console.sol";
import "./ERC20.sol";
import "./AggregatorV3Interface.sol";

contract BookyICO {
    ERC20 public token;
    address payable private owner =
        payable(0x96064ba777Af98F272e4C78e380b944F2742f0c5);
    AggregatorV3Interface internal dataFeed;
    uint256 public tokenPriceInCents;
    uint256 public totalTokensSold;
    uint8 public icoPhase;
    uint256 public saleLimit;

    constructor(address _token) {
        token = ERC20(_token); // Initialize the ERC20 token
        dataFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); // Initialize Chainlink Price Feed
        tokenPriceInCents = 2;
        icoPhase = 1;
        saleLimit = 222_000_000 ether;
    }

    // Function to buy tokens with Ether
    function buyToken() external payable {
        require(msg.value > 0, "BuyToken:: Value cannot be zero");
        uint256 _tokenRate = _getRate();
        uint256 _totalTokens = (msg.value / _tokenRate) * 1 ether;
        require(_totalTokens < saleLimit, "BuyToken:: Sale limit exeed for this phase");
        require(_totalTokens + totalTokensSold < saleLimit, "BuyToken:: token sale limit exceed, please reduce the amount");
        ERC20(token).transferFrom(owner, msg.sender, _totalTokens);
        owner.transfer(msg.value);
        totalTokensSold += _totalTokens;
    }

    function changeTokenPhase(uint8 _phase) external {
        require(msg.sender == owner, "changeTokenPhase: only owner can call");
        require(_phase < 4, "changeTokenPhase: only till phase 3");
        require(_phase > 1, "changeTokenPhase: can't assign phase one");
        require(_phase > icoPhase, "changeTokenPhase: please change the phase");
        if(_phase == 2) {
            tokenPriceInCents = 8;
            icoPhase = _phase;
            saleLimit = 75_500_000 ether;
            totalTokensSold = 0;
        }
        if(_phase == 3) {
            tokenPriceInCents = 17;
            icoPhase = _phase;
            saleLimit = 36_100_000 ether;
            totalTokensSold = 0;
        }
    }

    function getICOPhase() view public returns(uint8){
        return icoPhase;
    }

    // Function to get the current token rate based on fixed Ethereum price
    function _getRate() view internal returns (uint256) {
        uint256 ethPrice = _getETHPrice() / 10 ** 8;
        uint256 tokenInWei = 1 ether * tokenPriceInCents;
        uint256 rate = tokenInWei / ethPrice / 1000;
        return rate;
    }

    // Function to get the current Ethereum price from Chainlink Price Feed
    function _getETHPrice() view internal returns (uint256) {
        (, int answer, , , ) = dataFeed.latestRoundData();
        return uint256(answer);
    }
}
