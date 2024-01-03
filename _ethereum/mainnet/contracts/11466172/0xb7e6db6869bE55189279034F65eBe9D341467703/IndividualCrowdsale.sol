// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Crowdsale.sol";

/**
 * Track individual contributions and enforce the cap per address.
 */
contract IndividualCrowdsale is Crowdsale {
    using SafeMath for uint256;

    mapping(address => uint256) private _contributions;
    uint public contributorsCount;

    uint256 public individualCap = 50e18;

    function getContribution(address beneficiary) public view returns (uint256) {
        return _contributions[beneficiary];
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        super._updatePurchasingState(beneficiary, weiAmount);

        if (_contributions[beneficiary] == 0) {
            contributorsCount += 1;
        }

        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);

        require(_contributions[beneficiary] < individualCap, "IndividualCrowdsale: contributions cap is reached");
    }
}
