// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
 * A token burned is worth 900 seconds of the Creator's life.
 *
 *
 */
contract TimeKeeper is ERC1155, ReentrancyGuard, Ownable {
	uint256 constant private _TOKENID = 0;

	uint256 public IN_CIRCULATION;
	uint256 public MAX_PER_MINT;
	uint256 public BASE_PRICE;

	constructor(uint256 maxPerMint, uint256 basePrice) ERC1155("") {
		MAX_PER_MINT = maxPerMint;
		BASE_PRICE = basePrice;
	}

	function price() public view returns (uint256) {
		return BASE_PRICE * IN_CIRCULATION;
	}

	// The future for sale in 15 minute parcels
	function mint(
		address to,
		uint256 count
	) external payable nonReentrant {
		require(count <= MAX_PER_MINT, "Count too high");
		require(msg.value >= price() * count, "Value too low");
		_mint(to, _TOKENID, count, bytes(""));
		IN_CIRCULATION += count;
	}

	// Burn tokens to claim their weight in time
	function burn(
		uint256 count
	) external nonReentrant {
		_burn(msg.sender, _TOKENID, count);
		IN_CIRCULATION -= count;
	}

	function setURI(string memory newuri) external {
        _setURI(newuri);
    }

	function setMaxPerMint(uint256 newmax) external onlyOwner {
		MAX_PER_MINT = newmax;
	}

	function setBasePrice(uint256 newbase) external onlyOwner {
		BASE_PRICE = newbase;
	}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }	
}
