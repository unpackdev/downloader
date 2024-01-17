// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./IERC721.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Fixed price sale module
 * @notice Simple modifier that checks the value of ether and reverts if it's not what it expected
 */
abstract contract FixedPrice {
    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error IncorrectPayment(uint256 required, uint256 received);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Modifier that only allows the operator for a specific batch
     */
    modifier onlyWithCorrectPayment(uint256 paymentAmount) {
        if (msg.value != paymentAmount) revert IncorrectPayment(paymentAmount, msg.value);
        _;
    }
}
