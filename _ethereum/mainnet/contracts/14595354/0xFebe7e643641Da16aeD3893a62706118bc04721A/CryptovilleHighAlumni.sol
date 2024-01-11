// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./ERC165.sol";
import "./draft-EIP712.sol";
import "./SignatureChecker.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";
import "./Strings.sol";

import "./ProxyRegistry.sol";

error TokenOwnerQueryForInvalidToken();
error BalanceQueryForZeroAddress();
error ReservedTokenSupplyExhausted();
error SupplyInitRevealedTokensWhileInitUnrevealedMintingNotPaused();
error InitRevealedTokenSupplyExhausted();
error MintToZeroAddress();
error MintWithInvalidSignature();
error MintRevealedTokenDoesNotSupportReservedTokens();
error MintRevealedTokenInsufficientFund();
error MintRevealedTokenIdIsInvalid();
error MintRevealedTokenIsMinted();
error InitUnrevealedTokenMintingIsPaused();
error MintUnrevealedTokenInsufficientFund();
error MintUnrevealedTokenQuantityExceedsSupply();
error MintUnrevealedTokenQuantityIsProhibited();
error ApproveToTokenOwner();
error ApproveCallerIsNotOwnerNorApprovedForAll();
error ApprovedOperatorQueryForNonexistentToken();
error SetApprovalForAllTargetOperatorIsCaller();
error TransferInvalidToken();
error TransferFromIncorrectOwner();
error TransferFromZeroAddress();
error TransferToZeroAddress();
error TransferCallerIsNotOwnerNorApproved();
error TransferToNonERC721ReceiverImplementer();
error TokenUriQueryForNonexistentToken();
error WithdrawalFailed();

