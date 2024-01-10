// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IPayment.sol";
import "./LibDiamond.sol";
import "./LibPayment.sol";

contract PaymentFacet is IPayment {
    /// @notice Adds/removes a payment token
    /// @param _token The target token
    /// @param _status Whether the token will be added or removed
    function setPaymentToken(address _token, bool _status) external override {
        require(_token != address(0), "PaymentFacet: _token must not be 0x0");
        LibDiamond.enforceIsContractOwner();
        LibPayment.updatePaymentToken(_token, _status);

        emit SetPaymentToken(_token, _status);
    }

    /// @notice Gets whether the payment token is supported
    /// @param _token The target token
    function supportsPaymentToken(address _token)
        external
        view
        override
        returns (bool)
    {
        return LibPayment.containsPaymentToken(_token);
    }

    /// @notice Gets the total amount of token payments
    function totalPaymentTokens() external view override returns (uint256) {
        return LibPayment.tokensCount();
    }

    /// @notice Gets the payment token at a given index
    /// @param _index The token index
    function paymentTokenAt(uint256 _index)
        external
        view
        override
        returns (address)
    {
        return LibPayment.tokenAt(_index);
    }
}
