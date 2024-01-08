// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

interface IBridge {
	function activeOutbox() external view returns (address);
}
