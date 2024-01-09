// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721TokenReceiver.sol";

abstract contract ERC721 {
	/* -------------------------------------------------------------------------- */
	/*                                   EVENTS                                   */
	/* -------------------------------------------------------------------------- */

	/// @dev Emitted when `id` token is transferred from `from` to `to`.
	event Transfer(address indexed from, address indexed to, uint256 indexed id);

	/// @dev Emitted when `owner` enables `approved` to manage the `id` token.
	event Approval(address indexed owner, address indexed spender, uint256 indexed id);

	/// @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/* -------------------------------------------------------------------------- */
	/*                              METADATA STORAGE                              */
	/* -------------------------------------------------------------------------- */

	/// @dev The collection name.
	string private _name;

	/// @dev The collection symbol.
	string private _symbol;

	/* -------------------------------------------------------------------------- */
	/*                               ERC721 STORAGE                               */
	/* -------------------------------------------------------------------------- */

	/// @dev ID => spender
	mapping(uint256 => address) internal _tokenApprovals;

	/// @dev owner => operator => approved
	mapping(address => mapping(address => bool)) internal _operatorApprovals;

	/* -------------------------------------------------------------------------- */
	/*                                 CONSTRUCTOR                                */
	/* -------------------------------------------------------------------------- */

	/// @param name_ The collection name.
	/// @param symbol_ The collection symbol.
	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	/* -------------------------------------------------------------------------- */
	/*                                ERC165 LOGIC                                */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns true if this contract implements an interface from its ID.
	/// @dev See the corresponding
	/// [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
	/// to learn more about how these IDs are created.
	/// @return The implementation status.
	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
		return
			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
			interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
			interfaceId == 0x780e9d63; // ERC165 Interface ID for ERC721Enumerable
	}

	/* -------------------------------------------------------------------------- */
	/*                               METADATA LOGIC                               */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns the collection name.
	/// @return The collection name.
	function name() public view virtual returns (string memory) {
		return _name;
	}

	/// @notice Returns the collection symbol.
	/// @return The collection symbol.
	function symbol() public view virtual returns (string memory) {
		return _symbol;
	}

	/// @notice Returns the Uniform Resource Identifier (URI) for `id` token.
	/// @param id The token ID.
	/// @return The URI.
	function tokenURI(uint256 id) public view virtual returns (string memory);

	/* -------------------------------------------------------------------------- */
	/*                              ENUMERABLE LOGIC                              */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns the total amount of tokens stored by the contract.
	/// @return The token supply.
	function totalSupply() public view virtual returns (uint256);

	/// @notice Returns a token ID owned by `owner` at a given `index` of its token list.
	/// @dev Use along with {balanceOf} to enumerate all of `owner`'s tokens.
	/// @param owner The address to query.
	/// @param index The index to query.
	/// @return The token ID.
	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);

	/// @notice Returns a token ID at a given `index` of all the tokens stored by the contract.
	/// @dev Use along with {totalSupply} to enumerate all tokens.
	/// @param index The index to query.
	/// @return The token ID.
	function tokenByIndex(uint256 index) public view virtual returns (uint256);

	/* -------------------------------------------------------------------------- */
	/*                                ERC721 LOGIC                                */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns the account approved for a token ID.
	/// @dev Requirements:
	/// - `id` must exist.
	/// @param id Token ID to query.
	/// @return The account approved for `id` token.
	function getApproved(uint256 id) public virtual returns (address) {
		require(_exists(id), "NONEXISTENT_TOKEN");
		return _tokenApprovals[id];
	}

	/// @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
	/// @param owner The address of the owner.
	/// @param operator The address of the operator.
	/// @return True if `operator` was approved by `owner`.
	function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
		return _operatorApprovals[owner][operator];
	}

	/// @notice Gives permission to `to` to transfer `id` token to another account.
	/// @dev The approval is cleared when the token is transferred.
	/// Only a single account can be approved at a time, so approving the zero address clears previous approvals.
	/// Requirements:
	/// - The caller must own the token or be an approved operator.
	/// - `id` must exist.
	/// Emits an {Approval} event.
	/// @param spender The address of the spender to approve to.
	/// @param id The token ID to approve.
	function approve(address spender, uint256 id) public virtual {
		address owner = ownerOf(id);

		require(isApprovedForAll(owner, msg.sender) || msg.sender == owner, "NOT_AUTHORIZED");

		_tokenApprovals[id] = spender;

		emit Approval(owner, spender, id);
	}

	/// @notice Approve or remove `operator` as an operator for the caller.
	/// @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
	/// Emits an {ApprovalForAll} event.
	/// @param operator The address of the operator to approve.
	/// @param approved The status to set.
	function setApprovalForAll(address operator, bool approved) public virtual {
		_operatorApprovals[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	/// @notice Transfers `id` token from `from` to `to`.
	/// WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
	/// @dev Requirements:
	/// - `to` cannot be the zero address.
	/// - `id` token must be owned by `from`.
	/// - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	/// Emits a {Transfer} event.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param id The token ID to transfer.
	function transferFrom(
		address from,
		address to,
		uint256 id
	) public virtual {
		_transfer(from, to, id);
	}

	/// @notice Safely transfers `id` token from `from` to `to`.
	/// @dev Requirements:
	/// - `to` cannot be the zero address.
	/// - `id` token must exist and be owned by `from`.
	/// - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	/// - If `to` refers to a smart contract, it must implement {ERC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
	/// Emits a {Transfer} event.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param id The token ID to transfer.
	function safeTransferFrom(
		address from,
		address to,
		uint256 id
	) public virtual {
		_transfer(from, to, id);

		require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT");
	}

	/// @notice Safely transfers `id` token from `from` to `to`.
	/// @dev Requirements:
	/// - `to` cannot be the zero address.
	/// - `id` token must exist and be owned by `from`.
	/// - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	/// - If `to` refers to a smart contract, it must implement {ERC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
	/// Emits a {Transfer} event.
	/// Additionally passes `data` in the callback.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param id The token ID to transfer.
	/// @param data The calldata to pass in the {ERC721TokenReceiver-onERC721Received} callback.
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		bytes memory data
	) public virtual {
		_transfer(from, to, id);

		require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT");
	}

	/// @notice Returns the number of tokens in an account.
	/// @param owner The address to query.
	/// @return The balance.
	function balanceOf(address owner) public view virtual returns (uint256);

	/// @notice Returns the owner of a token ID.
	/// @dev Requirements:
	/// - `id` must exist.
	/// @param id The token ID.
	function ownerOf(uint256 id) public view virtual returns (address);

	/* -------------------------------------------------------------------------- */
	/*                               INTERNAL LOGIC                               */
	/* -------------------------------------------------------------------------- */

	/// @dev Returns whether a token ID exists.
	/// Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	/// Tokens start existing when they are minted.
	/// @param id Token ID to query.
	function _exists(uint256 id) internal view virtual returns (bool);

	/// @dev Transfers `id` from `from` to `to`.
	/// Requirements:
	/// - `to` cannot be the zero address.
	/// - `id` token must be owned by `from`.
	/// Emits a {Transfer} event.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param id The token ID to transfer.
	function _transfer(
		address from,
		address to,
		uint256 id
	) internal virtual;

	/// @dev Mints `amount` tokens to `to`.
	/// Requirements:
	/// - there must be `amount` tokens remaining unminted in the total collection.
	/// - `to` cannot be the zero address.
	/// Emits `amount` {Transfer} events.
	/// @param to The address to mint to.
	/// @param amount The amount of tokens to mint.
	function _mint(address to, uint256 amount) internal virtual;

	/// @dev Safely mints `amount` of tokens and transfers them to `to`.
	/// If `to` is a contract it must implement {ERC721TokenReceiver.onERC721Received}
	/// that returns {ERC721TokenReceiver.onERC721Received.selector}.
	/// @param to The address to mint to.
	/// @param amount The amount of tokens to mint.
	function _safeMint(address to, uint256 amount) internal virtual {
		_mint(to, amount);

		require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(address(0), to, totalSupply() - amount + 1, "") == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT");
	}

	/// @dev Safely mints `amount` of tokens and transfers them to `to`.
	/// Requirements:
	/// - `id` must not exist.
	/// - If `to` refers to a smart contract, it must implement {ERC721TokenReceiver.onERC721Received}, which is called upon a safe transfer.
	/// Additionally passes `data` in the callback.
	/// @param to The address to mint to.
	/// @param amount The amount of tokens to mint.
	/// @param data The calldata to pass in the {ERC721TokenReceiver.onERC721Received} callback.
	function _safeMint(
		address to,
		uint256 amount,
		bytes memory data
	) internal virtual {
		_mint(to, amount);

		require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(address(0), to, totalSupply() - amount + 1, data) == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT");
	}

	/* -------------------------------------------------------------------------- */
	/*                                    UTILS                                   */
	/* -------------------------------------------------------------------------- */

	/// @notice Converts a `uint256` to its ASCII `string` decimal representation.
	/// @dev https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
	function toString(uint256 value) internal pure virtual returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}
