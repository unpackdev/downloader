// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Pausable.sol";

import "./Fields.sol";
import "./ERC721ABurnable.sol";

abstract contract Base is Ownable, ERC721ABurnable, Pausable, Fields {
	/*
	 * accepts ether sent with no txData
	 */
	receive() external payable {
		for (uint8 i; i < receiverAddresses.length; i++) {
			address receiverAddress = receiverAddresses[i];
			uint256 maxToWithdraw = (msg.value * team[receiverAddress].percentage) / 100;
			_sendValueTo(receiverAddress, maxToWithdraw);
		}
	}

	/**
	 * @dev Triggers stopped state.
	 *
	 * Requirements:
	 *
	 * - The contract must not be paused.
	 */
	function pause() public onlyOwner {
		super._pause();
	}

	/**
	 * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	function unpause() public onlyOwner {
		super._unpause();
	}

	/**
	 * @dev baseURI for computing {tokenURI}. Empty by default, can be overwritten
	 * in child contracts.
	 */
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	/**
	 * @dev Set the baseURI to a given uri
	 * @param baseURI_ string to save
	 */
	function changeBaseURI(string memory baseURI_) external onlyOwner {
		switchMinting();
		emit BaseURIChanged(baseURI, baseURI_);
		baseURI = baseURI_;
	}

	/**
	 * @dev Returns whether `tokenId` exists.
	 *
	 * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	 *
	 * Tokens start existing when they are minted (`_mint`),
	 * and stop existing when they are burned (`_burn`).
	 */
	function exists(uint256 tokenId) public view returns (bool) {
		return _exists(tokenId);
	}

	function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
		return _ownerships[index];
	}

	/**
	 * @dev Send an amount of value to a specific address
	 * @param to_ address that will receive the value
	 * @param value to be sent to the address
	 */
	function _sendValueTo(address to_, uint256 value) internal {
		address payable to = payable(to_);
		(bool success, ) = to.call{ value: value }("");
		if (!success) revert ETHTransferFailed();
	}

	function _beforeTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal override {
		super._beforeTokenTransfers(from, to, startTokenId, quantity);
		if (paused()) revert NFTTransferPaused();
	}

	// start minting
	function switchMinting() public onlyOwner {
		mintedStarted = !mintedStarted;
	}

    /**
     * @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 holdingAmount = balanceOf(owner);
        uint256 currSupply    = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        uint256[] memory list = new uint256[](holdingAmount);
        unchecked {
            for (uint256 i; i < currSupply; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                // Find out who owns this sequence
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                // Append tokens the last found owner owns in the sequence
                if (currOwnershipAddr == owner) {
                    list[tokenIdsIdx++] = i;
                }
                // All tokens have been found, we don't need to keep searching
                if(tokenIdsIdx == holdingAmount) {
                    break;
                }
            }
        }
        return list;
    }

    /**
     * First token to be minted starts at 1
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
