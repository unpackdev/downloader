// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./PullPayment.sol";
import "./SafeMath.sol";
import "./IPayments.sol";

/**
 * @title Payments contract for SuperRare Marketplaces.
 */
contract Payments is IPayments, PullPayment {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // refund
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to refund an address. Typically for canceled bids or offers.
     * Requirements:
     *
     *  - _payee cannot be the zero address
     *
     * @param _amount uint256 value to be split.
     * @param _payee address seller of the token.
     */
    function refund(address _payee, uint256 _amount) external payable override {
        require(
            _payee != address(0),
            "refund::no payees can be the zero address"
        );

        require(msg.value == _amount);

        if (_amount > 0) {
            (bool success, ) = address(_payee).call{value: _amount}("");

            if (!success) {
                _asyncTransfer(_payee, _amount);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // payout
    /////////////////////////////////////////////////////////////////////////
    function payout(address[] calldata _splits, uint256[] calldata _amounts)
        external
        payable
        override
    {
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _splits.length; i++) {
            totalAmount = totalAmount.add(_amounts[i]);
            if (_splits[i] != address(0)) {
                (bool success, ) = address(_splits[i]).call{value: _amounts[i]}(
                    ""
                );

                if (!success) {
                    _asyncTransfer(_splits[i], _amounts[i]);
                }
            }
        }

        require(msg.value == totalAmount, "payout::not enough sent");
    }
}
