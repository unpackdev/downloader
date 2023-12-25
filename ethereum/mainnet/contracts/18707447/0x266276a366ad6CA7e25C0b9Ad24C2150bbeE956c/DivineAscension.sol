/**
 * @title  Divine Ascension Contract, For Apple ascension
 * @author Diveristy - twitter.com/DiversityETH
 *
 * 8888b.  88 Yb    dP 88 88b 88 888888      db    88b 88    db    88""Yb  dP""b8 88  88 Yb  dP
 *  8I  Yb 88  Yb  dP  88 88Yb88 88__       dPYb   88Yb88   dPYb   88__dP dP   `" 88  88  YbdP
 *  8I  dY 88   YbdP   88 88 Y88 88""      dP__Yb  88 Y88  dP__Yb  88"Yb  Yb      888888   8P
 * 8888Y"  88    YP    88 88  Y8 888888   dP""""Yb 88  Y8 dP""""Yb 88  Yb  YboodP 88  88  dP
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IERC721.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./LibString.sol";

import "./console.sol";

error MintPaused();
error MaxSupplyReached();
error InvalidMintArguments();
error AddressCantMint();
error TokenAlreadyAscended(uint256 nftId);

contract DivineAscension is Ownable, ERC721 {
	using LibString for uint256;

	uint256 public constant MAX_SUPPLY = 3000;
	// We can't burn to Zero Address (transfer error block) so we will use the next best thing.
	address public constant BURN_ADDRESS = 0x0000000000000000000000000000000000000001;
	bool public paused = false;
	string public baseUri;
	uint256 public totalSupply = 0;

	IERC721 private appleContract;

	constructor(string memory uri, address appleContractAddress) {
		baseUri = uri;
		appleContract = IERC721(appleContractAddress);
	}

	function mint(uint256[] calldata apple_ids, uint256[] calldata da_ids) public {
		if (paused) revert MintPaused();
		uint256 quantity = apple_ids.length;
		if (quantity != da_ids.length) revert InvalidMintArguments();
		if (totalSupply + quantity > MAX_SUPPLY) revert MaxSupplyReached();
		if (msg.sender == BURN_ADDRESS) revert AddressCantMint();

		for (uint i; i < quantity; i++) {
			uint256 apple_id = apple_ids[i];
			uint256 da_id = da_ids[i];

			if (_exists(da_id)) revert TokenAlreadyAscended(da_id);

			appleContract.transferFrom(msg.sender, BURN_ADDRESS, apple_id);
			_safeMint(msg.sender, da_id);
		}
		totalSupply += quantity;
	}

	// Harded coded id's to check for the owner's tokens to save gas during mint
	function walletOfOwner(address owner) public view returns (uint256[] memory) {
		uint256 balance = balanceOf(owner);
		uint256[] memory wallet = new uint256[](balance);
		uint256 idx = 0;
		for (uint i = 11; i <= 10010; i++) {
			address curr = _ownerOf(i);
			if (curr == owner) {
				wallet[idx] = i;
				idx++;
			}
		}

		return wallet;
	}

	function name() public view virtual override returns (string memory) {
		return "Divine Ascension";
	}

	function symbol() public view virtual override returns (string memory) {
		return "DAAS";
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		return string(abi.encodePacked(baseUri, "/", tokenId.toString(), ".json"));
	}

	function setBaseUri(string memory uri) public onlyOwner {
		baseUri = uri;
	}

	function togglePause() public onlyOwner {
		paused = !paused;
	}
}