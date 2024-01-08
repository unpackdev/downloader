// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./SafeMath.sol";

library SpaceportHelper {
    using SafeMath for uint256;
    
    function calculateAmountRequired (uint256 _amount, uint256 _tokenPrice, uint256 _listingRate, uint256 _liquidityPercent, uint256 _tokenFee) public pure returns (uint256) {
        uint256 listingRatePercent = _listingRate.mul(1000).div(_tokenPrice);
        uint256 plfiTokenFee = _amount.mul(_tokenFee).div(1000);
        uint256 amountMinusFee = _amount.sub(plfiTokenFee);
        uint256 liquidityRequired = amountMinusFee.mul(_liquidityPercent).mul(listingRatePercent).div(1000000);
        uint256 tokensRequiredForSpaceport = _amount.add(liquidityRequired).add(plfiTokenFee);
        return tokensRequiredForSpaceport;
    }
}