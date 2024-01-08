//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";
import "./IERC20.sol";

contract Airdrop {

    function payout (address _payoutToken, address[] calldata _receivers, uint[] calldata _amounts) public {
        require (_payoutToken != address (0), "invalid payout token");
        require (_receivers.length > 0, "no receivers");
        require (_receivers.length == _amounts.length, "invalid input");
        IERC20 payoutToken = IERC20(_payoutToken);
        uint totalAmount;
        for (uint i=0; i<_amounts.length; i++) {
            totalAmount+=_amounts[i];
        }

//        require (payoutToken.allowance(msg.sender, address (this)) >= totalAmount, "insuficient allowance");

        for (uint i=0; i<_receivers.length; i++) {
            payoutToken.transferFrom(msg.sender, _receivers[i], _amounts[i]);
        }
    }

}