contract CryptovilleHighAlumni is
    ERC165,
    IERC721,
    IERC721Metadata,
    EIP712,
    Ownable
{
    using Strings for uint256;
    using Address for address;

    struct TokenOwnerData {
        uint64 balance;
        bool giveawayOfferClaimed;
    }

    /**
     * @dev Emitted when the state variable `nextRevealedTokenId` has been
     * updated to `newValue` from the old value `newValue` - `delta`.
     */
    event NextRevealedTokenIdChange(
        uint256 indexed newValue,
        uint256 indexed delta
    );

    /**
     * @dev Emitted when the state variable `nextInitUnrevealedTokenId` has
     * been updated to `newValue` from `oldValue`.
     */
    event NextInitUnrevealedTokenIdChange(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    string private _name = "Cryptoville High Alumni";
    string private _symbol = "CHA";
    address private _proxyRegistryAddress;
    bool private _proxyRegistryEnabled = true;

    mapping(uint256 => address) private _ownerships;
    mapping(address => TokenOwnerData) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => bool) private _canSign;

    string private _metadataBaseUri;
    string private constant _unrevealedMetadataUri =
        "ipfs://bafkreigzl4khqp5v3g2ix4bnitmatsdd33goypayocmszlvlmruf4qepue";

    /** @dev Token IDs are seqential integers starting from `_startTokenId`. */
    uint256 private constant _startTokenId = 1;
    uint256 private constant _maxTotalSupply = 10000;
    uint256 private constant _numInitRevealed = 8000;
    uint256 private constant _lastReservedTokenId = 1000;

    uint256 private constant _revealedMintGiveawayQuantity = 1;
    uint256 private constant _maxInitUnrevealedBatchMintSize = 10;

    /** @dev Whether minting for initially unrevealed tokens is paused. */
    bool public initUnrevealedMintingPaused;
    uint256 private _nextReservedTokenId = 201;

    /**
     * @notice ID for the next initially unrevealed token to be minted.
     * @dev Only decrementable.
     * @dev _maxTotalSupply - nextInitUnrevealedTokenId
     *      = number of initially unrevealed tokens minted
     * @dev nextInitUnrevealedTokenId - nextRevealedTokenId + 1
     *      = number of initially unrevealed tokens that are mintable
     */
    uint256 public nextInitUnrevealedTokenId = _maxTotalSupply;

    /**
     * @notice ID for the next initially revealed token that can be made
     * available for sale.
     * @dev Only incrementable.
     * @dev nextRevealedTokenId - 1
     *      = maximum number of initially revealed tokens that can be in
     *        circulation
     * @dev nextInitUnrevealedTokenId - nextRevealedTokenId + 1
     *      = maximum number of initially revealed tokens that can be further
     *        supplied by the deployer/issuer
     */
    uint256 public nextRevealedTokenId = 8001;

    /**
     * @notice Initializes the contract for the NFT collection with limited
     * supply.
     */
    constructor(string memory baseUri, address proxyRegistryAddress)
        EIP712(_name, "1.0.0")
    {
        for (uint256 id = _startTokenId; id < _nextReservedTokenId; id++) {
            emit Transfer(address(0), owner(), id);
        }
        _owners[address(0)].balance += uint64(_nextReservedTokenId - 1);
        _canSign[owner()] = true;
        _metadataBaseUri = baseUri;
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    /**
     * @notice Returns the maximum number of tokens that can be in circulation
     * at any time.
     */
    function totalSupply() public pure returns (uint256) {
        return _maxTotalSupply;
    }

    function setCanSign(address signer, bool allowed) public onlyOwner {
        _canSign[signer] = allowed;
    }

    function enableProxyRegistry(bool enabled) public onlyOwner {
        _proxyRegistryEnabled = enabled;
    }

    /**
     * @notice Enables/disables minting of initially unrevealed tokens.
     * @dev Must be disabled before supplying initially revealed tokens, which
     * automatically enables minting of initially unrevealed tokens when
     * the incremental supply of initially revealed tokens is completed.
     */
    function pauseInitUnrevealedTokenMinting(bool paused) public onlyOwner {
        initUnrevealedMintingPaused = paused;
    }

    /** @dev Use it to just check if `id` falls within the admissible range. */
    function _validTokenId(uint256 id) private pure returns (bool) {
        return _startTokenId <= id && id <= _maxTotalSupply;
    }

    function _initUnrevealedOwnerOf(uint256 tokenId)
        private
        view
        returns (address)
    {
        unchecked {
            address owner;
            uint256 currId = tokenId;
            for (uint256 i = 0; i < _maxInitUnrevealedBatchMintSize; i++) {
                owner = _ownerships[currId++];
                if (owner != address(0)) {
                    return owner;
                }
            }
        }
        revert TokenOwnerQueryForInvalidToken();
    }

    /**
     * @notice Returns the owner of the token identified by `tokenId` if it
     * maps to a token that has been revealed and in circulation (including
     * tokens that are initially unrevealed at deployment); reverts otherwise.
     * @dev Tokens that have an ID not exceeding `lastReservedTokenId` and are
     * still available for sale in the primary market are owned by the
     * deployer/issuer.
     * @dev Owner query for any invalid or unminted token ID reverts.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (tokenId != 0 && tokenId < nextRevealedTokenId) {
            address tokenOwner = _ownerships[tokenId];
            if (tokenOwner == address(0)) {
                if (tokenId < _nextReservedTokenId) {
                    return owner();
                }
                revert TokenOwnerQueryForInvalidToken();
            }
            return tokenOwner;
        }
        if (nextInitUnrevealedTokenId < tokenId && tokenId <= _maxTotalSupply) {
            return _initUnrevealedOwnerOf(tokenId);
        }
        revert TokenOwnerQueryForInvalidToken();
    }

    /**
     * @notice Returns the number of tokens owned by `tokenOwner`.
     * @dev `tokenOwner` must not be the zero address, for which any query
     * reverts.
     */
    function balanceOf(address tokenOwner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (tokenOwner == address(0)) revert BalanceQueryForZeroAddress();
        uint64 balance = _owners[tokenOwner].balance;
        if (tokenOwner == owner()) {
            balance += _owners[address(0)].balance;
        }
        return uint256(balance);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @notice Makes the next `quantity` number of (initially revealed)
     * reserved tokens available for sale in the primary market.
     * @dev If `quantity` exceeds the total number of mintable reserved tokens
     * available, it would be decremented to align with such amount.
     * @dev `quantity==0` does not revert if supply has not been exhausted.
     */
    function mintReservedTokens(uint256 quantity) public onlyOwner {
        if (_nextReservedTokenId > _lastReservedTokenId) {
            revert ReservedTokenSupplyExhausted();
        }
        uint256 maxQuantity = _lastReservedTokenId + 1 - _nextReservedTokenId;
        if (quantity > maxQuantity) {
            quantity = maxQuantity;
        }

        uint256 newNextId = _nextReservedTokenId + quantity;
        address to = owner();
        for (uint256 id = _nextReservedTokenId; id < newNextId; id++) {
            emit Transfer(address(0), to, id);
        }
        _owners[address(0)].balance += uint64(quantity);
        _nextReservedTokenId = newNextId;
    }

    function _maxInitUnrevealedMintable() private view returns (uint256) {
        return nextInitUnrevealedTokenId + 1 - nextRevealedTokenId;
    }

    /**
     * @notice Provides an additional `quantity` number of initially revealed
     * tokens for sale in the primary market, hence decreasing the supply of
     * initially unrevealed tokens.
     * @dev Reverts if minting of initially unrevealed tokens is not paused
     * before executing the incremental supply.
     * @dev If `quantity` exceeds the total number of mintable tokens available,
     * it would be decremented to align with such amount.
     * @dev `quantity==0` does not revert if supply has not been exhausted.
     */
    function supplyInitRevealedTokens(uint256 quantity) public onlyOwner {
        if (!initUnrevealedMintingPaused) {
            revert SupplyInitRevealedTokensWhileInitUnrevealedMintingNotPaused();
        }
        uint256 maxQuantity = _maxInitUnrevealedMintable();
        if (quantity > maxQuantity) {
            quantity = maxQuantity;
        }
        nextRevealedTokenId += quantity;
        initUnrevealedMintingPaused = false;
        emit NextRevealedTokenIdChange(nextRevealedTokenId, quantity);
    }

    /**
     * @notice Returns `true` if the token identified by `tokenId` is initally
     * revealed and is available in the primary market at the moment of this
     * query.
     */
    function isInitRevealedAndInPrimaryMarket(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return
            _ownerships[tokenId] == address(0) &&
            ((_lastReservedTokenId < tokenId &&
                tokenId < nextRevealedTokenId) ||
                (_startTokenId <= tokenId && tokenId < _nextReservedTokenId));
    }

    /**
     * @notice Mints the initially revealed token that is identified by
     * `tokenId` and transfers it to the address `to`. `tokenId` must be in
     * either of the ranges [`_startTokenId`, `_nextReservedTokenId` - 1] or
     * [`lastReservedTokenId` + 1, `nextRevealedTokenId` - 1]. A minting fee
     * of `minPrice` wei applies and is payable by the message sender.
     * A successful mint may receive the giveaway offer of at most
     * `_revealedMintGiveawayQuantity` number of initially unrevealed tokens
     * in limited time while supply lasts and on a first-come-first-served
     * basis. Each wallet address is eligible for this offer only once.
     * Minting by a contract is not eligible for this offer. Giveaway offers
     * cannot be fulfilled when minting for initially unrevealed tokens is
     * paused. To check the status, use `initUnrevealedMintingPaused`.
     */
    function mintRevealedToken(
        uint256 tokenId,
        uint256 minPrice,
        address to,
        bytes32 nonce,
        address signer,
        bytes calldata signature
    ) public payable {
        if (to != owner()) {
            if (msg.value < minPrice) {
                revert MintRevealedTokenInsufficientFund();
            }
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 tokenId,uint256 minPrice,address to,bytes32 nonce)"
                        ),
                        tokenId,
                        minPrice,
                        to,
                        nonce
                    )
                )
            );
            if (
                !_canSign[signer] ||
                !SignatureChecker.isValidSignatureNow(signer, digest, signature)
            ) {
                revert MintWithInvalidSignature();
            }
        }
        _safeMintRevealed(to, tokenId, "");
    }

    function _safeMintRevealed(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private {
        if (tokenId < _startTokenId || tokenId >= nextRevealedTokenId) {
            revert MintRevealedTokenIdIsInvalid();
        }

        if (
            _nextReservedTokenId <= tokenId && tokenId <= _lastReservedTokenId
        ) {
            revert MintRevealedTokenDoesNotSupportReservedTokens();
        }

        if (_ownerships[tokenId] != address(0)) {
            revert MintRevealedTokenIsMinted();
        }

        if (to == address(0)) revert MintToZeroAddress();

        bool notExceedingLastReservedTokenId = tokenId <= _lastReservedTokenId;
        address from = notExceedingLastReservedTokenId ? owner() : address(0);

        _tokenApprovals[tokenId] = address(0);

        if (notExceedingLastReservedTokenId) {
            _owners[address(0)].balance -= 1;
        }
        _owners[to].balance += 1;
        _ownerships[tokenId] = to;

        emit Transfer(from, to, tokenId);

        if (
            to.isContract() && !_checkOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }

        _claimGiveawayOffer(to, _revealedMintGiveawayQuantity);
    }

    function _claimGiveawayOffer(address to, uint256 quantity) private {
        if (
            !initUnrevealedMintingPaused &&
            !to.isContract() &&
            !_owners[to].giveawayOfferClaimed &&
            nextInitUnrevealedTokenId >= nextRevealedTokenId
        ) {
            _safeMintUnrevealed(to, quantity, "");
            _owners[to].giveawayOfferClaimed = true;
        }
    }

    /**
     * @notice Mints `quantity` number of initially unrevealed tokens and
     * transfers all minted tokens to the address `to`, subject to a maximum
     * quantity of `_maxInitUnrevealedBatchMintSize` per transaction.
     * A miniting fee of `unitPrice` wei per token applies and is payable by
     * the message sender.
     * @dev `to` cannot be the zero address.
     * @dev `quantity` must be greater than 0 and no larger than
     * `_maxInitUnrevealedBatchMintSize`.
     * @dev Reverts if `quantity` exceeds the maximum possible supply of
     * initially unrevealed tokens. To check the number of initially unrevealed
     * tokens that are mintable, see `nextInitUnrevealedTokenId`.
     */
    function mintUnrevealedToken(
        uint256 quantity,
        uint256 unitPrice,
        address to,
        bytes32 nonce,
        address signer,
        bytes calldata signature
    ) public payable {
        if (
            nextInitUnrevealedTokenId < nextRevealedTokenId ||
            quantity > _maxInitUnrevealedMintable()
        ) {
            revert MintUnrevealedTokenQuantityExceedsSupply();
        }
        if (to != owner()) {
            if (msg.value < quantity * unitPrice) {
                revert MintUnrevealedTokenInsufficientFund();
            }
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BatchVoucher(bytes32 nonce,uint256 quantity,address to,uint256 unitPrice)"
                        ),
                        nonce,
                        quantity,
                        to,
                        unitPrice
                    )
                )
            );
            if (
                !_canSign[signer] ||
                !SignatureChecker.isValidSignatureNow(signer, digest, signature)
            ) {
                revert MintWithInvalidSignature();
            }
        }
        _safeMintUnrevealed(to, quantity, "");
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        if (!sent) revert WithdrawalFailed();
    }

    function _safeMintUnrevealed(
        address to,
        uint256 quantity,
        bytes memory _data
    ) private {
        if (initUnrevealedMintingPaused) {
            revert InitUnrevealedTokenMintingIsPaused();
        }

        if (quantity == 0 || quantity > _maxInitUnrevealedBatchMintSize) {
            revert MintUnrevealedTokenQuantityIsProhibited();
        }

        if (to == address(0)) revert MintToZeroAddress();

        uint256 maxQuantity = _maxInitUnrevealedMintable();
        if (quantity > maxQuantity) {
            quantity = maxQuantity;
        }

        uint256 firstTokenId = nextInitUnrevealedTokenId;
        unchecked {
            _owners[to].balance += uint64(quantity);
            _ownerships[firstTokenId] = to;

            uint256 currTokenId = firstTokenId;
            uint256 lastTokenId = currTokenId - quantity;
            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, currTokenId);
                    if (
                        !_checkOnERC721Received(
                            address(0),
                            to,
                            currTokenId--,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (currTokenId != lastTokenId);
                if (nextInitUnrevealedTokenId != firstTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, currTokenId--);
                } while (currTokenId != lastTokenId);
            }
            nextInitUnrevealedTokenId = currTokenId;
            emit NextInitUnrevealedTokenIdChange(currTokenId, firstTokenId);
        }
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApproveToTokenOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApproveCallerIsNotOwnerNorApprovedForAll();
        }

        _approve(to, tokenId, owner);
    }

    /** @dev See {IERC721-getApproved}. */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_validTokenId(tokenId)) {
            revert ApprovedOperatorQueryForNonexistentToken();
        }

        return _tokenApprovals[tokenId];
    }

    /** @dev See {IERC721-setApprovalForAll}. */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (_msgSender() == operator) {
            revert SetApprovalForAllTargetOperatorIsCaller();
        }

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /** @dev See {IERC721-isApprovedForAll}. */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (_proxyRegistryEnabled) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return _operatorApprovals[owner][operator];
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        if (
            _msgSender() != from &&
            !isApprovedForAll(from, _msgSender()) &&
            getApproved(tokenId) != _msgSender()
        ) revert TransferCallerIsNotOwnerNorApproved();

        if (
            from == owner() &&
            _ownerships[tokenId] == address(0) &&
            tokenId < _nextReservedTokenId
        ) {
            return _safeMintRevealed(to, tokenId, "");
        }

        if (!_validTokenId(tokenId)) revert TransferInvalidToken();

        if (from == address(0)) revert TransferFromZeroAddress();

        address prevOwner = tokenId <= nextInitUnrevealedTokenId
            ? _ownerships[tokenId]
            : _initUnrevealedOwnerOf(tokenId);
        if (prevOwner != from) revert TransferFromIncorrectOwner();

        if (to == address(0)) revert TransferToZeroAddress();

        _approve(address(0), tokenId, from);

        unchecked {
            _owners[from].balance -= 1;
            _owners[to].balance += 1;
            _ownerships[tokenId] = to;

            if (tokenId > nextInitUnrevealedTokenId) {
                uint256 prevTokenId = tokenId - 1;
                if (
                    prevTokenId > nextInitUnrevealedTokenId &&
                    _ownerships[prevTokenId] == address(0)
                ) {
                    _ownerships[prevTokenId] = from;
                }
            }
        }
        emit Transfer(from, to, tokenId);
    }

    /** @dev See {IERC721-transferFrom}. */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /** @dev See {IERC721-safeTransferFrom}. */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /** @dev See {IERC721-safeTransferFrom}. */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (
            to.isContract() && !_checkOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /** @dev See {IERC721Metadata-name}. */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /** @dev See {IERC721Metadata-symbol}. */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /** @dev See {IERC721Metadata-tokenURI}. */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_validTokenId(tokenId)) {
            revert TokenUriQueryForNonexistentToken();
        }

        if (
            tokenId < nextRevealedTokenId || tokenId > nextInitUnrevealedTokenId
        ) {
            string memory baseURI = _metadataBaseUri;
            return
                bytes(baseURI).length != 0
                    ? string(abi.encodePacked(baseURI, tokenId.toString()))
                    : "";
        }
        return _unrevealedMetadataUri;
    }

    /** @dev See {IERC165-supportsInterface}. */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}