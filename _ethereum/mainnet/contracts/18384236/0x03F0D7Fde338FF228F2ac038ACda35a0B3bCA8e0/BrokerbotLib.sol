// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IBrokerbot.sol";
import "./PaymentHub.sol";
import "./BrokerbotRegistry.sol";

library BrokerbotLib {

	error Brokerbot_Not_Found();  
	function getBrokerbotAndPaymentHub(BrokerbotRegistry brokerbotRegistry, IERC20 base, IERC20 token) internal view returns (IBrokerbot brokerbot, PaymentHub paymentHub) {
		brokerbot = brokerbotRegistry.getBrokerbot(base, token);
		if (address(brokerbot) == address(0)) revert Brokerbot_Not_Found();
		paymentHub = PaymentHub(payable(brokerbot.paymenthub()));
	}
}