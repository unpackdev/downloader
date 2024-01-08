//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";

import "./Token.sol";

contract PaymentRecipient is ContextUpgradeable {
    event ReceivedEther(address indexed sender, uint256 amount);

    /**
     * @dev Receive Ether and generate a log event
     */
    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }
}
