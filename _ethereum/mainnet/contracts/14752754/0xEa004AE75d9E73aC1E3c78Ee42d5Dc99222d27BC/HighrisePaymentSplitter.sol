// SPDX-License-Identifier: SPDX-License
/// @author aboltc
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./PaymentSplitter.sol";

// hytha 0xb79C26FAFaaFEB2835FF175d025Db1b9DEEEDF5E -> 55
// mark 0x57F85eFaD59c5DEab19479F2970C9D333a18045f -> 20
// aboltc 0x35FB16Db88Bd1A37EFe58E4A936456c15065f713 -> 25

contract HighrisePaymentSplitter is Ownable, PaymentSplitter {
	constructor(address[] memory _payees, uint256[] memory _shares)
		payable
		PaymentSplitter(_payees, _shares)
	{}
}
