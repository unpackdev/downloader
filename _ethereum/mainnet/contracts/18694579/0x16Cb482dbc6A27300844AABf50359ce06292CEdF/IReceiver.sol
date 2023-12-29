// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReceiver {
	function distribute(uint amount) external;
}
