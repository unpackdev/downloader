// SPDX-License-Identifier: MIT
// solhint-disable reason-string

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ERC1155NSBaseInternal.sol";

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 * and solid state, but uses _msgSender() so that contracts are supported
 */
abstract contract ERC1155NSBase is IERC1155, ERC1155NSBaseInternal {
	/**
	 * @inheritdoc IERC1155
	 */
	function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
		return _balanceOf(account, id);
	}

	/**
	 * @inheritdoc IERC1155
	 */
	function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
		public
		view
		virtual
		override
		returns (uint256[] memory)
	{
		require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

		mapping(uint256 => mapping(address => uint256)) storage balances = ERC1155NSBaseStorage
			.layout()
			.balances;

		uint256[] memory batchBalances = new uint256[](accounts.length);

		unchecked {
			for (uint256 i = 0; i < accounts.length; i++) {
				require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
				batchBalances[i] = balances[ids[i]][accounts[i]];
			}
		}

		return batchBalances;
	}

	/**
	 * @inheritdoc IERC1155
	 */
	function isApprovedForAll(address account, address operator)
		public
		view
		virtual
		override
		returns (bool)
	{
		return ERC1155NSBaseStorage.layout().operatorApprovals[account][operator];
	}

	/**
	 * @inheritdoc IERC1155
	 */
	function setApprovalForAll(address operator, bool status) public virtual override {
		_setApprovalForAll(_msgSender(), operator, status);
	}

	/**
	 * @inheritdoc IERC1155
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		_safeTransfer(_msgSender(), from, to, id, amount, data);
	}

	/**
	 * @inheritdoc IERC1155
	 */
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		_safeTransferBatch(_msgSender(), from, to, ids, amounts, data);
	}
}
