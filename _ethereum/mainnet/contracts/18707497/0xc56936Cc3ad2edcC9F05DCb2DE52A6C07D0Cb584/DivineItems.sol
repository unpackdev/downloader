/**
 * @title  Items Contract for Divine Anarchy, allowing us to add/curate new traits for DA characters
 * @author Diveristy - twitter.com/DiversityETH
 *
 * 8888b.  88 Yb    dP 88 88b 88 888888      db    88b 88    db    88""Yb  dP""b8 88  88 Yb  dP
 *  8I  Yb 88  Yb  dP  88 88Yb88 88__       dPYb   88Yb88   dPYb   88__dP dP   `" 88  88  YbdP
 *  8I  dY 88   YbdP   88 88 Y88 88""      dP__Yb  88 Y88  dP__Yb  88"Yb  Yb      888888   8P
 * 8888Y"  88    YP    88 88  Y8 888888   dP""""Yb 88  Y8 dP""""Yb 88  Yb  YboodP 88  88  dP
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC1155.sol";
import "./LibString.sol";

import "./console.sol";

error ContractPaused();
error ArgCountMismatch(uint256 item_ids, uint256 amounts);
error ServerAuthReject();

contract DivineItems is ERC1155, Ownable {
	using LibString for uint256;
	using ECDSA for bytes32;
	event ServiceExecuted(string json);

    address private _signer;
	bool public paused = false;
	uint256 public totalSupply = 0;
	string public baseUri;

	constructor(string memory new_uri, address signer) {
		setSigner(signer);
		baseUri = new_uri;
	}

	function mint(uint256[] calldata itemIds, uint256[] calldata amounts, bytes memory signature, string calldata service_json) public {
		uint256 itemIdsLength = itemIds.length;

		uint256 priorTotalSupply = totalSupply;
		totalSupply += totalArray(amounts);

		// Correct args & contract state
		if(paused) revert ContractPaused();
		if(itemIdsLength != amounts.length) revert ArgCountMismatch(itemIdsLength, amounts.length);

		// Valid server auth
		bytes32 message = keccak256(abi.encodePacked(msg.sender, itemIds, amounts, priorTotalSupply, service_json));
		bytes32 hash = message.toEthSignedMessageHash();
		address signer = hash.recover(signature);
		if(signer != _signer) revert ServerAuthReject();

		if(itemIdsLength > 0) {
			_batchMint(msg.sender, itemIds, amounts, "");
		} else {
			_mint(msg.sender, itemIds[0], amounts[0], "");
		}

		emit ServiceExecuted(service_json);
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(baseUri, "/", tokenId.toString()));
	}

	function setUri(string memory new_uri) public onlyOwner {
		baseUri = new_uri;
	}

	function togglePause() public onlyOwner {
		paused = !paused;
	}

	function airdrop(uint256 tokenId, uint256 amount, address wallet) public onlyOwner {
		_mint(wallet, tokenId, amount, "");
		totalSupply += amount;
	}

	function setSigner(address signer) public onlyOwner {
		_signer = signer;
	}

	function totalArray(uint256[] calldata array) public pure returns (uint256) {
		uint256 total = 0;
		for(uint256 i = 0; i < array.length; i++) {
			total += array[i];
		}
		return total;
	}
}