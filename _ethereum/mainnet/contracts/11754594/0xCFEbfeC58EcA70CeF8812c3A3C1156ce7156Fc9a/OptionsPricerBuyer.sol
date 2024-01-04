// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";

import "./IOptionsPricer.sol";
import "./IOptionsProvider.sol";
import "./IPriceProvider.sol";

contract OptionsPricerBuyer is Ownable, IOptionsPricer {
    using SafeMath for uint;

    uint public impliedVolRate = 5500;
    uint public constant PRICE_DECIMALS = 1e8;
    bool public useHegicIV = false;

    IOptionsProvider public optionsProvider;
    IPriceProvider public priceProvider;

    constructor(IPriceProvider pp, IOptionsProvider op) public {
        _setPriceProvider(pp);
        _setOptionsProvider(op);
    }

    function setImpliedVolRate(uint IVRate) external onlyOwner {
        require(IVRate > 1000, "2ndary::OptionsPricer::setImpliedVolRate::IVRate-too-low");
        impliedVolRate = IVRate;
    }

    function setUseHegicIV(bool _useHegicIV) external onlyOwner {
        useHegicIV = _useHegicIV;
    }

    function setOptionsProvider(IOptionsProvider op) external onlyOwner {
        _setOptionsProvider(op);
    }

    function setPriceProvider(IPriceProvider pp) external onlyOwner {
        _setPriceProvider(pp);
    }

    function getOptionPrice(uint tokenId) external view override returns (uint){
        (IHegicOptions.State state,
         address holder,
         uint strike,
         uint amount,
         ,
         ,
         uint expiration, 
         IHegicOptions.OptionType optionType) = optionsProvider.getUnderlyingOptionParams(tokenId);

        if(state != IHegicOptions.State.Active || expiration <= block.timestamp || optionType == IHegicOptions.OptionType.Invalid || holder != address(optionsProvider))
            return 0;

        return getOptionPriceWithParams(strike, expiration, amount, optionType);
    }

    function getOptionPriceWithParams(
        uint strike,
        uint expiration,
        uint amount,
        IHegicOptions.OptionType optionType
    ) public view override returns (uint){
        uint intrinsicValue = getIntrinsicValue(strike, amount, optionType);
        uint timeValue = getTimeValue(expiration, amount, strike, optionType);
        
        if(expiration.sub(block.timestamp) < 1 days) timeValue = 0; 
        
        return intrinsicValue.add(timeValue);
    }

    function getIntrinsicValue(uint strike, uint amount, IHegicOptions.OptionType optionType) internal view returns (uint){
        uint currentPrice = getCurrentPrice();

        if(optionType == IHegicOptions.OptionType.Call && currentPrice > strike){
            return currentPrice.sub(strike).mul(amount).div(currentPrice);
        } else if (optionType == IHegicOptions.OptionType.Put && currentPrice < strike)
            return strike.sub(currentPrice).mul(amount).div(currentPrice);
    
        return 0;
    }

    function getTimeValue(uint expiration, uint amount, uint strike, IHegicOptions.OptionType optionType) internal view returns (uint){
        uint currentPrice = getCurrentPrice();
        uint period = expiration.sub(block.timestamp);

        if(optionType == IHegicOptions.OptionType.Put)
            return amount
                .mul(sqrt(period))
                .mul(_impliedVolRate())
                .mul(strike)
                .div(currentPrice)
                .div(PRICE_DECIMALS);
        else if (optionType == IHegicOptions.OptionType.Call)
            return amount
                .mul(sqrt(period))
                .mul(_impliedVolRate())
                .mul(currentPrice)
                .div(strike)
                .div(PRICE_DECIMALS);
        
        return 0;   
    }

    function _impliedVolRate() internal view returns (uint currentIVRate) {
        if(useHegicIV){
            IHegicOptions hegic = optionsProvider.optionsProvider();
            currentIVRate = hegic.impliedVolRate();
        } else {
            currentIVRate = impliedVolRate;
        }
    }

    function getCurrentPrice() internal view returns (uint currentPrice) {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        currentPrice = uint(latestPrice);
    }

    function _setPriceProvider(IPriceProvider pp) internal {
        priceProvider = pp;
    }

    function _setOptionsProvider(IOptionsProvider op) internal {
        optionsProvider = op;
    }

    /**
     * @return result Square root of the number
     */
    function sqrt(uint256 x) private pure returns (uint256 result) {
        result = x;
        uint256 k = x.div(2).add(1);
        while (k < result) (result, k) = (k, x.div(k).add(k).div(2));
    }
}