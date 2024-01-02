// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DiamondCollection.sol";
import "./LockerRoom.sol";
import "./Ownable.sol";

contract RulesetManager is Ownable {
	mapping(address => mapping(uint256 => mapping(address => uint256))) private lastMintTime;
	mapping(address => address[]) private allowedTokens;
	address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	uint256 public halfwayPoint;
	uint256 public mintAmountLimit;

	constructor() {
		halfwayPoint = 1700948507;
		mintAmountLimit = 21;
	}

	function addAllowedToken(address collectionAddress, address tokenAddress) external onlyOwner {
		allowedTokens[collectionAddress].push(tokenAddress);
	}

	function setMintingTimes(uint256 _halfwayPoint) external onlyOwner {
		halfwayPoint = _halfwayPoint;
	}

	function setMintAmountLimit(uint256 _mintAmountLimit) external onlyOwner {
		mintAmountLimit = _mintAmountLimit;
	}

	function checkRuleset(
		address minter,
		address receiver,
		address collectionAddress,
		address lockerRoomAddress,
		uint256 amount,
		uint256 tokenId
	) external returns (bool) {
		DiamondCollection dc = DiamondCollection(collectionAddress);
		uint256 blueprintId = dc.getBlueprintId(tokenId);
		(, , uint256 maxSupply, , , uint256 minted, uint256 rulesetId, ) = dc.getBlueprint(blueprintId);

		if (isSpecialRuleset(rulesetId)) {
			(, uint256 ruleId) = getIdsFromRuleset(rulesetId);
			rulesetId = ruleId;
		}

		if (rulesetId == 0) {
			return true;
		}

		if (rulesetId == 1) {
			// Check if both minter and receiver have not minted/received this specific tokenId within the required wait time
			if (block.timestamp < halfwayPoint + 1 hours) {
				require(
					block.timestamp >= lastMintTime[collectionAddress][tokenId][minter] + 13 hours &&
					block.timestamp >= lastMintTime[collectionAddress][tokenId][receiver] + 13 hours,
					"Minting limited to 1 each 13 hours."
				);
			}

			// Limit to 1 mint per address
			require(amount <= mintAmountLimit, "Max minting amount reached.");

			// Check if the supply has reached the halfway point, if so check if the second minting time has been reached
			if (minted > (maxSupply / 2)) {
				require(
					block.timestamp >= halfwayPoint,
					"Second minting time not reached yet."
				);
			}

			lastMintTime[collectionAddress][tokenId][minter] = block.timestamp;
			lastMintTime[collectionAddress][tokenId][receiver] = block.timestamp;

			return true;
		}

		return true;
	}

	function getTokenAddressFromRuleset(address collectionAddress, address tokenAddress, uint256 blueprintId) external view returns (address) {
		(, , , , , , uint256 rulesetId, ) = DiamondCollection(collectionAddress).getBlueprint(blueprintId);
		if (isSpecialRuleset(rulesetId)) {
			(uint256 tokenId,) = getIdsFromRuleset(rulesetId);
			if (tokenId == 0) {
				return WETH;
			}
			return allowedTokens[collectionAddress][tokenId-1];
		}
		return tokenAddress;
	}

	function isSpecialRuleset(uint256 rulesetId) internal pure returns (bool) {
		return rulesetId >= 420000;
	}

	function getIdsFromRuleset(uint256 rulesetId) public pure returns (uint256 tokenId, uint256 ruleId) {
		require(isSpecialRuleset(rulesetId), "Not a special ruleset");

		uint256 originalRulesetId = rulesetId;
		uint256 divider = 10;

		// Strip away ruleId
		while (rulesetId > 0) {
				uint256 digit = rulesetId % 10;
				if (digit == 0 && (rulesetId != originalRulesetId)) {
					rulesetId /= 10;
					break;
				}
				rulesetId /= 10;
				divider *= 10;
		}
		ruleId = originalRulesetId % (divider);
		divider = 10;
		uint256 newRulesetId = rulesetId;

		while (rulesetId >= 10000) {
				rulesetId /= 10;
				divider *= 10;
		}
		tokenId = newRulesetId % divider;

		return (tokenId, ruleId);
	}
}
