pragma solidity 0.6.12;
interface IPriceSafeChecker {
    //checking price ( _reserve0/_reserve1 ) to making sure  in a safe range
    function checkPrice(uint256 _reserve0, uint256 _reserve1) external view ;

     event SettingPriceRang(uint256 _minPriceNumerator, uint256 _minPriceDenominator, uint256 _maxPriceNumerator, uint256 _maxPriceDenominator);
}