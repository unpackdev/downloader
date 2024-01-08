// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./IAdapter.sol";

abstract contract AdapterBase is IAdapter {
    using SafeMath for uint256;

    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function getTotalWrappedTokenAmountCore()
        internal
        view
        virtual
        returns (uint256);

    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function getWrappedTokenPriceInUnderlyingCore()
        internal
        view
        virtual
        returns (uint256);

    function getRedeemableUnderlyingTokensForCore(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 price = getWrappedTokenPriceInUnderlyingCore();

        return amount.mul(price).div(10**18);
    }

    function getWrappedTokenPriceInUnderlying()
        external
        view
        override
        returns (uint256)
    {
        return getWrappedTokenPriceInUnderlyingCore();
    }

    function getRedeemableUnderlyingTokensFor(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        return getRedeemableUnderlyingTokensForCore(amount);
    }

    function getTotalRedeemableUnderlyingTokens()
        external
        view
        override
        returns (uint256)
    {
        uint256 totalWrappedTokenAmount = getTotalWrappedTokenAmountCore();

        return getRedeemableUnderlyingTokensForCore(totalWrappedTokenAmount);
    }
}
