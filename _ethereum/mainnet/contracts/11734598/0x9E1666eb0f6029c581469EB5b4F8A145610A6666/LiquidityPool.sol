//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./SafeMath.sol";
import "./TW33T.sol";

contract LiquidityPool is Ownable {
    using SafeMath for uint256;

    TW33T public token;
    uint256 public rate;
    uint256 public total;
    uint256 public listingRate;
    uint256 public rewards;

    bool finalized = false;

    IUniswapV2Router02 router;
    IUniswapV2Factory factory;

    mapping (address => uint256) public whitelist;
    mapping (address => uint256) public contribution;
    uint256 public raised;

    uint256 public startDate;

    constructor(IUniswapV2Router02 _router) {
        router = _router;
        factory = IUniswapV2Factory(router.factory());
    }

    function prepare(uint256 _rate, uint256 _total, uint256 _listingRate, TW33T _token) public onlyOwner {
        require(_total % _rate == 0, "Prepare: total amount must be divisible by rate");
        require(startDate == 0, "Prepare: countdown has already started");
        total = _total;
        rate = _rate;
        listingRate = _listingRate;
        token = _token;
        // whitelist this contract for reward and presale distribution
        token.whitelist(address(this), true);
    }

    function finalize() public onlyOwner {
        // prevent adding liquidity twice
        require(!finalized, "Finalize: presale was already finalized");
        // make sure we sold all of the tokens
        require(block.timestamp >= startDate + 1 days, "Finalize: sale isn't over yet");
        
        finalized = true;
        // allow token transfers
        token.unpause();
        // allow uniswap to spend required amount of tokens
        token.approve(address(router), listingRate * raised);
        // add liquidity to uniswap
        router.addLiquidityETH{value: raised}(
            address(token),
            listingRate * raised,
            listingRate * raised,
            raised,
            address(this),
            block.timestamp
        );

        // whitelist uniswap pair so that buying isn't taxed
        address pair = factory.getPair(router.WETH(), address(token));
        token.whitelist(pair, true);

        // Since tokens are distributed right away, leftover is going to be used for rewards
        rewards = token.balanceOf(address(this));
    }

    function reward(address recipient, uint256 amount) public onlyOwner {
        require(amount <= rewards, "Reward: not enough tokens in reward pool");
        token.transfer(recipient, amount);
        rewards = rewards.sub(amount);
    }

    function addToWhitelist(address[] calldata addresses, uint256 cap) public onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = cap;
        }
    }

    function startTimer(uint256 date) public onlyOwner {
        require(address(token) != address(0), "Start: presale needs a token before starting");
        startDate = date;
    }

    receive() external payable {
        // make sure that timer is started
        require(startDate != 0, "Buy: presale timer wasn't started");
        // make sure that current time is after presale start
        require(block.timestamp >= startDate, "Buy: presale hasn't started yet");
        // make sure that presale isn't over yet
        require(block.timestamp < startDate + 1 days, "Buy: presale is over");
        //require(address(token) == address(0), "Buy: presale was finalized");
        contribution[msg.sender] = contribution[msg.sender].add(msg.value);
        require(contribution[msg.sender] <= whitelist[msg.sender], "Buy: contribution exceeds whitelist");
        token.transfer(msg.sender, msg.value * rate);
        raised = raised.add(msg.value);
        require(raised <= total / rate, "Buy: presale is filled");
    }
}
