// SPDX-License-Identifier: MIT
pragma solidity ^0.5.14;

import "./Crowdsale.sol";
import "./CappedCrowdsale.sol";
import "./SafeMath.sol";

contract TokenCrowdsale is Crowdsale, CappedCrowdsale {
    using SafeMath for uint256;
    address public _owner;
    bool public _finalized;
    mapping(address => uint256) private _balances;

    event CrowdsaleFinalized();

    modifier ownerOnly {
        require(msg.sender == _owner, "Action not permitted");
        _;
    }

    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
        uint256 cap
    ) public CappedCrowdsale(cap) Crowdsale(rate, wallet, token) {
        _finalized = false;
        _owner = 0x4cC8310479aCd5C8b6E6693A49B028Ec97899F38;
    }

    function finalize() public ownerOnly {
        require(!_finalized, "Already finalized");
        _finalized = true;
        emit CrowdsaleFinalized();
    }

    function withdrawTokens(address beneficiary) public {
        require(_finalized, "Crowdsale not finalized");
        uint256 amount = _balances[beneficiary];
        require(amount > 0, "Beneficiary is not due any tokens");
        _balances[beneficiary] = 0;
        // _deliverTokens(beneficiary, amount);
        token().transfer(beneficiary, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(!_finalized, "Crowdsale not open");
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
    {
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    }
}
