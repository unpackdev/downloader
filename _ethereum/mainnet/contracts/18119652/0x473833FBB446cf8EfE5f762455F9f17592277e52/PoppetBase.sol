// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ERC721A.sol";

import "./ICurios.sol";
import "./IJournal.sol";

import "./ERC2981.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

import "./Ownable.sol";

import "./RevokableDefaultOperatorFilterer.sol";
import "./UpdatableOperatorFilterer.sol";

import "./IERC4906.4.9.2.sol";

import "./IERC5192.sol";

import "./PoppetSignatureChecks.sol";

import "./PoppetErrorsAndEvents.sol";
import "./PoppetStructs.sol";

contract PoppetBase is
    PoppetErrorsAndEvents,
    PoppetStructs,
    PoppetEIP712,
    ERC721A,
    IERC4906,
    IERC5192,
    ERC2981,
    RevokableDefaultOperatorFilterer,
    Ownable,
    ERC721Holder,
    ERC1155Holder
{
    uint80 public SWAP_PRICE;

    uint80 public REVEAL_PRICE;

    address public CURIOS;

    address public COMMUNITY_CURIOS;

    address public JOURNAL;

    address private _receiver;

    address public WINTER;

    ThreadConfig public config;

    string public baseURI;

    address public PACKS;

    mapping(uint256 => bool) private _locked;

    constructor(
        string memory name_,
        string memory symbol_,
        address signer_,
        string memory uri_
    ) ERC721A(name_, symbol_) PoppetEIP712(name_, signer_) {
        _receiver = msg.sender;
        _setBaseURI(uri_);
    }

    // ███    ███  ██████  ██████  ██ ███████ ██ ███████ ██████  ███████
    // ████  ████ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██ ██
    // ██ ████ ██ ██    ██ ██   ██ ██ █████   ██ █████   ██████  ███████
    // ██  ██  ██ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██      ██
    // ██      ██  ██████  ██████  ██ ██      ██ ███████ ██   ██ ███████

    modifier onlyPoppetOwner(uint256 tokenId) {
        if (_msgSender() != ownerOf(tokenId)) {
            revert InsufficientPermissions();
        }
        _;
    }

    modifier onlyPoppetOwnerIfUnlocked(uint256 tokenId) {
        if (_msgSender() != ownerOf(tokenId)) {
            revert InsufficientPermissions();
        }
        if (_locked[tokenId]) {
            revert LockedToken();
        }
        _;
    }

    modifier activeThreadOnly() {
        if (config.maxTokenId < _nextTokenId()) {
            revert ExceedsMaxSupply();
        }
        if (block.timestamp > config.endTimestamp) {
            revert ThreadNotActive();
        }
        _;
    }

    modifier quantityAvailable(uint256 quantity) {
        if (_nextTokenId() + quantity > config.maxTokenId) {
            revert ExceedsMaxSupply();
        }
        _;
    }

    modifier unlockedOrOwner(uint256 tokenId) {
        if (_locked[tokenId]) {
            if (_msgSender() != owner()) {
                revert LockedToken();
            }
        }
        _;
    }

    //  █████  ██████  ███    ███ ██ ███    ██
    // ██   ██ ██   ██ ████  ████ ██ ████   ██
    // ███████ ██   ██ ██ ████ ██ ██ ██ ██  ██
    // ██   ██ ██   ██ ██  ██  ██ ██ ██  ██ ██
    // ██   ██ ██████  ██      ██ ██ ██   ████

    function setSigner(address signer_) external payable onlyOwner {
        _setSigner(signer_);
    }

    function setCuriosAddress(address curios_) external payable onlyOwner {
        _setCuriosAddress(curios_);
    }

    function _setCuriosAddress(address curios) internal {
        CURIOS = curios;
    }

    function setCommunityCuriosAddress(
        address curios_
    ) external payable onlyOwner {
        _setCommunityCuriosAddress(curios_);
    }

    function _setCommunityCuriosAddress(address curios) internal {
        COMMUNITY_CURIOS = curios;
    }

    function setWinterAddress(address winter_) external payable onlyOwner {
        _setWinterAddress(winter_);
    }

    function _setWinterAddress(address winter) internal {
        WINTER = winter;
    }

    function setJournalAddress(address journal_) external payable onlyOwner {
        _setJournalAddress(journal_);
    }

    function _setJournalAddress(address journal) internal {
        JOURNAL = journal;
    }

    function _setBaseURI(string memory uri_) internal {
        baseURI = uri_;
    }

    function setBaseURI(string calldata uri_) external payable onlyOwner {
        _setBaseURI(uri_);
        emit BatchMetadataUpdate(1, _nextTokenId() - 1);
    }

    function setSwapPrice(uint80 swapPrice_) external payable onlyOwner {
        _setSwapPrice(swapPrice_);
    }

    function _setSwapPrice(uint80 swapPrice_) internal {
        SWAP_PRICE = swapPrice_;
    }

    function setRevealPrice(uint80 revealPrice_) external payable onlyOwner {
        _setRevealPrice(revealPrice_);
    }

    function _setRevealPrice(uint80 revealPrice_) internal {
        REVEAL_PRICE = revealPrice_;
    }

    function setPacksAddress(address packs_) external payable onlyOwner {
        _setPackAddress(packs_);
    }

    function _setPackAddress(address packs_) internal {
        PACKS = packs_;
    }

    function disableJournalEntry(
        uint256 tokenId,
        string calldata ipfs_cid
    ) external payable onlyOwner {
        emit JournalEntryDisabled(tokenId, ipfs_cid);
    }

    function createNewThread(
        uint publicMintPrice,
        uint signedMintPrice,
        uint supply,
        uint endTimestamp
    ) external payable onlyOwner {
        unchecked {
            ++config.currentThreadId;
        }
        config.publicMintPrice = uint80(publicMintPrice);
        config.signedMintPrice = uint80(signedMintPrice);
        config.maxTokenId = uint16(_nextTokenId() + supply);
        config.endTimestamp = uint40(endTimestamp);
        config.threadSeed = uint24(
            uint256(
                keccak256(
                    abi.encodePacked(config.threadSeed, config.currentThreadId)
                )
            ) % (2 ** 24 - 1)
        );

        uint256 team_supply = supply / 20;

        if (team_supply > 0) {
            _mint(owner(), team_supply);
        } else {
            _mint(owner(), 1);
        }

        emit ThreadStarted(
            config.currentThreadId,
            config.endTimestamp,
            config.threadSeed
        );
    }

    //     ███    ███  ██████  ███    ███ ████████
    //     ████  ████ ██       ████  ████    ██
    //     ██ ████ ██ ██   ███ ██ ████ ██    ██
    //     ██  ██  ██ ██    ██ ██  ██  ██    ██
    //     ██      ██  ██████  ██      ██    ██

    /**
     * @notice Swaps Curios (accessories) tokens between the contract and a specified owner in batches
     * @dev Creating the amounts arrays off-chain is WAY cheaper than doing so on EVM and it's not mysterious
     * @param _owner The address of the owner to swap tokens with.
     * @param remove An array of token IDs to remove from the contract.
     * @param removeAmounts An array of amounts for each token ID to remove. Should be [1,1...] with length of remove
     * @param add An array of token IDs to add to the contract.
     * @param addAmounts An array of amounts for each token ID to add. Should be [1,1...] with length of add
     */
    function _swapCurios(
        address _owner,
        address _tokenAccount,
        uint256[] calldata remove,
        uint256[] calldata removeAmounts,
        uint256[] calldata add,
        uint256[] calldata addAmounts
    ) internal {
        if (remove.length > 0) {
            ICurios(CURIOS).safeBatchTransferFrom(
                _tokenAccount,
                _owner,
                remove,
                removeAmounts,
                ""
            );
        }
        if (add.length > 0) {
            ICurios(CURIOS).safeBatchTransferFrom(
                _owner,
                _tokenAccount,
                add,
                addAmounts,
                ""
            );
        }
    }

    /**
     * @notice Swaps Curios (accessories) tokens between the contract and a specified owner in batches
     * @dev Creating the amounts arrays off-chain is WAY cheaper than doing so on EVM and it's not mysterious
     * @param _owner The address of the owner to swap tokens with.
     * @param remove An array of token IDs to remove from the contract.
     * @param removeAmounts An array of amounts for each token ID to remove. Should be [1,1...] with length of remove
     * @param add An array of token IDs to add to the contract.
     * @param addAmounts An array of amounts for each token ID to add. Should be [1,1...] with length of add
     */
    function _swapCommunityCurios(
        address _owner,
        address _tokenAccount,
        uint256[] calldata remove,
        uint256[] calldata removeAmounts,
        uint256[] calldata add,
        uint256[] calldata addAmounts
    ) internal {
        if (remove.length > 0) {
            ICurios(COMMUNITY_CURIOS).safeBatchTransferFrom(
                _tokenAccount,
                _owner,
                remove,
                removeAmounts,
                ""
            );
        }
        if (add.length > 0) {
            ICurios(COMMUNITY_CURIOS).safeBatchTransferFrom(
                _owner,
                _tokenAccount,
                add,
                addAmounts,
                ""
            );
        }
    }

    function _reveal(uint256[] memory tokenIds) internal {
        emit PoppetsRevealed(_msgSender(), tokenIds);
    }

    // ███    ███ ██ ███    ██ ████████
    // ████  ████ ██ ████   ██    ██
    // ██ ████ ██ ██ ██ ██  ██    ██
    // ██  ██  ██ ██ ██  ██ ██    ██
    // ██      ██ ██ ██   ████    ██

    function mintFromWinter(address to_, uint amt) public payable {
        if (_msgSender() != WINTER) {
            revert InsufficientPermissions();
        }
        _mint(to_, amt);
    }

    //  ██████  ███████ ████████ ████████ ███████ ██████  ███████
    // ██       ██         ██       ██    ██      ██   ██ ██
    // ██   ███ █████      ██       ██    █████   ██████  ███████
    // ██    ██ ██         ██       ██    ██      ██   ██      ██
    //  ██████  ███████    ██       ██    ███████ ██   ██ ███████

    function _getConfig() internal view returns (ThreadConfig storage) {
        return config;
    }

    function _getPublicPrice() external view returns (uint) {
        return config.publicMintPrice;
    }

    function _getSignedPrice() external view returns (uint) {
        return config.signedMintPrice;
    }

    /*
        We're just going to treat tokenIds as accounts - the odds of someone having
        the private key to 0x00..1 through 0x00..ffff or whatever are infinitesmally low.
    */
    function _getTokenAccount(uint256 tokenId) internal pure returns (address) {
        // 00000000005f3dd0d326e1d00000000000000000
        return address(uint160(494521973352776966419055802073481216 + tokenId));
    }

    //  ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████
    // ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██
    // ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████
    // ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██
    //  ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████
    //
    // Functions that override ERC-standards, primarily for the OS Operator Filter
    // and soulbound tokens

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool) {
        return _locked[tokenId];
    }

    function lock(uint256 tokenId) external onlyPoppetOwner(tokenId) {
        _locked[tokenId] = true;
        emit Locked(tokenId);
    }

    function unlock(uint256 tokenId) external onlyOwner {
        _locked[tokenId] = false;
        emit Unlocked(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address,
        address,
        uint24 previousExtraData
    ) internal view override returns (uint24) {
        // Revert if the current block isn't 48 hours after the previous extraData (12 seconds = 1 block)
        unchecked {
            if (
                previousExtraData != 0 &&
                uint24(previousExtraData + 14400) > uint24(block.number)
            ) {
                revert CooldownNotComplete();
            }
        }

        return previousExtraData;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * Overrides here include checks for individual token supply limits, tracking
     * totalSupply for each token,
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from == address(0)) {
            // Minting - make sure totalSupply is less than maxSupply
            if (_nextTokenId() + quantity > config.maxTokenId) {
                revert ExceedsMaxSupply();
            }
        } else if (to != address(0)) {}
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from == address(0)) {
            // Minting - set extraData to block number for trait generation purposes
            unchecked {
                uint24 seed = uint24(block.number - 14400);
                _setExtraDataAt(startTokenId, seed);
                emit PoppetsMinted(startTokenId, seed, to, quantity);
            }
        } else {
            // Check for journal entries and transfer if they exist
            if (JOURNAL != address(0)) {
                IJournal(JOURNAL).safeTransferFrom(
                    _getTokenAccount(startTokenId),
                    to,
                    startTokenId
                );
            }
        }
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override
        onlyAllowedOperator(from)
        unlockedOrOwner(tokenId)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override
        onlyAllowedOperator(from)
        unlockedOrOwner(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override
        onlyAllowedOperator(from)
        unlockedOrOwner(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, ERC1155Receiver, ERC2981)
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) || // ERC-4906
            ERC721A.supportsInterface(interfaceId) ||
            ERC1155Receiver.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    // ███████ ██ ███    ██  █████  ███    ██  ██████ ███████ ███████
    // ██      ██ ████   ██ ██   ██ ████   ██ ██      ██      ██
    // █████   ██ ██ ██  ██ ███████ ██ ██  ██ ██      █████   ███████
    // ██      ██ ██  ██ ██ ██   ██ ██  ██ ██ ██      ██           ██
    // ██      ██ ██   ████ ██   ██ ██   ████  ██████ ███████ ███████

    function withdraw() public payable {
        (bool sent, bytes memory data) = payable(_receiver).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public payable onlyOwner {
        _receiver = receiver;
        _setDefaultRoyalty(_receiver, feeNumerator);
    }

    // ░░    ░░ ░░░░░░░░ ░░ ░░      ░░ ░░░░░░░░ ░░    ░░
    // ▒▒    ▒▒    ▒▒    ▒▒ ▒▒      ▒▒    ▒▒     ▒▒  ▒▒
    // ▒▒    ▒▒    ▒▒    ▒▒ ▒▒      ▒▒    ▒▒      ▒▒▒▒
    // ▓▓    ▓▓    ▓▓    ▓▓ ▓▓      ▓▓    ▓▓       ▓▓
    //  ██████     ██    ██ ███████ ██    ██       ██

    function _asSingletonArray(
        uint256 element
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function mintCuriosFromPacks(
        address to_,
        uint[] calldata ids
    ) external payable {
        if (_msgSender() != PACKS) {
            revert InsufficientPermissions();
        }
        ICurios(CURIOS).mintFromPack(to_, ids);
    }

    function mintCommunityCuriosFromPacks(
        address to_,
        uint[] calldata ids
    ) external payable {
        if (_msgSender() != PACKS) {
            revert InsufficientPermissions();
        }
        ICurios(COMMUNITY_CURIOS).mintFromPack(to_, ids);
    }
}
