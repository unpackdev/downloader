// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface iNFT {
	function getMintingRate(address _address) external view returns(uint256);
}