// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./SafeMath.sol";

/**
 * @title IndividuallyCappedCrowdsaleHelper
 * @author Enjinstarter
 * @dev Helper for crowdsale with per beneficiary cap.
 */
contract IndividuallyCappedCrowdsaleHelper {
    using SafeMath for uint256;

    mapping(address => uint256) private _tokensPurchased;
    uint256 private _tokenCap;

    /**
     * @param tokenCap cap limit in wei for each benificiary
     */
    constructor(uint256 tokenCap) {
        require(tokenCap > 0, "IndividuallyCappedCrowdsaleHelper: zero cap");
        _tokenCap = tokenCap;
    }

    modifier beneficiaryCapNotExceeded(
        address beneficiary,
        uint256 tokenAmount
    ) {
        require(
            _tokensPurchased[beneficiary].add(tokenAmount) <= _tokenCap,
            "IndividuallyCappedCrowdsaleHelper: beneficiary cap exceeded"
        );
        _;
    }

    /**
     * @return tokenCap Cap for beneficiary in wei
     */
    function getBeneficiaryCap() public view returns (uint256 tokenCap) {
        tokenCap = _tokenCap;
    }

    /**
     * @dev Returns the amount of tokens purchased so far by specific beneficiary.
     * @param beneficiary Address of contributor
     * @return tokensPurchased Tokens purchased by beneficiary so far in wei
     */
    function getTokensPurchasedBy(address beneficiary)
        public
        view
        returns (uint256 tokensPurchased)
    {
        require(
            beneficiary != address(0),
            "IndividuallyCappedCrowdsale: zero beneficiary address"
        );

        tokensPurchased = _tokensPurchased[beneficiary];
    }

    /**
     * @param beneficiary Address of contributor
     * @param tokenAmount Amount in wei of token being purchased
     */
    function _updateBeneficiaryTokensPurchased(
        address beneficiary,
        uint256 tokenAmount
    ) internal {
        _tokensPurchased[beneficiary] = _tokensPurchased[beneficiary].add(
            tokenAmount
        );
    }

    /**
     * @return availableTokens Available number of tokens for purchase by beneficiary
     */
    function _getAvailableTokensFor(address beneficiary)
        internal
        view
        returns (uint256 availableTokens)
    {
        availableTokens = getBeneficiaryCap().sub(
            getTokensPurchasedBy(beneficiary)
        );
    }
}
