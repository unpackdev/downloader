// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";

import "./IOptionsPricer.sol";
import "./IOptionsProvider.sol";
import "./ICapitalManager.sol";
import "./IOptionsManager.sol";
import "./IOptionsPool.sol";
import "./IOptionsSeller.sol";

contract OptionsSeller is IOptionsSeller, Ownable {
    using SafeMath for uint;

    IOptionsPricer public optionsPricer;
    IOptionsProvider public optionsProvider;
    ICapitalManager public capitalManager;
    IOptionsManager public optionsManager; 
    IOptionsPool public optionsPool;
    
    constructor(IOptionsPricer oPricer, IOptionsProvider oProvider, ICapitalManager cm, IOptionsPool oPool, IOptionsManager om) public {
        _setOptionsPricer(oPricer);
        _setOptionsProvider(oProvider);
        _setCapitalManager(cm);
        _setOptionsPool(oPool);
        _setOptionsManager(om);
    }

    function updateOptionPricer(IOptionsPricer op) external onlyOwner {
        _setOptionsPricer(op);
    }

    function setOptionsManager(IOptionsManager om) external onlyOwner {
        _setOptionsManager(om);
    }

    function setCapitalManager(ICapitalManager cm) external onlyOwner {
        _setCapitalManager(cm);
    }

    function setOptionsProvider(IOptionsProvider oProvider) external onlyOwner {
        _setOptionsProvider(oProvider);
    }

    function setOptionsPool(IOptionsPool oPool) external onlyOwner {
        _setOptionsPool(oPool);
    }

    function buyOption(uint tokenId) external payable override {
        (IHegicOptions.State state,
         ,
         uint strike,
         uint amount,
         ,
         ,
         uint expiration, 
         IHegicOptions.OptionType optionType) = optionsProvider.getUnderlyingOptionParams(tokenId);
        require(state == IHegicOptions.State.Active, "2ndary::buyOption::option-not-active");
        require(expiration > block.timestamp, "2ndary::buyOption::option-expired");

        uint price = getOptionPriceWithParams(strike, expiration, amount, optionType);

        _sendPayment(msg.sender, price, tokenId);

        optionsManager.withdrawOption(msg.sender, tokenId);

        emit SellOption(msg.sender, tokenId, strike, expiration, amount, optionType, price);
    }

    function getOptionPrice(uint tokenId) external view override returns (uint) {
        ICapitalManager cp = capitalManager;
        return optionsPricer.getOptionPrice(tokenId).mul(cp.BASE().add(cp.feeRate())).div(cp.BASE());
    }

    function getOptionPriceWithParams(uint strike, uint expiration, uint amount, IHegicOptions.OptionType optionType) public view returns (uint) {
        return optionsPricer.getOptionPriceWithParams(strike, expiration, amount, optionType);
    }

    function _sendPayment(address from, uint amount, uint tokenId) internal {
        uint paidPremium = optionsPool.paidPremiums(tokenId);
        capitalManager.receivePayout {value: msg.value}(from, tokenId, paidPremium, amount, true);
    }

    function _setOptionsPricer(IOptionsPricer op) internal {
        optionsPricer = op;
    }

    function _setOptionsProvider(IOptionsProvider op) internal {
        optionsProvider = op;
    }

    function _setCapitalManager(ICapitalManager cm) internal {
        capitalManager = cm;
    }    

    function _setOptionsPool(IOptionsPool op) internal {
        optionsPool = op;
    }    
    
    function _setOptionsManager(IOptionsManager om) internal {
        optionsManager = om;
    }
}