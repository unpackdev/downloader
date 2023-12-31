// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract TipHostProxy {

	event PaymentSuccessful(
		address payable indexed from_,
		address payable indexed to_,
		uint256 amount_
	);

	constructor() {}

	function payHost(address payable receiver_) payable public {
		require(
			receiver_ != address(0x0),
			"Expected a valid host address.");

		uint256 amount_ = msg.value;

		require(
			amount_ > 0,
			"Send some tokens to make a transaction.");

		receiver_.transfer(amount_);

		emit PaymentSuccessful(msg.sender, receiver_, amount_);
	}
}