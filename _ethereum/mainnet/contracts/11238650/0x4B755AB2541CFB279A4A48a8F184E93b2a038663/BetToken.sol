pragma solidity ^0.6.9;

import "./BetTokenHolder.sol";
import "./BetTokenRecipient.sol";
import "./BetTokenSender.sol";

abstract contract BetToken is BetTokenHolder, BetTokenSender, BetTokenRecipient {
    constructor (
        address tokenAddress
    ) public BetTokenHolder(tokenAddress) {}
}