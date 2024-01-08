// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./DigiAvatar.sol";

contract DigiAvatarTest is
	DigiAvatar
{
	// Only development env.
	function setStartTime(uint256 _starttime) external onlyOwner {
		publicMintStartTime = _starttime;
	}
}
