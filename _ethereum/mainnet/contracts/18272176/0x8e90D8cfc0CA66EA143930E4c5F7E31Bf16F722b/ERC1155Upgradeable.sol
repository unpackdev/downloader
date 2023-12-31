// SPDX-License-Identifier: MIT
// Modifications from OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol):
// - Revert strings replaced with custom errors
// - Decoupled hooks 
//   - `_beforeTokenTransfer` --> `_beforeTokenTransfer` & `_beforeBatchTokenTransfer`
//   - `_afterTokenTransfer` --> `_afterTokenTransfer` & `_afterBatchTokenTransfer`
// - Minor gas optimizations (eg. array length caching, unchecked loop iteration)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./IERC1155MetadataURIUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";

error ERC1155_ADDRESS_ZERO_IS_NOT_A_VALID_OWNER();
error ERC1155_ACCOUNTS_AND_IDS_LENGTH_MISMATCH();
error ERC1155_IDS_AND_AMOUNTS_LENGTH_MISMATCH();
error ERC1155_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
error ERC1155_TRANSFER_TO_ZERO_ADDRESS();
error ERC1155_INSUFFICIENT_BALANCE_FOR_TRANSFER();
error ERC1155_MINT_TO_ZERO_ADDRESS();
error ERC1155_BURN_FROM_ZERO_ADDRESS();
error ERC1155_BURN_AMOUNT_EXCEEDS_BALANCE();
error ERC1155_SETTING_APPROVAL_FOR_SELF();
error ERC1155_ERC1155RECEIVER_REJECTED_TOKENS();
error ERC1155_TRANSFER_TO_NON_ERC1155RECEIVER_IMPLEMENTER();

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if (account == address(0)) {
            revert ERC1155_ADDRESS_ZERO_IS_NOT_A_VALID_OWNER();
        }
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory batchBalances) {
        uint256 numAccounts = accounts.length;

        if (numAccounts != ids.length) {
            revert ERC1155_ACCOUNTS_AND_IDS_LENGTH_MISMATCH();
        }

        batchBalances = new uint256[](numAccounts);

        unchecked {
            for (uint256 i; i < numAccounts; ++i) {
                batchBalances[i] = balanceOf(accounts[i], ids[i]);
            }
        }
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert ERC1155_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert ERC1155_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert ERC1155_TRANSFER_TO_ZERO_ADDRESS();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, id, amount, data);

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
            revert ERC1155_INSUFFICIENT_BALANCE_FOR_TRANSFER();
        }
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, id, amount, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 numIds = ids.length;

        if (numIds != amounts.length) {
            revert ERC1155_ACCOUNTS_AND_IDS_LENGTH_MISMATCH();
        }
        if (to == address(0)) {
            revert ERC1155_TRANSFER_TO_ZERO_ADDRESS();
        }

        address operator = _msgSender();

        _beforeBatchTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 id;
        uint256 amount;
        uint256 fromBalance;

        for (uint256 i; i < numIds; ) {
            id = ids[i];
            amount = amounts[i];
            fromBalance = _balances[id][from];

            if (fromBalance < amount) {
                revert ERC1155_INSUFFICIENT_BALANCE_FOR_TRANSFER();
            }

            _balances[id][to] += amount;

            unchecked {
                _balances[id][from] = fromBalance - amount;

                ++i;
            }


        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterBatchTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        if (to == address(0)) {
            revert ERC1155_MINT_TO_ZERO_ADDRESS();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, id, amount, data);

        _balances[id][to] += amount;

        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, id, amount, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert ERC1155_MINT_TO_ZERO_ADDRESS();
        }

        uint256 numIds = ids.length;

        if (numIds != amounts.length) {
            revert ERC1155_IDS_AND_AMOUNTS_LENGTH_MISMATCH();
        }

        address operator = _msgSender();

        _beforeBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i; i < numIds; ) {
            _balances[ids[i]][to] += amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        if (from == address(0)) {
            revert ERC1155_BURN_FROM_ZERO_ADDRESS();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), id, amount, "");

        uint256 fromBalance = _balances[id][from];

        if (fromBalance < amount) {
            revert ERC1155_BURN_AMOUNT_EXCEEDS_BALANCE();
        }
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), id, amount, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        if (from == address(0)) {
            revert ERC1155_BURN_FROM_ZERO_ADDRESS();
        }

        uint256 numIds = ids.length;

        if (numIds != amounts.length) {
            revert ERC1155_IDS_AND_AMOUNTS_LENGTH_MISMATCH();
        }

        address operator = _msgSender();

        _beforeBatchTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 id;
        uint256 amount;
        uint256 fromBalance;
        for (uint256 i; i < numIds; ) {
            id = ids[i];
            amount = amounts[i];

            fromBalance = _balances[id][from];

            if (fromBalance < amount) {
                revert ERC1155_BURN_AMOUNT_EXCEEDS_BALANCE();
            }

            unchecked {
                _balances[id][from] = fromBalance - amount;

                ++i;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterBatchTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (owner == operator) {
            revert ERC1155_SETTING_APPROVAL_FOR_SELF();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before a single token transfer.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual { }


    /**
     * @dev Hook that is called before a batch token transfer.
     */
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after a single token transfer.
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after a batch token transfer.
     */
    function _afterBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert ERC1155_ERC1155RECEIVER_REJECTED_TOKENS();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155_TRANSFER_TO_NON_ERC1155RECEIVER_IMPLEMENTER();
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert ERC1155_ERC1155RECEIVER_REJECTED_TOKENS();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155_TRANSFER_TO_NON_ERC1155RECEIVER_IMPLEMENTER();
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}
