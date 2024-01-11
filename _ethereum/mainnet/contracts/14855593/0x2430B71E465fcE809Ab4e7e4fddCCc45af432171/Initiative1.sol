// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MentalHealthCoalition.sol";

/// @title Initiative1
/// Initial mint for The Mental Health Coalition
contract Initiative1 is Ownable {

	/// Indicates that an invalid amount of tokens to mint was provided
	error InvalidAmount();

	/// Indicates that an invalid sum of ETH was provided during mint
	error InvalidPrice();

	/// Indicates that there are no more tokens in this sale to be minted
	error SoldOut();

	/// Maximum quantity of tokens that can be minted at once
	uint256 public constant MAX_MINT_QUANTITY = 10;

	/// The per-token mint price
	uint256 public constant MINT_PRICE = 0.05 ether;

	/// The total number of tokens that will be minted in this sale
	uint256 public constant MAX_MINT = 500;

	/// @dev Reference to the MentalHealthCoalition ERC-1155 contract
	MentalHealthCoalition private immutable _mentalHealthCoalition;

	/// @dev The number of tokens currently minted by this contract
	uint256 private _minted;

	/// @dev The recipient of the raised funds
	address payable private immutable _recipient;

	/// @dev A seed used in selected specific token ids for mint
	uint256 private _seed;

	/// Constructs the `Initiative1` minting contract
	/// @param mentalHealthCoalition The address of the `MentalHealthCoalition` ERC-1155 contract
	/// @param recipient The recipient of the raised funds
	/// @param seed The initial seed used for token selection
	constructor(address mentalHealthCoalition, address payable recipient, uint256 seed) Ownable() payable {
		require(mentalHealthCoalition != address(0) && recipient != address(0), "constructor: invalid inputs");
		_mentalHealthCoalition = MentalHealthCoalition(mentalHealthCoalition);
		_recipient = recipient;
		_seed = seed;
	}

	/// @return Returns the available supply of tokens minted by this contract
	function availableSupply() external view returns (uint256) {
		if (_minted >= MAX_MINT) return 0;
		return MAX_MINT - _minted;
	}

	/// Mints the provided type and quantity of Kennethisms
	/// @dev There are some optimizations to reduce minting gas costs, which have been thoroughly unit tested
	/// @param amount The amount to mint
	function mintKennethisms(uint256 amount) external payable {
		// Check for a valid mint
		if (amount == 0 || amount > MAX_MINT_QUANTITY) revert InvalidAmount();
		if (msg.value != MINT_PRICE * amount) revert InvalidPrice();
		unchecked { // bounds for `amount` and `_minted` are known and won't cause an overflow
			uint totalMinted = _minted + amount;
			if (totalMinted > MAX_MINT) revert SoldOut();
			_minted = totalMinted;
		}
		// Determine the token ids that will be minted using a pseudo-random function
		bytes32 seedBytes = _hashSeed(_seed);
		uint count = 0; // Determines the size of the input arrays for minting
		uint8[4] memory amounts = [0, 0, 0, 0];
		unchecked { // bounds for `index`, `amount`, and `count` are all known and do not need to be checked for overflows
			for (uint index = 0; index < amount; ++index) {
				uint tokenId = _selectTokenId(uint8(seedBytes[index]));
				uint currentAmount = amounts[tokenId];
				if (currentAmount == 0) ++count;
				amounts[tokenId] = uint8(currentAmount + 1);
			}
		}
		// Now prepare the arrays to be passed into the minting function
		uint256[] memory tokenIds = new uint256[](count);
		uint256[] memory amountsById = new uint256[](count);
		count = 0; // Reset count as an index into the arrays above
		unchecked { // bounds for `index`, `amount`, and `count` are all known and do not need to be checked for overflows
			for (uint index = 0; index < amounts.length; ++index) {
				uint current = amounts[index];
				// Are we minting this token id?
				if (current == 0) continue;
				tokenIds[count] = index;
				amountsById[count] = current;
				// Have we finished checking non-0 ids?
				if (++count == tokenIds.length) break;
			}
		}
		_seed = uint256(seedBytes);
		// Call the minting function
		uint256[] memory blank = new uint256[](0);
		_mentalHealthCoalition.mintBurnBatch(_msgSender(), tokenIds, amountsById, blank, blank);
	}

	/// @dev Withdraws proceeds for donation
	function withdrawProceeds() external {
        require(owner() == _msgSender() || _recipient == _msgSender(), "Ownable: caller is not the owner");
		uint256 balance = address(this).balance;
		if (balance > 0) {
			Address.sendValue(_recipient, balance);
		}
	}

	/// Hashes a seed along with a few other variables to improve randomness of selection
	function _hashSeed(uint256 initialSeed) private view returns (bytes32) {
		return keccak256(abi.encodePacked(blockhash(block.number - 1), _msgSender(), initialSeed >> 1));
	}

	/// Bespoke function that picks a token id based on the random input's spread within the desired percentages
	function _selectTokenId(uint8 seedByte) private pure returns (uint256) {
		// Unit tests will confirm that this provides the desired spread of randomness
		if (seedByte < 153) return 0; // Token 0 has a 60% chance (0-152)
		if (seedByte < 204) return 1; // Token 1 has a 20% chance (153-203)
		if (seedByte < 243) return 2; // Token 2 has a 15% chance (204-242)
		return 3; // Token 3 has a 5% chance (243-255)
	}
}
