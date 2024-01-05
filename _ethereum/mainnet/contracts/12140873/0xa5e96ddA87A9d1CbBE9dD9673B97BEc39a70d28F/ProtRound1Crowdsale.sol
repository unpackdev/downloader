// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";
import "./Ownable.sol";

contract ProtRound1Crowdsale is Ownable, Crowdsale, TimedCrowdsale  {
    using SafeMath for uint256;

    mapping(address => uint256) private _contributions;
    mapping(address => uint256) private _ethContributions;

    uint256 private _maxTxValuePerUser;
    uint256 private _ethPrice;
    uint256 private _cap;
    uint256 private _tokensAllocated;

    constructor (
        uint256 rate,
        address payable wallet,
        IERC20 token,
        uint256 openingTime,
        uint256 closingTime,
        uint256 cap,
        uint256 ethPrice,
        uint256 maxTxValuePerUser
    ) public 
        Crowdsale( rate, wallet, token )
        TimedCrowdsale( openingTime, closingTime )
    {
        require( ethPrice != 0, "Invalid Eth Price");
        require( maxTxValuePerUser != 0, "Invalid User Cap");
        require( cap != 0, "Invalid Cap");
        _ethPrice = ethPrice;
        _maxTxValuePerUser = maxTxValuePerUser;
        _cap = cap;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function ethPrice() public view returns (uint256) {
        return _ethPrice;
    }

    function maxTxValuePerUser() public view returns (uint256) {
        return _maxTxValuePerUser;
    }

    function tokensAllocated() public view returns (uint256) {
        return _tokensAllocated;
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 tokens = (_ethPrice.mul(weiAmount).mul(100)).div(super.rate());
        require(_tokensAllocated.add(tokens) <= _cap, "Funding Goal Reached");
        return tokens;
    }

    function setEthPrice(uint256 newEthPrice) public onlyOwner {
        require( newEthPrice != 0, "Invalid Eth Price");
        _ethPrice = newEthPrice;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase( beneficiary, weiAmount);
        require(_ethContributions[beneficiary].add(weiAmount) <= _maxTxValuePerUser, "PROTIndividuallyCappedCrowdsale: beneficiary's cap exceeded");
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        _ethContributions[beneficiary] = _ethContributions[beneficiary].add(weiAmount);
    }

    // solhint-disable-next-line
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _contributions[beneficiary] = _contributions[beneficiary].add(tokenAmount);
        _tokensAllocated = _tokensAllocated.add(tokenAmount);
    }

    function getUserContribution(address beneficiary) public view returns (uint256) {
        return _contributions[beneficiary];
    }
}