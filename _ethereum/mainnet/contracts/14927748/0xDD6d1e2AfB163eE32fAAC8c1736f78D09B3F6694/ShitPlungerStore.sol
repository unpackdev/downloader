// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface IShitPlunger {
    function mint(address to, uint32 amount) external;
}

contract ShitPlungerStore is Ownable {
    using Address for address payable;

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant PRICE_MULTIPLIER = 100_000_000 ether;

    struct Status {
        // config
        uint32 startingPrice;
        uint32 endingPrice;
        uint32 startTime;
        uint32 duration;
        uint32 increasePerInterval;
        uint32 interval;

        uint256 priceMultiplier;
        uint32 maxSupply;
        uint32 publicSupply;
        uint32 walletLimit;

        // state
        uint32 publicMinted;
        uint32 userMinted;
        bool soldout;
    }

    struct AuctionConfig {
        uint32 startingPrice;
        uint32 endingPrice;
        uint32 startTime;
        uint32 duration;
        uint32 increasePerInterval;
        uint32 interval;
    }

    IShitPlunger public immutable _shitPlunger;
    IERC20 public immutable _shitCoin;
    uint32 public immutable _walletLimit;

    AuctionConfig public _auctionConfig;
    uint32 public _maxSupply = 8888 - 4416;
    uint32 public _minted;
    mapping(address => uint32) public _userMinted;

    constructor(address shitCoin, address shitPlunger, uint32 walletLimit) {
        _shitCoin = IERC20(shitCoin);
        _shitPlunger = IShitPlunger(shitPlunger);
        _walletLimit = walletLimit;
    }

    function mint(uint32 amount) external payable {
        require(tx.origin == msg.sender, "ShitPlungerStore: ?");
        AuctionConfig memory auctionConfig = _auctionConfig;

        require(auctionConfig.startTime != 0 &&  block.timestamp > auctionConfig.startTime, "ShitPlungerStore: Not Started");
        require(_minted + amount <= _maxSupply, "ShitPlungerStore: Exceed max supply");
        require(_userMinted[msg.sender] + amount <= _walletLimit, "ShitPlungerStore: Exceed wallet limit");

        uint32 price = internalAuctionPrice(auctionConfig);
        uint256 requiredValue = price * PRICE_MULTIPLIER * amount;
        _shitCoin.transferFrom(msg.sender, address(this), requiredValue);

        _minted += amount;
        _userMinted[msg.sender] += amount;
        _shitPlunger.mint(msg.sender, amount);
    }

    function _publicMinted() public view returns (uint32) {
        return  _minted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _minted;
    }

    function internalAuctionPrice(AuctionConfig memory config) internal view returns (uint32) {
        // [startTime, endTime)
        uint32 price;

        if (block.timestamp < config.startTime) {
            price = config.startingPrice;
        } else if (block.timestamp > config.startTime + config.duration) {
            price = config.startingPrice;
        } else {
            uint32 elapsedInterval = (uint32(block.timestamp) - config.startTime) / config.interval;
            price = config.startingPrice + elapsedInterval * config.increasePerInterval;
        }

        return price;
    }

    function _auctionPrice() public view returns (uint256) {
        return internalAuctionPrice(_auctionConfig) * PRICE_MULTIPLIER;
    }

    function _status(address minter) external view returns (Status memory) {
        uint32 publicSupply = _publicSupply();
        uint32 publicMinted = _publicMinted();

        return Status({
            // config
            priceMultiplier: PRICE_MULTIPLIER,
            maxSupply: _maxSupply,
            publicSupply: publicSupply,
            walletLimit: _walletLimit,
            startingPrice: _auctionConfig.startingPrice,
            endingPrice: _auctionConfig.endingPrice,
            startTime: _auctionConfig.startTime,
            duration: _auctionConfig.duration,
            increasePerInterval: _auctionConfig.increasePerInterval,
            interval: _auctionConfig.interval,

            // state
            publicMinted: publicMinted,
            soldout: publicMinted >= publicSupply,
            userMinted: _userMinted[minter]
        });
    }

    function setAuctionState(
        uint32 startingPrice,
        uint32 endingPrice,
        uint32 startTime,
        uint32 duration,
        uint32 interval
    ) external onlyOwner {
        require(startingPrice <= endingPrice, "ShitPlungerStore: Starting Price too low");
        require(duration % interval == 0, "ShitPlungerStore: Duration % Interval != 0");

        uint32 priceDifference = endingPrice - startingPrice;
        uint32 step = duration / interval;
        require(priceDifference % step == 0, "ShitPlungerStore: PriceDiff % Step != 0");

        _auctionConfig = AuctionConfig({
            startingPrice: startingPrice,
            endingPrice: endingPrice,
            startTime: startTime,
            duration: duration,
            interval: interval,
            increasePerInterval: priceDifference / step
        });
    }

    function withdrawFund(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            payable(msg.sender).sendValue(address(this).balance);
        } else {
            IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
        }
    }
}
