// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract Token is ERC20, Ownable {
    bool public tradeOpen;

    uint256 public buyFeeRate;
    uint256 public sellFeeRate;
    address public feeTo;

    uint256 public tradeMaxAmount;

    uint256 public tradeInterval;
    mapping(address => uint256) public lastTradeTime;

    bool public blacklistEnable;
    mapping(address => bool) public blacklist;

    bool public whitelistEnable;
    mapping(address => bool) public whitelist;

    mapping(address => bool) public pairs;

    constructor() ERC20("Nothing Or Everything", "NOEO") {
        _mint(0xf55872283159D86C87D9DF536dEB98Cdeff61a81, 100000000 * 10 ** decimals());
    }

    function setTradeOpen(bool _tradeOpen) public onlyOwner {
        tradeOpen = _tradeOpen;
    }

    function setTradeFee(uint256 _buyFeeRate, uint256 _sellFeeRate, address _feeTo) public onlyOwner {
        buyFeeRate = _buyFeeRate;
        sellFeeRate = _sellFeeRate;
        feeTo = _feeTo;
    }

    function setTradeMaxAmount(uint256 _tradeMaxAmount) public onlyOwner {
        tradeMaxAmount = _tradeMaxAmount;
    }

    function setTradeInterval(uint256 _tradeInterval) public onlyOwner {
        tradeInterval = _tradeInterval;
    }

    function setBlacklistEnable(bool _blacklistEnable) public onlyOwner {
        blacklistEnable = _blacklistEnable;
    }

    function setBlackList(address user, bool state) public onlyOwner {
        blacklist[user] = state;
    }

    function setWhitelistEnable(bool _whitelistEnable) public onlyOwner {
        whitelistEnable = _whitelistEnable;
    }

    function setWhiteList(address user, bool state) public onlyOwner {
        whitelist[user] = state;
    }

    function setPair(address pair, bool state) public onlyOwner {
        pairs[pair] = state;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        if ((blacklistEnable == true && blacklist[from] == true)) revert();

        if (pairs[from] == false && pairs[to] == false) {
            super._transfer(from, to, amount);
            return;
        }

        if (tradeOpen == false) revert();

        if (tradeMaxAmount > 0 && amount > tradeMaxAmount) revert();

        if (whitelistEnable == true && whitelist[from] == false) revert();

        if (tradeInterval > 0 && block.timestamp - lastTradeTime[from] < tradeInterval) revert();

        uint256 fee;
        if (pairs[from] == true && buyFeeRate > 0) {
            fee = (amount * buyFeeRate) / 10000;
        }
        if (pairs[to] == true && sellFeeRate > 0) {
            fee = (amount * sellFeeRate) / 10000;
        }

        if (fee == 0) {
            super._transfer(from, to, amount);
        } else {
            super._transfer(from, feeTo, fee);
            super._transfer(from, to, amount - fee);
        }

        if (tradeInterval > 0) {
            lastTradeTime[from] = block.timestamp;
        }
    }
}
