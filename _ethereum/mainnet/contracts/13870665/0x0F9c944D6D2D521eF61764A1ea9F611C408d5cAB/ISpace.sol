// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAtopia.sol";

struct Task {
	uint256 id;
	uint256 info;
	uint256 rewards;
}

interface ISpace {
	function atopia() external view returns (IAtopia);

	function ownerOf(uint256 tokenId) external view returns (address);

	function lives(uint256 tokenId) external view returns (uint256);

	function tasks(uint256 id) external view returns (Task memory);

	function claimBucks(uint256 centerId, uint256 amount) external;
}
