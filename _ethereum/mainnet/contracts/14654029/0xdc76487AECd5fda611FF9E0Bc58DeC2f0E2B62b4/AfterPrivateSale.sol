// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AllowanceCrowdsale.sol";

/// @custom:security-contact security@after.fund
contract AfterPrivateSale is AllowanceCrowdsale {
    constructor(
        uint256 rate_,
        address payable wallet_,
        IERC20 token_,
        address tokenWallet_
    )
        AllowanceCrowdsale(rate_, wallet_, token_, tokenWallet_)
    {
        // solhint-disable-previous-line no-empty-blocks
    }
}