// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IRateProvider.sol";
import "./Holder.sol";
import "./IToken.sol";
import "./IBull20.sol";
import "./Stage.sol";
import "./Proxy.sol";

contract Bull20 is IBull20, Proxy {
    event Airdrop(address indexed wallet, uint256 amount);
    event Purchase(address indexed wallet, uint256 cost, address token, uint256 amount);
    event Received(address, uint256);

    bool private _enabled = false;
    IRateProvider private _rateProvider;
    Stage[] private _stages;
    // wallet->stage->balance
    mapping(address => mapping(uint => uint256)) private _presale;
    address[] private _holders;

    constructor(address proxy_) payable Proxy(proxy_) {}

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function holders() external view onlyFromProxy returns (address[] memory) {
        return _holders;
    }

    function enabled() external view onlyFromProxy returns (bool) {
        return _enabled;
    }

    function rateProvider() external view onlyFromProxy returns (IRateProvider) {
        return _rateProvider;
    }

    function stages() public view onlyFromProxy returns (Stage[] memory) {
        return _stages;
    }

    function activeStage() public view onlyFromProxy returns (Stage memory) {
        Stage[] memory cachedStages = _stages;
        uint256 stagesLength = cachedStages.length;

        require(stagesLength != 0, "Stages are not set up");

        for (uint i = 0; i < stagesLength; ++i) {
            if (cachedStages[i].expectedValue > cachedStages[i].raisedValue) {
                return cachedStages[i];
            }
        }

        return cachedStages[cachedStages.length - 1];
    }

    function totalRaised() external view onlyFromProxy returns (uint256) {
        uint256 total = 0;
        Stage[] memory cachedStages = _stages;
        uint256 stagesLength = cachedStages.length;

        for (uint i = 0; i < stagesLength; ++i) {
            total += cachedStages[i].raisedValue;
            if (cachedStages[i].expectedValue > cachedStages[i].raisedValue) {
                break;
            }
        }

        return total;
    }

    function presaleAmount(address _wallet) external view onlyFromProxy returns (uint256) {
        uint256 amount = 0;
        uint256 stagesLength = _stages.length;

        for (uint i = 0; i < stagesLength; ++i) {
            amount += _presale[_wallet][i];
        }

        return amount;
    }

    function buy(uint256 amount, address token, uint256 msgValue, address msgSender) external payable onlyFromProxy {
        require(amount != 0, "Amount should be > 0");
        uint256 costUSD = activeStage().price * amount;
        uint256 value = _rateProvider.getAmountForUSD(token, costUSD);

        emit Purchase(
            msgSender,
            value,
            token,
            amount
        );

        // If native currency
        if (token == address(0x0)) {
            require(msgValue == value, "Incorrect amount");
            _airdrop(msgSender, amount, costUSD);
        } else {
            require(msgValue == 0, "Value should be 0");
            _airdrop(msgSender, amount, costUSD);
            bool success = IToken(token).transferFrom(msgSender, address(this), value);
            require(success, "Buy failed");
        }
    }

    function disable() external onlyFromProxy {
        _enabled = false;
    }

    function enable() external onlyFromProxy {
        _enabled = true;
    }

    function setRateProvider(address rateProvider_) public onlyFromProxy {
        require(rateProvider_.code.length != 0, "Invalid contract");
        _rateProvider = IRateProvider(rateProvider_);
    }

    function addStages(uint256[] memory prices, uint256[] memory expectedValues) external onlyFromProxy {
        uint256 pricesLength = prices.length;
        require(pricesLength == expectedValues.length, "prices.length != expectedValues.length");

        for (uint i = 0; i < pricesLength; ++i) {
            _addStage(prices[i], expectedValues[i]);
        }
    }

    function addStage(uint256 priceUSD, uint256 expectedValue) external onlyFromProxy returns (Stage memory) {
        return _addStage(priceUSD, expectedValue);
    }

    function editStage(uint index, uint256 price, uint256 expectedValue) external onlyFromProxy returns (Stage memory) {
        Stage memory currentStage = activeStage();
        require((index + 1) > currentStage.index, "Editing previous stage");

        Stage memory stage = Stage(index, price, expectedValue, _stages[index].raisedValue);
        _stages[index] = stage;
        return stage;
    }

    function deleteLastStage() external onlyFromProxy {
        Stage memory currentStage = activeStage();
        require(currentStage.index < _stages.length, "Can not delete active stage");
        _stages.pop();
    }

    function airdrop(address wallet, uint256 amount) external onlyFromProxy {
        uint256 costUSD = activeStage().price * amount;
        _airdrop(wallet, amount, costUSD);
    }

    function airdropMany(address[] memory wallets, uint256[] memory amounts) external onlyFromProxy {
        uint256 walletsLength = wallets.length;
        require(walletsLength == amounts.length, "wallets.length != amounts.length");

        for (uint i = 0; i < walletsLength; ++i) {
            uint256 costUSD = activeStage().price * amounts[i];
            _airdrop(wallets[i], amounts[i], costUSD);
        }
    }

    function withdraw(address holder) external onlyFromProxy payable {
        address[] memory tokens = _rateProvider.tokens();
        uint256 tokensLength = tokens.length;

        for (uint i = 0; i < tokensLength; ++i) {
            if (tokens[i] == address(0x0)) {
                continue;
            }

            IToken erc20 = IToken(tokens[i]);
            bool success = erc20.transfer(holder, erc20.balanceOf(address(this)));
            require(success, "Withdraw failed");
        }

        if (address(this).balance != 0) {
            payable(holder).transfer(address(this).balance);
        }
    }

    function _addStage(uint256 priceUSD, uint256 expectedValue) private returns (Stage memory) {
        require(priceUSD != 0, "Price should be > 0");
        require(expectedValue != 0, "Expected value should be > 0");

        Stage memory stage = Stage(_stages.length, priceUSD, expectedValue, 0);
        _stages.push(stage);
        return stage;
    }

    function _airdrop(address wallet, uint256 amount, uint256 costUSD) private {
        require(_enabled, "Contract should be enabled");
        require(amount != 0, "Amount should be > 0");
        Stage memory currentStage = activeStage();
        _stages[currentStage.index].raisedValue += costUSD;
        _presale[wallet][currentStage.index] += amount;

        emit Airdrop(wallet, amount);
        address[] memory cachedHolders = _holders;
        uint256 holdersLength = cachedHolders.length;

        for (uint i = 0; i < holdersLength; ++i) {
            if (cachedHolders[i] == wallet) {
                return;
            }
        }

        _holders.push(wallet);
    }
}