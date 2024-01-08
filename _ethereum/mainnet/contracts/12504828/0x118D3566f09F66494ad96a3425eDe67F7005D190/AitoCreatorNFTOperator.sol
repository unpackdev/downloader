// SPDX-License-Identifier: UNLICENSED.
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IAitoCreatorNFTOperator.sol";
import "./Errors.sol";
import "./ERC721.sol";

/**
 * @title AitoCreatorNFT contract
 * @author Aito
 *
 * @notice An NFT contract that inherits from a slightly modified ERC721 implementation that allows for setting
 * operator approvals via signature. In addition, this contract maps certain additional fields per NFT, allowing for
 * simple external market integrations via fetching data.
 */
contract AitoCreatorNFTOperator is ERC721, IAitoCreatorNFTOperator {
    uint16 constant BPS_MAX = 10000;

    //keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    //keccak256("PermitForAll(address owner,address operator,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMITFORALL_TYPEHASH =
        0x6a42f941d678cc59927d3f3e5741e2de6c08ed2585137041916d9a265fa7ef7c;

    mapping(address => mapping(uint256 => uint256)) public permitNonces;
    mapping(address => uint256) public permitForAllNonces;

    uint256 internal _idCounter;
    mapping(uint256 => address) internal _creator;
    mapping(uint256 => IAitoCreatorNFTOperator.FeeData) internal _feeData;
    address internal _globalOperator;

    /**
     * @dev Constructor calls the ERC721 constructor, sets the initial global operator
     * and initializes the ID counter to 1.
     */
    constructor(
        string memory name,
        string memory symbol,
        address globalOperator
    ) ERC721(name, symbol) {
        require(globalOperator != address(0), Errors.ZERO_SPENDER);
        _idCounter = 1;
        _globalOperator = globalOperator;
    }

    // ========== EXTERNAL/PUBLIC ==========

    /// @inheritdoc IAitoCreatorNFTOperator
    function mint(
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string calldata uri,
        bool approveGlobal
    ) public virtual override {
        _validateMintParams(creator, feeRecipient, feeBps);
        _fullMint(_idCounter++, creator, to, feeRecipient, feeBps, uri);
        if (approveGlobal) {
            _setApprovalForAll(to, _globalOperator, true);
        }
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function batchMint(
        uint256 amount,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string[] calldata uris,
        bool approveGlobal
    ) public virtual override {
        _validateMintParams(creator, feeRecipient, feeBps);
        require(amount > 1, Errors.INVALID_BATCH_MINT_AMOUNT);
        require(amount == uris.length, Errors.ARRAY_MISMATCH);
        uint256 tokenId = _idCounter;
        for (uint256 i = 0; i < amount; i++) {
            _fullMint(tokenId++, creator, to, feeRecipient, feeBps, uris[i]);
        }
        if (approveGlobal) {
            _setApprovalForAll(to, _globalOperator, true);
        }
        _idCounter = tokenId;
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function batchMintCopies(
        uint256 amount,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string calldata uri,
        bool approveGlobal
    ) public virtual override {
        _validateMintParams(creator, feeRecipient, feeBps);
        require(amount > 1, Errors.INVALID_BATCH_MINT_AMOUNT);
        uint256 tokenId = _idCounter;
        for (uint256 i = 0; i < amount; i++) {
            _fullMint(tokenId++, creator, to, feeRecipient, feeBps, uri);
        }
        if (approveGlobal) {
            _setApprovalForAll(to, _globalOperator, true);
        }
        _idCounter = tokenId;
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function burn(uint256 tokenId) external override {
        require(msg.sender == ownerOf(tokenId), Errors.NOT_NFT_OWNER);
        _burn(tokenId);
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function changeURI(uint256 tokenId, string calldata newUri)
        external
        override
    {
        _validateGlobalOperator(msg.sender);
        _setTokenURI(tokenId, newUri);

        emit URIChanged(tokenId, newUri);
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function changeFeeBps(uint256 tokenId, uint16 newFeeBps) external override {
        _validateGlobalOperator(msg.sender);
        require(newFeeBps < BPS_MAX, Errors.INVALID_BPS);
        _feeData[tokenId].feeBps = newFeeBps;

        emit FeeBpsChanged(tokenId, newFeeBps);
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function changeFeeRecipient(uint256 tokenId, address newFeeRecipient)
        external
        override
    {
        _validateGlobalOperator(msg.sender);
        require(newFeeRecipient != address(0), Errors.ZERO_FEE_RECIPIENT);
        _feeData[tokenId].feeRecipient = newFeeRecipient;

        emit FeeRecipientChanged(tokenId, newFeeRecipient);
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function changeCreator(uint256 tokenId, address newCreator)
        external
        override
    {
        _validateGlobalOperator(msg.sender);
        require(newCreator != address(0), Errors.ZERO_CREATOR);
        _creator[tokenId] = newCreator;

        emit CreatorChanged(tokenId, newCreator);
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function changeGlobalOperator(address newGlobalOperator) external override {
        _validateGlobalOperator(msg.sender);
        require(newGlobalOperator != address(0), Errors.ZERO_SPENDER);
        _globalOperator = newGlobalOperator;

        emit GlobalOperatorChanged(newGlobalOperator);
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function renounceApprovalForAll(address owner) external override {
        require(_operatorApprovals[owner][msg.sender] == true, Errors.NOT_OPERATOR);
        _setApprovalForAll(owner, msg.sender, false);
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function permit(
        address spender,
        uint256 tokenId,
        IAitoCreatorNFTOperator.EIP712Signature calldata sig
    ) external override {
        require(sig.deadline >= block.timestamp, Errors.SIGNATURE_EXPIRED);
        require(spender != address(0), Errors.ZERO_SPENDER);
        bytes32 domainSeparator = _calculateDomainSeparator();

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            spender,
                            tokenId,
                            permitNonces[ownerOf(tokenId)][tokenId]++,
                            sig.deadline
                        )
                    )
                )
            );

        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        // Removed address(0) check since ownerOf(tokenId) reverts on a nonexistent tokenId.
        require(recoveredAddress == ownerOf(tokenId), Errors.INVALID_SIGNATURE);

        _approve(spender, tokenId);
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function permitForAll(
        address owner,
        address operator,
        IAitoCreatorNFTOperator.EIP712Signature calldata sig
    ) external override {
        require(sig.deadline >= block.timestamp, Errors.SIGNATURE_EXPIRED);
        require(operator != address(0), Errors.ZERO_SPENDER);
        bytes32 domainSeparator = _calculateDomainSeparator();

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            PERMITFORALL_TYPEHASH,
                            owner,
                            operator,
                            permitForAllNonces[owner]++,
                            sig.deadline
                        )
                    )
                )
            );

        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        require(recoveredAddress == owner, Errors.INVALID_SIGNATURE);

        _setApprovalForAll(owner, operator, true);
    }

    // ========== VIEW ==========

    /// @inheritdoc IAitoCreatorNFTOperator
    function creator(uint256 tokenId) external view override returns (address) {
        return _creator[tokenId];
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function feeData(uint256 tokenId)
        external
        view
        override
        returns (IAitoCreatorNFTOperator.FeeData memory)
    {
        return _feeData[tokenId];
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function feeBps(uint256 tokenId) external view override returns (uint16) {
        return _feeData[tokenId].feeBps;
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function feeRecipient(uint256 tokenId) external view override returns (address) {
        return _feeData[tokenId].feeRecipient;
    }

    /// @inheritdoc IAitoCreatorNFTOperator
    function domainSeparator() external view override returns (bytes32) {
        return _calculateDomainSeparator();
    }

    // ========== INTERNAL ==========

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        _operatorApprovals[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    function _validateMintParams(
        address creator,
        address feeRecipient,
        uint16 feeBps
    ) internal {
        require(creator != address(0), Errors.ZERO_CREATOR);
        require(feeRecipient != address(0), Errors.ZERO_FEE_RECIPIENT);
        require(feeBps <= BPS_MAX, Errors.INVALID_BPS);
    }

    function _validateGlobalOperator(address globalOperatorCandidate) internal view {
        require(globalOperatorCandidate == _globalOperator, Errors.NOT_GLOBAL_OPERATOR);
    }

    function _fullMint(
        uint256 tokenId,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string memory uri
    ) internal {
        _creator[tokenId] = creator;
        _feeData[tokenId] = IAitoCreatorNFTOperator.FeeData(feeRecipient, feeBps);
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit TokenMinted(tokenId, creator, to, feeRecipient, feeBps, uri);
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return
            keccak256(
                abi.encode(
                    keccak256(
                        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                    ),
                    keccak256(bytes(name())),
                    keccak256(bytes('1')),
                    chainID,
                    address(this)
                )
            );
    }
}
