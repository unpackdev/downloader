// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";

import "./IOptionsBuyer.sol";
import "./IOptionsManager.sol";
import "./IOptionsPricer.sol";
import "./IOptionsProvider.sol";
import "./ICapitalManager.sol";

contract OptionsBuyer is IOptionsBuyer, Ownable {
    using SafeMath for uint;

    IOptionsManager public optionsManager;
    IOptionsPricer public optionsPricer;
    IOptionsProvider public optionsProvider;
    ICapitalManager public capitalManager;

    constructor(IOptionsManager om, IOptionsPricer oPricer, IOptionsProvider oProvider, ICapitalManager cm) public {
        _setOptionsManager(om);
        _setOptionsPricer(oPricer);
        _setOptionsProvider(oProvider);
        _setCapitalManager(cm);
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

    function sellOption(uint tokenId) external override {        
        (IHegicOptions.State state,
         address holder,
         uint strike,
         uint amount,
         ,
         ,
         uint expiration, 
         IHegicOptions.OptionType optionType) = optionsProvider.getUnderlyingOptionParams(tokenId);
        
        require(holder == address(optionsProvider), "2ndary::sellOption::invalid-option");
        require(state == IHegicOptions.State.Active, "2ndary::sellOption::option-not-active");
        require(expiration > block.timestamp, "2ndary::sellOption::option-expired");
        
        uint premium = getOptionPriceWithParams(strike, expiration, amount, optionType);
        
        optionsManager.depositOption(msg.sender, tokenId, premium);
        
        _payOption(msg.sender, premium);

        emit BuyOption(msg.sender, tokenId, strike, expiration, amount, optionType, premium);
    }

    function getOptionPrice(uint tokenId) external view override returns (uint) {
        ICapitalManager cp = capitalManager;
        return optionsPricer.getOptionPrice(tokenId).mul(cp.BASE().sub(cp.feeRate())).div(cp.BASE());
    }

    function getOptionPriceWithParams(
        uint strike,
        uint expiration,
        uint amount,
        IHegicOptions.OptionType optionType
    ) internal view returns (uint){
        return optionsPricer.getOptionPriceWithParams(strike, expiration, amount, optionType);
    }

    function _payOption(address receiver, uint premium) internal {
        capitalManager.payOption(receiver, premium);
    }

    function _setOptionsManager(IOptionsManager om) internal {
        optionsManager = om;
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
}