// SPDX-License-Identifier: MIT
// solhint-disable reason-string

pragma solidity ^0.8.0;

import "./Address.sol";

import "./IERC1155Receiver.sol";
import "./IERC1155Internal.sol";

import "./ERC2771Recipient.sol";

import "./ERC1155NSBaseStorage.sol";

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155NSBaseInternal is ERC2771Recipient, IERC1155Internal {
	using Address for address;

	/**
	 * @notice query the balance of given token held by given address
	 * @param account address to query
	 * @param id token to query
	 * @return token balance
	 */
	function _balanceOf(address account, uint256 id) internal view virtual returns (uint256) {
		require(account != address(0), "ERC1155: balance query for the zero address");
		return ERC1155NSBaseStorage.layout().balances[id][account];
	}

	/**
	 * @notice transfer tokens between given addresses
	 * @dev ERC1155Receiver implementation is not checked
	 * @param operator executor of transfer
	 * @param from sender of tokens
	 * @param to receiver of tokens
	 * @param id token ID
	 * @param amount quantity of tokens to transfer
	 * @param data data payload
	 */
	function _transfer(
		address operator,
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: transfer to the zero address");

		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(
			operator,
			from,
			to,
			_asSingletonArray(id),
			_asSingletonArray(amount),
			data
		);

		mapping(uint256 => mapping(address => uint256)) storage balances = ERC1155NSBaseStorage
			.layout()
			.balances;

		unchecked {
			uint256 fromBalance = balances[id][from];
			require(fromBalance >= amount, "ERC1155: insufficient balances for transfer");
			balances[id][from] = fromBalance - amount;
		}

		balances[id][to] += amount;

		emit TransferSingle(operator, from, to, id, amount);

		_afterTokenTransfer(operator, from, to, ids, amounts, data);
	}

	/**
	 * @notice transfer tokens between given addresses
	 * @param operator executor of transfer
	 * @param sender sender of tokens
	 * @param recipient receiver of tokens
	 * @param id token ID
	 * @param amount quantity of tokens to transfer
	 * @param data data payload
	 */
	function _safeTransfer(
		address operator,
		address sender,
		address recipient,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		_transfer(operator, sender, recipient, id, amount, data);

		_doSafeTransferAcceptanceCheck(operator, sender, recipient, id, amount, data);
	}

	/**
	 * @notice transfer batch of tokens between given addresses
	 * @dev ERC1155Receiver implementation is not checked
	 * @param operator executor of transfer
	 * @param from sender of tokens
	 * @param to receiver of tokens
	 * @param ids token IDs
	 * @param amounts quantities of tokens to transfer
	 * @param data data payload
	 */
	function _transferBatch(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
		require(to != address(0), "ERC1155: transfer to the zero address");

		_beforeTokenTransfer(operator, from, to, ids, amounts, data);

		mapping(uint256 => mapping(address => uint256)) storage balances = ERC1155NSBaseStorage
			.layout()
			.balances;

		for (uint256 i = 0; i < ids.length; ) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			unchecked {
				uint256 fromBalance = balances[id][from];

				require(fromBalance >= amount, "ERC1155: insufficient balances for transfer");

				balances[id][from] = fromBalance - amount;

				i++;
			}

			// balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
			balances[id][to] += amount;
		}

		emit TransferBatch(operator, from, to, ids, amounts);

		_afterTokenTransfer(operator, from, to, ids, amounts, data);
	}

	/**
	 * @notice transfer batch of tokens between given addresses
	 * @param operator executor of transfer
	 * @param sender sender of tokens
	 * @param recipient receiver of tokens
	 * @param ids token IDs
	 * @param amounts quantities of tokens to transfer
	 * @param data data payload
	 */
	function _safeTransferBatch(
		address operator,
		address sender,
		address recipient,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		_transferBatch(operator, sender, recipient, ids, amounts, data);

		_doSafeBatchTransferAcceptanceCheck(operator, sender, recipient, ids, amounts, data);
	}

	/**
	 * @notice mint given quantity of tokens for given address
	 * @dev ERC1155Receiver implementation is not checked
	 * @param to beneficiary of minting
	 * @param id token ID
	 * @param amount quantity of tokens to mint
	 * @param data data payload
	 */
	function _mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		_unsafeMint(operator, to, id, amount);

		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);
	}

	/**
	 * @notice mint given quantity of tokens for given address
	 * @param account beneficiary of minting
	 * @param id token ID
	 * @param amount quantity of tokens to mint
	 * @param data data payload
	 */
	function _safeMint(
		address account,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		_mint(account, id, amount, data);

		_doSafeTransferAcceptanceCheck(_msgSender(), address(0), account, id, amount, data);
	}

	/**
	 * Mint without any safety checks or other function calls
	 */
	function _unsafeMint(
		address operator,
		address to,
		uint256 id,
		uint256 amount
	) internal virtual {
		ERC1155NSBaseStorage.layout().balances[id][to] += amount;
		emit TransferSingle(operator, address(0), to, id, amount);
	}

	/**
	 * @notice mint batch of tokens for given address
	 * @dev ERC1155Receiver implementation is not checked
	 * @param to beneficiary of minting
	 * @param ids list of token IDs
	 * @param amounts list of quantities of tokens to mint
	 * @param data data payload
	 */
	function _mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		_unsafeMintBatch(operator, to, ids, amounts);

		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);
	}

	/**
	 * @notice mint batch of tokens for given address
	 * @param account beneficiary of minting
	 * @param ids list of token IDs
	 * @param amounts list of quantities of tokens to mint
	 * @param data data payload
	 */
	function _safeMintBatch(
		address account,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		_mintBatch(account, ids, amounts, data);

		_doSafeBatchTransferAcceptanceCheck(_msgSender(), address(0), account, ids, amounts, data);
	}

	/**
	 * Mint without any safety checks or other function calls
	 */
	function _unsafeMintBatch(
		address operator,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal virtual {
		mapping(uint256 => mapping(address => uint256)) storage balances = ERC1155NSBaseStorage
			.layout()
			.balances;

		for (uint256 i = 0; i < ids.length; ) {
			balances[ids[i]][to] += amounts[i];
			unchecked {
				i++;
			}
		}

		emit TransferBatch(operator, address(0), to, ids, amounts);
	}

	/**
	 * @notice burn given quantity of tokens held by given address
	 * @param from holder of tokens to burn
	 * @param id token ID
	 * @param amount quantity of tokens to burn
	 */
	function _burn(
		address from,
		uint256 id,
		uint256 amount
	) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

		mapping(address => uint256) storage balances = ERC1155NSBaseStorage.layout().balances[id];

		uint256 fromBalance = balances[from];
		unchecked {
			require(fromBalance >= amount, "ERC1155: burn amount exceeds balances");
			balances[from] = fromBalance - amount;
		}

		emit TransferSingle(_msgSender(), from, address(0), id, amount);

		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}

	/**
	 * @notice burn given batch of tokens held by given address
	 * @param from holder of tokens to burn
	 * @param ids token IDs
	 * @param amounts quantities of tokens to burn
	 */
	function _burnBatch(
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

		mapping(uint256 => mapping(address => uint256)) storage balances = ERC1155NSBaseStorage
			.layout()
			.balances;

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = balances[id][from];
			require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
			unchecked {
				balances[id][from] = fromBalance - amount;
			}
		}

		emit TransferBatch(_msgSender(), from, address(0), ids, amounts);

		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}

	/**
	 * @dev Approve `operator` to operate on all of `owner` tokens
	 *
	 * Emits a {ApprovalForAll} event.
	 */
	function _setApprovalForAll(
		address owner,
		address operator,
		bool status
	) internal virtual {
		require(_msgSender() != operator, "ERC1155: setting approval status for self");
		ERC1155NSBaseStorage.layout().operatorApprovals[owner][operator] = status;
		emit ApprovalForAll(owner, operator, status);
	}

	/**
	 * @dev Hook that is called after any token transfer. This includes minting
	 * and burning, as well as batched variants.
	 *
	 * The same hook is called on both single and batched variants. For single
	 * transfers, the length of the `id` and `amount` arrays will be 1.
	 *
	 * Calling conditions (for each `id` and `amount` pair):
	 *
	 * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * of token type `id` will be  transferred to `to`.
	 * - When `from` is zero, `amount` tokens of token type `id` will be minted
	 * for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
	 * will be burned.
	 * - `from` and `to` are never both zero.
	 * - `ids` and `amounts` have the same, non-zero length.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _afterTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}

	/**
	 * @notice ERC1155 hook, called before all transfers including mint and burn
	 * @dev function should be overridden and new implementation must call super
	 * @dev called for both single and batch transfers
	 * @param operator executor of transfer
	 * @param from sender of tokens
	 * @param to receiver of tokens
	 * @param ids token IDs
	 * @param amounts quantities of tokens to transfer
	 * @param data data payload
	 */
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}

	/**
	 * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
	 * @param operator executor of transfer
	 * @param from sender of tokens
	 * @param to receiver of tokens
	 * @param id token ID
	 * @param amount quantity of tokens to transfer
	 * @param data data payload
	 */
	function _doSafeTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
				bytes4 response
			) {
				require(
					response == IERC1155Receiver.onERC1155Received.selector,
					"ERC1155: ERC1155Receiver rejected tokens"
				);
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	/**
	 * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
	 * @param operator executor of transfer
	 * @param from sender of tokens
	 * @param to receiver of tokens
	 * @param ids token IDs
	 * @param amounts quantities of tokens to transfer
	 * @param data data payload
	 */
	function _doSafeBatchTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
				bytes4 response
			) {
				require(
					response == IERC1155Receiver.onERC1155BatchReceived.selector,
					"ERC1155: ERC1155Receiver rejected tokens"
				);
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	/**
	 * @notice wrap given element in array of length 1
	 * @param element element to wrap
	 * @return singleton array
	 */
	function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;
		return array;
	}
}
