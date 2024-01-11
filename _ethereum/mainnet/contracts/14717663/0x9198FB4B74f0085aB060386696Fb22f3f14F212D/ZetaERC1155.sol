//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./Strings.sol";
import "./AccessControlEnumerable.sol";

import "./IZetaToken.sol";
import "./IVendingMachine.sol";
import "./Errors.sol";
import "./ZetaFallback.sol";

contract ZetaERC1155 is
    Context,
    ERC165,
    IERC1155,
    IERC1155MetadataURI,
    AccessControlEnumerable,
    ZetaFallback
{
    using Address for address;

    bytes32 public constant DEPLOYER = keccak256("DEPLOYER");
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    // // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 public globalLimitPerWallet;
    mapping(uint256 => uint256) tokenLimitPerWallet;

    mapping(address => uint256) private mintedPerWallet;

    mapping(address => mapping(uint256 => uint256))
        private mintedTokensPerWallet;

    IZetaToken[] private _tokensContracts;

    string private _uri;
    string private _name;
    string private _symbol;

    constructor(string memory initialName, string memory initialSymbol) {
        _setupRole(OPERATOR, _msgSender());
        _setupRole(DEPLOYER, _msgSender());
        _setRoleAdmin(OPERATOR, DEPLOYER);
        _name = initialName;
        _symbol = initialSymbol;
    }

    function setTokenContract(uint256 id, address contractAddress)
        public
        onlyRole(DEPLOYER)
    {
        if (!contractAddress.isContract()) {
            revert ContractAddressIsNotAContract();
        }

        if (id > _tokensContracts.length) {
            revert UnknownTokenId();
        }

        if (id == _tokensContracts.length) {
            _tokensContracts.push(IZetaToken(payable(contractAddress)));
        } else {
            _tokensContracts[id] = IZetaToken(payable(contractAddress));
        }
    }

    function setLimitPerWallet(uint256 _limitPerWallet)
        public
        onlyRole(DEPLOYER)
    {
        globalLimitPerWallet = _limitPerWallet;
    }

    function limitPerWalletByToken(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return tokenLimitPerWallet[tokenId];
    }

    function setTokenLimitPerWallet(uint256 tokenId, uint256 _limitPerWallet)
        public
        onlyRole(DEPLOYER)
    {
        tokenLimitPerWallet[tokenId] = _limitPerWallet;
    }

    function mintedTokensPerWalletByToken(uint256 tokenId, address wallet)
        public
        view
        returns (uint256)
    {
        return mintedTokensPerWallet[wallet][tokenId];
    }

    function minted(address wallet) public view returns (uint256) {
        return mintedPerWallet[wallet];
    }

    function tokenContract(uint256 id) external view returns (address) {
        if (id >= _tokensContracts.length) {
            revert UnknownTokenId();
        }
        return address(_tokensContracts[id]);
    }

    function canPerform(address account, string calldata action)
        public
        view
        returns (bool)
    {
        bool result = false;

        for (uint256 id = 0; id < _tokensContracts.length; id++) {
            result = result || _tokensContracts[id].canPerform(account, action);
        }

        return result;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(AccessControlEnumerable).interfaceId ||
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
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (id >= _tokensContracts.length) {
            revert UnknownTokenId();
        }

        return string(abi.encodePacked(_uri, Strings.toString(id), ".json"));
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        if (id >= _tokensContracts.length) {
            revert UnknownTokenId();
        }
        return _tokensContracts[id].totalSupply();
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (account == address(0)) {
            revert BalanceQueryForTheZeroAddress();
        }

        if (id >= _tokensContracts.length) {
            revert UnknownTokenId();
        }
        return _tokensContracts[id].balanceOf(account);
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) {
            revert AccountsAndIdsLengthMismatch();
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        if (!(from == _msgSender() || isApprovedForAll(from, _msgSender()))) {
            revert CallerIsNotOwnerNorApproved();
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
        if (!(from == _msgSender() || isApprovedForAll(from, _msgSender()))) {
            revert CallerIsNotOwnerNorApproved();
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
            revert TransferToTheZeroAddress();
        }

        if (id >= _tokensContracts.length) {
            revert UnknownTokenId();
        }

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        _tokensContracts[id].decreaseBalance(from, amount);
        _tokensContracts[id].increaseBalance(to, amount);

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        if (ids.length != amounts.length) {
            revert IdsAndAmountsLengthMismatch();
        }

        if (to == address(0)) {
            revert TransferToTheZeroAddress();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (id >= _tokensContracts.length) {
                revert UnknownTokenId();
            }
            _tokensContracts[id].decreaseBalance(from, amount);
            _tokensContracts[id].increaseBalance(to, amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
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
    function setURI(string memory newuri) public onlyRole(DEPLOYER) {
        _uri = newuri;
    }

    function setName(string memory newName) public onlyRole(DEPLOYER) {
        _name = newName;
    }

    function setSymbol(string memory newSymbol) public onlyRole(DEPLOYER) {
        _symbol = newSymbol;
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
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyRole(OPERATOR) {
        if (to == address(0)) {
            revert MintToTheZeroAddress();
        }

        if (id >= _tokensContracts.length) {
            revert UnknownTokenId();
        }

        if (
            tokenLimitPerWallet[id] != 0 &&
            mintedTokensPerWallet[to][id] + amount > tokenLimitPerWallet[id]
        ) {
            revert ExhaustedWalletAllowance();
        }

        if (
            globalLimitPerWallet != 0 &&
            mintedPerWallet[to] + amount > globalLimitPerWallet
        ) {
            revert ExhaustedWalletAllowance();
        }

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _tokensContracts[id].increaseBalance(to, amount);
        _tokensContracts[id].increaseTotalSupply(amount);
        mintedPerWallet[to] += amount;
        mintedTokensPerWallet[to][id] += amount;

        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external virtual onlyRole(OPERATOR) {
        if (to == address(0)) {
            revert MintToTheZeroAddress();
        }

        if (ids.length != amounts.length) {
            revert IdsAndAmountsLengthMismatch();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        uint256 totalToBeMinted = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] >= _tokensContracts.length) {
                revert UnknownTokenId();
            }

            if (
                tokenLimitPerWallet[ids[i]] != 0 &&
                mintedTokensPerWallet[to][ids[i]] + amounts[i] >
                tokenLimitPerWallet[ids[i]]
            ) {
                revert ExhaustedWalletAllowance();
            }

            totalToBeMinted += amounts[i];
        }

        if (
            globalLimitPerWallet != 0 &&
            mintedPerWallet[to] + totalToBeMinted > globalLimitPerWallet
        ) {
            revert ExhaustedWalletAllowance();
        }

        for (uint256 i = 0; i < ids.length; i++) {
            _tokensContracts[ids[i]].increaseBalance(to, amounts[i]);
            _tokensContracts[ids[i]].increaseTotalSupply(amounts[i]);
            mintedPerWallet[to] += amounts[i];
            mintedTokensPerWallet[to][ids[i]] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual onlyRole(DEPLOYER) {
        if (from == address(0)) {
            revert BurnFromTheZeroAddress();
        }

        if (id >= _tokensContracts.length) {
            revert UnknownTokenId();
        }

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        _tokensContracts[id].decreaseBalance(from, amount);
        _tokensContracts[id].decreaseTotalSupply(amount);

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual onlyRole(DEPLOYER) {
        if (from == address(0)) {
            revert BurnFromTheZeroAddress();
        }
        if (ids.length != amounts.length) {
            revert IdsAndAmountsLengthMismatch();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (id >= _tokensContracts.length) {
                revert UnknownTokenId();
            }
            _tokensContracts[id].decreaseBalance(from, amount);
            _tokensContracts[id].decreaseTotalSupply(amount);
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

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
        bool approved
    ) internal virtual {
        if (owner == operator) {
            revert SettingApprovalStatusForSelf();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
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
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

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

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert TransferToNonERC1155ReceiverImplementer();
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
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert ERC1155ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert TransferToNonERC1155ReceiverImplementer();
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
