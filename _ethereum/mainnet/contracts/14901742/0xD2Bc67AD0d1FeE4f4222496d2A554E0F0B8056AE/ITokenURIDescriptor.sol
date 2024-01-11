// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import "./ISTokenManagerStruct.sol";

interface ITokenURIDescriptor {
	/*
	 * @dev get image from custom descriopro
	 * @param _tokenId token id
	 * @param _owner owner address
	 * @param _positions staking position
	 * @param _rewards rewards
	 * @return string image information
	 */
	function image(
		uint256 _tokenId,
		address _owner,
		ISTokenManagerStruct.StakingPositionV1 memory _positions,
		ISTokenManagerStruct.RewardsV1 memory _rewards
	) external view returns (string memory);
}
