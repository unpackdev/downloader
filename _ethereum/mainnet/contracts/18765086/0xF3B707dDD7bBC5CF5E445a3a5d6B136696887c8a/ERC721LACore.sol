// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./AccessControl.sol";
import "./Winter.sol";
import "./IERC721LA.sol";
import "./Pausable.sol";
import "./IERC4906.sol";
import "./Ownable.sol";
import "./LAInitializable.sol";
import "./LANFTUtils.sol";
import "./BPS.sol";
import "./CustomErrors.sol";
import "./IERC721Events.sol";
import "./ERC721State.sol";
import "./WithOperatorRegistry.sol";

interface IStakingContract {
    function isTokenStaked(uint256 tokenId) external view returns (bool);
}

interface IPrintVoucherContract {
    function mintPrintVoucher(
        address _recipient,
        uint256[] calldata _tokenIds
    ) external;
}

/**
 * @notice LiveArt ERC721 implementation contract
 * Supports multiple edtioned NFTs and gas optimized batch minting
 */
abstract contract ERC721LACore is
    LAInitializable,
    AccessControl,
    WithOperatorRegistry,
    Winter,
    Pausable,
    Ownable,
    IERC721LA,
    IERC4906
{
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               LIBRARIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    using BitMaps for BitMaps.BitMap;
    using ERC721State for ERC721State.ERC721LAState;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               LIBRARIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    using BitMaps for BitMaps.BitMap;
    using ERC721State for ERC721State.ERC721LAState;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    bytes32 public constant IERC721METADATA_INTERFACE = hex"5b5e139f";
    bytes32 public constant IERC721_INTERFACE = hex"80ac58cd";
    bytes32 public constant IERC2981_INTERFACE = hex"2a55205a";
    bytes32 public constant IERC165_INTERFACE = hex"01ffc9a7";
    bytes32 public constant IERC4906_INTERFACE = hex"49064906";

    // Used for separating editionId and tokenNumber from the tokenId (cf. createEdition)
    uint24 public constant DEFAULT_EDITION_TOKEN_MULTIPLIER = 10e5;

    // Used to differenciate burnt tokens in the bitmap logic (Null address being used for unminted tokens)
    address public constant burnAddress = address(0xDEAD);

    // Logic contracts addresses
    address constant GOERLI_LOGIC_CONTRACT =
        address(0x3874070EC249EaEd336Fd0c6eE79Bef7ff8b924D);
    address constant MAINNET_LOGIC_CONTRACT =
        address(0xE291354a3aeB7EB49da0f1333d667F17fa33F1c5);

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               INITIALIZERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @dev Initialize function. Should be called by the factory when deploying new instances.
     * @param _collectionAdmin is the address of the default admin for this contract
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _collectionAdmin,
        address _royaltyRegistry
    ) external notInitialized {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._name = _name;
        state._symbol = _symbol;
        state._royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
        state._editionCounter = 1;
        state._edition_max_tokens = DEFAULT_EDITION_TOKEN_MULTIPLIER;
        _grantRole(COLLECTION_ADMIN_ROLE, _collectionAdmin);
        _setOwner(_collectionAdmin);
        _setWinterWallet(0xdAb1a1854214684acE522439684a145E62505233);
        _initOperatorRegsitry();
    }

    /**
     * @dev Overload `initialize` function with `_edition_max_tokens` argument
     */
    // function initialize(
    //     string calldata _name,
    //     string calldata _symbol,
    //     address _collectionAdmin,
    //     address _royaltyRegistry,
    //     uint24 _edition_max_tokens
    // ) external notInitialized {
    //     ERC721State.ERC721LAState storage state = ERC721State
    //         ._getERC721LAState();
    //     state._name = _name;
    //     state._symbol = _symbol;
    //     state._royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
    //     state._editionCounter = 1;
    //     state._edition_max_tokens = _edition_max_tokens;
    //     _grantRole(COLLECTION_ADMIN_ROLE, _collectionAdmin);
    //     _setOwner(_collectionAdmin);
    //     _setWinterWallet(0xdAb1a1854214684acE522439684a145E62505233);
    //     _initOperatorRegsitry();
    // }

    /// @dev See {IERC165-supportsInterface}.
    // function supportsInterface(
    //     bytes4 interfaceId
    // ) external pure override returns (bool) {
    //     return
    //         interfaceId == IERC4906_INTERFACE ||
    //         interfaceId == IERC2981_INTERFACE ||
    //         interfaceId == IERC721_INTERFACE ||
    //         interfaceId == IERC721METADATA_INTERFACE ||
    //         interfaceId == IERC165_INTERFACE;
    // }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                           LogicContract
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function _delegateLogic() internal virtual {
        address implementation = getLogicContract();
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function getLogicContract() internal view returns (address) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        if (state._logicContractAddress != address(0)) {
            return state._logicContractAddress;
        }

        if (block.chainid == 5) {
            return GOERLI_LOGIC_CONTRACT;
        }
        return MAINNET_LOGIC_CONTRACT;
    }

    function setLogicContractAddress(address newAddress) external onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._logicContractAddress = newAddress;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                           IERC721Metadata
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function name() external view override returns (string memory) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._name;
    }

    function symbol() external view returns (string memory) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._symbol;
    }

    // function setName(string calldata _name) public onlyAdmin {
    //     ERC721State.ERC721LAState storage state = ERC721State
    //         ._getERC721LAState();
    //     state._name = _name;
    // }

    // function setSymbol(string calldata _symbol) public onlyAdmin {
    //     ERC721State.ERC721LAState storage state = ERC721State
    //         ._getERC721LAState();
    //     state._symbol = _symbol;
    // }

    function tokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert CustomErrors.TokenNotFound();
        }

        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);
        ERC721State.Edition memory edition = getEdition(editionId);

        if (edition.perTokenMetadata) {
            return
                string(
                    abi.encodePacked(
                        state._baseURIByEdition[editionId],
                        LANFTUtils.toString(tokenId)
                    )
                );
        }
        return state._baseURIByEdition[editionId];
    }

    function totalSupply() external view override returns (uint256) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        uint256 _count;
        for (uint256 i = 1; i < state._editionCounter; i += 1) {
            _count += editionMintedTokens(i);
        }
        return _count;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               EDITIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @notice Backward compatibility with the frontend
     */
    function EDITION_TOKEN_MULTIPLIER() public view returns (uint24) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._edition_max_tokens;
    }

    function EDITION_MAX_SIZE() public view returns (uint24) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._edition_max_tokens - 1;
    }

    /**
     * @notice Creates a new Edition
     * Editions can be seen as collections within a collection.
     * The token Ids for the a given edition have the following format:
     * `[editionId][tokenNumber]`
     * eg.: The Id of the 2nd token of the 5th edition is: `5000002`
     *
     */
    function createEdition(
        string calldata _baseURI,
        uint24 _maxSupply,
        uint24 _publicMintPriceInFinney,
        uint32 _publicMintStartTS,
        uint32 _publicMintEndTS,
        uint8 _maxMintPerWallet,
        bool _perTokenMetadata,
        uint8 _burnableEditionId,
        uint8 _amountToBurn
    ) public onlyAdmin returns (uint256) {
        _delegateLogic();
    }

    /**
     * @notice updates an edition base URI
     */
    function updateEditionBaseURI(
        uint256 editionId,
        string calldata _baseURI
    ) public onlyAdmin {
        _delegateLogic();
    }

    /**
     * @notice updates an edition base URI
     */
    function updateEditionPrintData(
        uint256 _editionId,
        address _newPrintVoucherAddress,
        uint24 _newPublicMintPriceWithPrintInFinney
    ) public onlyAdmin {
        _delegateLogic();
    }

    /**
     * @notice updates edition parameter. Careful: This will overwrite all previously set values on that edition.
     */
    function updateEdition(
        uint256 editionId,
        uint24 _publicMintPriceInFinney,
        uint32 _publicMintStartTS,
        uint32 _publicMintEndTS,
        uint8 _maxMintPerWallet,
        uint24 _maxSupply,
        bool _perTokenMetadata
    ) public onlyAdmin {
        _delegateLogic();
    }

    /**
     * @notice fetch edition struct data by editionId
     */
    function getEdition(
        uint256 _editionId
    ) public view override returns (ERC721State.Edition memory) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (_editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }
        return state._editions[_editionId];
    }

    /**
     * @notice fetch edition struct data by editionId
     */
    function getEditionWithURI(
        uint256 _editionId
    )
        public
        view
        override
        returns (ERC721State.EditionWithURI memory editionWithURI)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (_editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }
        editionWithURI = ERC721State.EditionWithURI({
            data: state._editions[_editionId],
            baseURI: state._baseURIByEdition[_editionId]
        });
    }

    function getEditionPrintData(
        uint256 _editionId
    )
        public
        view
        override
        returns (ERC721State.EditionWithPrintData memory editionPrintData)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (_editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }

        editionPrintData = ERC721State.EditionWithPrintData({
            printVoucherContractAddress: state
                ._printDataByEdition[_editionId]
                .printVoucherContractAddress,
            publicMintPriceWithPrintInFinney: state
                ._printDataByEdition[_editionId]
                .publicMintPriceWithPrintInFinney
        });
    }

    /**
     * @notice Returns the total number of editions
     */
    function totalEditions() external view returns (uint256 total) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        total = state._editionCounter - 1;
    }

    /**
     * @notice Returns the current supply of a given edition
     */
    function editionMintedTokens(
        uint256 editionId
    ) public view returns (uint256 supply) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        ERC721State.Edition memory edition = state._editions[editionId];
        return edition.currentSupply - edition.burnedSupply;
    }

    /**
     * @dev Given an editionId and  tokenNumber, returns tokenId in the following format:
     * `[editionId][tokenNumber]` where `tokenNumber` is between 1 and state._edition_max_tokens  - 1
     * eg.: The second token from the 5th edition would be `500002`
     *
     */
    function editionedTokenId(
        uint256 editionId,
        uint256 tokenNumber
    ) public view returns (uint256 tokenId) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        uint256 paddedEditionID = editionId * state._edition_max_tokens;
        tokenId = paddedEditionID + tokenNumber;
    }

    /**
     * @dev Given a tokenId return editionId and tokenNumber.
     * eg.: 3000005 => editionId 3 and tokenNumber 5
     */
    function parseEditionFromTokenId(
        uint256 tokenId
    ) public view returns (uint256 editionId, uint256 tokenNumber) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        // Divide first to lose the decimal. ie. 1000001 / 1000000 = 1
        editionId = tokenId / state._edition_max_tokens;
        tokenNumber = tokenId - (editionId * state._edition_max_tokens);
    }

    /// @dev Is public mint open for given edition
    function isPublicMintStarted(
        uint256 editionId
    ) public view override returns (bool) {
        ERC721State.Edition memory edition = getEdition(editionId);
        bool started = (edition.publicMintStartTS != 0 &&
            edition.publicMintStartTS <= block.timestamp) &&
            (edition.publicMintEndTS == 0 ||
                edition.publicMintEndTS > block.timestamp);
        return started;
    }

    /**
     * @notice sets the staking contract address
     **/
    function setStakingContractAddress(
        address stakingContractAddress
    ) external onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._stakingContractAddress = stakingContractAddress;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               STAKING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /**
     * @notice toggle staking on/off for an edition
     **/
    function toggleStakingByEdition(uint256 editionId) external onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._editions[editionId].stakingEnabled = !state
            ._editions[editionId]
            .stakingEnabled;
    }

    function getStakingContractAddress() external view returns (address) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._stakingContractAddress;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               STAKING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    modifier whenPublicMintOpened(uint256 editionId) {
        if (!isPublicMintStarted(editionId)) {
            revert CustomErrors.MintClosed();
        }
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               MINTABLE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /**
     * @dev Internal batch minting function
     */
    function _safeMint(
        uint256 _editionId,
        uint24 _quantity,
        address _recipient
    ) internal virtual returns (uint256 firstTokenId) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        ERC721State.Edition storage edition = state._editions[_editionId];

        uint256 tokenNumber = edition.currentSupply + 1;

        if (_editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }

        if (_quantity == 0 || _recipient == address(0)) {
            revert CustomErrors.InvalidMintData();
        }

        if (tokenNumber > edition.maxSupply) {
            revert CustomErrors.MaxSupplyError();
        }

        firstTokenId = editionedTokenId(_editionId, tokenNumber);

        if (edition.currentSupply + _quantity > edition.maxSupply) {
            revert CustomErrors.MaxSupplyError();
        }

        edition.currentSupply += _quantity;
        state._owners[firstTokenId] = _recipient;
        state._batchHead.set(firstTokenId);
        state._balances[_recipient] += _quantity;

        // Emit events
        for (
            uint256 tokenId = firstTokenId;
            tokenId < firstTokenId + _quantity;
            tokenId++
        ) {
            emit Transfer(address(0), _recipient, tokenId);
            LANFTUtils._checkOnERC721Received(
                address(0),
                _recipient,
                tokenId,
                ""
            );
        }
    }

    function mintEditionTokens(
        uint256 _editionId,
        uint24 _quantity,
        address _recipient
    ) public payable whenPublicMintOpened(_editionId) whenNotPaused {
        ERC721State.Edition memory edition = getEdition(_editionId);

        _validatePublicMintParams(
            _editionId,
            _quantity,
            edition.maxMintPerWallet
        );

        _validateMintPrice(edition.publicMintPriceInFinney, _quantity);

        uint256 firstTokenId = _safeMint(_editionId, _quantity, _recipient);

        _sendRoyaltiesAfterMint(firstTokenId);
    }

    function mintEditionTokensWithPrints(
        uint256 _editionId,
        uint24 _quantity,
        address _recipient
    ) public payable whenPublicMintOpened(_editionId) whenNotPaused {
        ERC721State.Edition memory edition = getEdition(_editionId);

        ERC721State.EditionWithPrintData memory printData = getEditionPrintData(
            _editionId
        );

        _validatePublicMintParams(
            _editionId,
            _quantity,
            edition.maxMintPerWallet
        );

        _validateEditionPrintData(printData);

        _validateMintPrice(
            printData.publicMintPriceWithPrintInFinney,
            _quantity
        );

        uint256 firstTokenId = _safeMint(_editionId, _quantity, _recipient);

        _sendRoyaltiesAfterMint(firstTokenId);
        _mintPrintVouchers(_editionId, _quantity, firstTokenId);
    }

    function adminMint(
        uint256 _editionId,
        uint24 _quantity,
        address _recipient
    ) public onlyAdmin {
        _safeMint(_editionId, _quantity, _recipient);
    }

    function getMintedCount(
        uint256 _editionId,
        address _recipient
    ) public view returns (uint256) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        uint256 mintedCountKey = uint256(
            keccak256(abi.encodePacked(_editionId, _recipient))
        );
        return state._mintedPerWallet[mintedCountKey];
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               PAUSABLE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function pauseContract() public onlyAdmin {
        _pause();
    }

    function unpauseContract() public onlyAdmin {
        _unpause();
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                                   ERC721
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev See {IERC721-approve}.
    function approve(
        address to,
        uint256 tokenId
    ) external override onlyAllowedOperatorApproval(to) {
        address owner = ownerOf(tokenId);
        if (
            msg.sender == to ||
            (msg.sender != owner && !isApprovedForAll(owner, msg.sender))
        ) {
            revert CustomErrors.NotAllowed();
        }

        _approve(to, tokenId);
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override onlyAllowedOperator(from) {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CustomErrors.TransferError();
        }

        _transfer(from, to, tokenId);
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        (address owner, ) = _ownerAndBatchHeadOf(tokenId);
        return owner;
    }

    /// @dev Returns the number of tokens in ``owner``'s account.
    function balanceOf(
        address owner
    ) external view returns (uint256 tokenBalance) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        tokenBalance = state._balances[owner];
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(
        uint256 tokenId
    ) public view override returns (address) {
        if (!_exists(tokenId)) {
            revert CustomErrors.TokenNotFound();
        }
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        if (!_isTransferAllowed(tokenId)) {
            revert CustomErrors.TokenStaked();
        }
        return state._tokenApprovals[tokenId];
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(
        address owner,
        address operator
    ) public view override returns (bool) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return state._operatorApprovals[owner][operator];
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(
        address operator,
        bool approved
    ) external override onlyAllowedOperatorApproval(operator) {
        if (operator == msg.sender) {
            revert CustomErrors.NotAllowed();
        }

        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override onlyAllowedOperator(from) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override onlyAllowedOperator(from) {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CustomErrors.NotAllowed();
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                         INTERNAL / PUBLIC HELPERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev Returns whether `tokenId` exists.
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            tokenId
        );
        if (isBurned(tokenId)) {
            return false;
        }
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        ERC721State.Edition memory edition = state._editions[editionId];
        return tokenNumber <= edition.currentSupply;
    }

    /**
     * @dev Returns the index of the batch for a given token.
     * If the token was not bought in a batch tokenId == tokenIdBatchHead
     */
    function _getBatchHead(
        uint256 tokenId
    ) internal view returns (uint256 tokenIdBatchHead) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);
        tokenIdBatchHead = state._batchHead.scanForward(
            tokenId,
            editionId * state._edition_max_tokens
        );
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        state._tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Returns the index of the batch for a given token.
     * and the batch owner address
     */
    function _ownerAndBatchHeadOf(
        uint256 tokenId
    ) internal view returns (address owner, uint256 tokenIdBatchHead) {
        if (!_exists(tokenId)) {
            revert CustomErrors.TokenNotFound();
        }

        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        tokenIdBatchHead = _getBatchHead(tokenId);
        owner = state._owners[tokenIdBatchHead];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        if (!_exists(tokenId)) {
            revert CustomErrors.TokenNotFound();
        }

        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     * Internal function intened to split the logic for different transfer use cases
     * Emits a {Transfer} event.
     */
    function _transferCore(address from, address to, uint256 tokenId) internal {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        (, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(tokenId);

        address owner = ownerOf(tokenId);

        if (owner != from) {
            revert CustomErrors.TransferError();
        }

        // We check if the token after the one being transfer
        // belong to the batch, if it does, we have to update it's owner
        // while being careful to not overflow the edition maxSupply
        uint256 nextTokenId = tokenId + 1;
        (, uint256 nextTokenNumber) = parseEditionFromTokenId(nextTokenId);
        (uint256 currentEditionId, ) = parseEditionFromTokenId(tokenId);

        ERC721State.Edition memory edition = state._editions[currentEditionId];

        if (
            nextTokenNumber <= edition.maxSupply &&
            !state._batchHead.get(nextTokenId)
        ) {
            state._owners[nextTokenId] = from;
            state._batchHead.set(nextTokenId);
        }

        // Finaly we update the owners and balances
        state._owners[tokenId] = to;
        if (tokenId != tokenIdBatchHead) {
            state._batchHead.set(tokenId);
        }

        state._balances[to] += 1;
        state._balances[from] -= 1;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        _beforeTokenTransfer(from, to, tokenId);
        // Remove approval
        _approve(address(0), tokenId);
        emit Transfer(from, to, tokenId);
        _transferCore(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        LANFTUtils._checkOnERC721Received(from, to, tokenId, _data);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (!_isTransferAllowed(tokenId)) {
            revert CustomErrors.TokenStaked();
        }
    }

    /**
     * Check if the token is staked
     */
    function _isTransferAllowed(uint256 tokenId) internal view returns (bool) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        (uint256 currentEditionId, ) = parseEditionFromTokenId(tokenId);

        ERC721State.Edition memory edition = state._editions[currentEditionId];
        // If the token is staked, we don't allow transfer
        if (edition.stakingEnabled) {
            bool tokenIsStaked = IStakingContract(state._stakingContractAddress)
                .isTokenStaked(tokenId);

            if (tokenIsStaked) {
                return false;
            }
        }
        return true;
    }

    function _mintPrintVouchers(
        uint256 _editionId,
        uint24 _quantity,
        uint256 _firstTokenId
    ) internal {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        address printVoucherContractAddress = state
            ._printDataByEdition[_editionId]
            .printVoucherContractAddress;

        // Mint print vouchers
        uint256[] memory tokenArray = new uint256[](_quantity);

        for (uint256 i = 0; i < _quantity; i++) {
            tokenArray[i] = _firstTokenId + i;
        }

        IPrintVoucherContract(printVoucherContractAddress).mintPrintVoucher(
            tx.origin,
            tokenArray
        );
    }

    function _validatePublicMintParams(
        uint256 _editionId,
        uint24 _quantity,
        uint8 _maxMintPerWallet
    ) internal {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        // Check max mint per wallet restrictions (if maxMintPerWallet is 0, no restriction apply)
        if (_maxMintPerWallet != 0 && !_isWinterWallet()) {
            uint256 mintedCountKey = uint256(
                keccak256(abi.encodePacked(_editionId, msg.sender))
            );
            if (
                state._mintedPerWallet[mintedCountKey] + _quantity >
                _maxMintPerWallet
            ) {
                revert CustomErrors.MaximumMintAmountReached();
            }
            state._mintedPerWallet[mintedCountKey] += _quantity;
        }
    }

    function _validateEditionPrintData(
        ERC721State.EditionWithPrintData memory printData
    ) internal pure {
        if (
            printData.printVoucherContractAddress == address(0) ||
            printData.publicMintPriceWithPrintInFinney == 0
        ) {
            revert CustomErrors.InvalidPrintData();
        }
    }

    function _validateMintPrice(
        uint256 _mintPriceInFinney,
        uint24 _quantity
    ) internal view {
        uint256 mintPriceInWei = uint256(_mintPriceInFinney) * 10e14;

        if (mintPriceInWei * _quantity > msg.value) {
            revert CustomErrors.InsufficientFunds();
        }
    }

    function _sendRoyaltiesAfterMint(uint256 _firstTokenId) internal {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        // Send primary royalties
        (
            address payable[] memory wallets,
            uint256[] memory primarySalePercentages
        ) = state._royaltyRegistry.primaryRoyaltyInfo(
                address(this),
                _firstTokenId
            );

        uint256 nReceivers = wallets.length;

        for (uint256 i = 0; i < nReceivers; i++) {
            uint256 royalties = BPS._calculatePercentage(
                msg.value,
                primarySalePercentages[i]
            );
            (bool sent, ) = wallets[i].call{value: royalties}("");

            if (!sent) {
                revert CustomErrors.FundTransferError();
            }
        }
    }

    /**
     * Check if the token is staked
     */
    // function _areAllNFTsStaked(address from) internal view returns(bool) {
    //     ERC721State.ERC721LAState storage state = ERC721State
    //         ._getERC721LAState();
    //     (uint256 currentEditionId, ) = parseEditionFromTokenId(tokenId);

    //     ERC721State.Edition memory edition = state._editions[currentEditionId];
    //     // If the token is staked, we don't allow transfer
    //     if (edition.stakingEnabled) {
    //         bool tokenIsStaked = IStakingContract(state._stakingContractAddress)
    //             .isTokenStaked(tokenId);

    //         if (tokenIsStaked) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    function isBurned(uint256 tokenId) public view returns (bool) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        address owner = state._owners[tokenId];
        return owner == burnAddress;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               ETHER
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAmount(
        address payable recipient,
        uint256 amount
    ) external onlyAdmin {
        (bool succeed, ) = recipient.call{value: amount}("");
        if (!succeed) {
            revert CustomErrors.FundTransferError();
        }
    }

    function withdrawAll(address payable recipient) external onlyAdmin {
        (bool succeed, ) = recipient.call{value: balance()}("");
        if (!succeed) {
            revert CustomErrors.FundTransferError();
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               X-CARD
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function setXCardContractAddress(
        address xCardContractAddress
    ) public override onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._xCardContractAddress = xCardContractAddress;
    }

    function getXCardContractAddress() public view override returns (address) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._xCardContractAddress;
    }
}
