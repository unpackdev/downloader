pragma solidity ^0.6.9;

import "./BetToken.sol";
import "./BetBettingLogic.sol";

contract Deathbet is BetBettingLogic, BetToken {
    constructor (
        address tokenAddress,
        uint _ticketPrice
    ) public
        BetToken(tokenAddress)
        BetBettingLogic(_ticketPrice)
    {}

    // Implements "./BetToken/BetTokenSender.sol"
    function bet (address better, uint amountSent, bytes memory betData) internal override {
    // Routs to "./Logic/BetBettingLogic"
        _bet(better, amountSent, betData);
    }
}