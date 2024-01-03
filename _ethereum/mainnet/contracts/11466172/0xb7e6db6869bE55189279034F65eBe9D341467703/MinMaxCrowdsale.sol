// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Crowdsale.sol";
import "./Ownable.sol";
import "./WhitelistAdminRole.sol";

contract MinMaxCrowdsale is Crowdsale, WhitelistAdminRole {
    using SafeMath for uint256;

    // Min-max contribution limits: 0.02 and 50
    uint256 private _minContribution = 1e17;
    uint256 private _maxContribution = 10e18;

    function getContributionLimits() public view returns (uint256, uint256) {
        return (_minContribution, _maxContribution);
    }

    function setMinContribution(uint256 min) public onlyWhitelistAdmin {
        require(min > 0, 'MinMaxCrowdsale: min is 0');
        require(_maxContribution > min, 'MinMaxCrowdsale: max is less than min');
        _minContribution = min;
    }

    function setMaxContribution(uint256 max) public onlyWhitelistAdmin {
        require(max > 0, 'MinMaxCrowdsale: max is 0');
        require(max > _minContribution, 'MinMaxCrowdsale: max is less than min');
        _maxContribution = max;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiAmount >= _minContribution, "MinMaxCrowdsale: weiAmount is less than allowed minimum");
        require(weiAmount <= _maxContribution, "MinMaxCrowdsale: weiAmount is bigger than allowed maximum");
    }
}
