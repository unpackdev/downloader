// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";

error ZeroInput();
error MismatchedArrays();
error SoulboundTokenNotTransferable();

contract CASETiFYCollectsProofs is ERC1155, Ownable {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    constructor(string memory name_, string memory symbol_, string memory tokenuri_) ERC1155(tokenuri_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function setURI(string calldata newuri) public onlyOwner {
        _setURI(newuri);
    }

	function airDrop(address to, uint256 id, uint256 quantity) public onlyOwner {
        if (quantity == 0) revert ZeroInput();
        
		_mint(to, id, quantity, "");
    }

	function airDropBatch(address to, uint256[] calldata ids, uint256[] calldata quantity) public onlyOwner {
        _mintBatch(to, ids, quantity, "");
    }

	function bulkAirDrop(address[] calldata recipients, uint256 id) public onlyOwner {
        if (recipients.length == 0) revert ZeroInput();
        
        for (uint256 i = 0; i < recipients.length;) {
            _mint(recipients[i], id, 1, "");
            unchecked {
                ++i;
            }
        }
	}

	function bulkAirDropBatch(address[] calldata recipients, uint256[] calldata ids) public onlyOwner {
        if (recipients.length == 0) revert ZeroInput();
        if (recipients.length != ids.length) revert MismatchedArrays();
        
        for (uint256 i = 0; i < recipients.length;) {
            _mint(recipients[i], ids[i], 1, "");
            unchecked {
                ++i;
            }
        }
	}

    function setApprovalForAll(address, bool) public pure override {
        revert SoulboundTokenNotTransferable();
    }

    function safeTransferFrom(address, address, uint256, uint256, bytes memory) public pure override {
        revert SoulboundTokenNotTransferable();
    }

    function safeBatchTransferFrom(address, address, uint256[] memory, uint256[] memory, bytes memory) public pure override {
        revert SoulboundTokenNotTransferable();
    }
}
