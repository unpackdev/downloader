// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";

contract BlazingPepeRewardsDeployer {
    using SafeMath for uint256;

    function batchTransferTokens(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory amounts
    ) public {
        require(recipients.length == amounts.length, "Mismatched arrays");

        IERC20 token = IERC20(tokenAddress);

        uint256 totalAmount = 0;
        for (uint i = 0; i < recipients.length; i++) {
            totalAmount = totalAmount.add(amounts[i]);
        }

        require(token.transferFrom(msg.sender, address(this), totalAmount), "Transfer to contract failed");

        for (uint i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amounts[i]), "Transfer to recipient failed");
        }
    }
}
