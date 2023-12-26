// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ECDSA.sol";
import "./EIP712.sol";
import "./ERC721.sol";
import "./Initializable.sol";
import "./LibString.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./RoyaltyManager.sol";
import "./SSTORE2.sol";

import "./IAccessControl.sol";
import "./IERC4906.sol";
import "./IFxContractRegistry.sol";
import "./IFxGenArt721.sol";
import "./IMinter.sol";
import "./IRandomizer.sol";
import "./IRenderer.sol";

import "./Constants.sol";

/**
 * @title FxGenArt721
 * @author fx(hash)
 * @notice See the documentation in {IFxGenArt721}
 */
contract FxGenArt721 is IFxGenArt721, IERC4906, ERC721, EIP712, Initializable, Ownable, Pausable, RoyaltyManager {
    /*//////////////////////////////////////////////////////////////////////////
                                    STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxGenArt721
     */
    address public immutable contractRegistry;

    /**
     * @inheritdoc IFxGenArt721
     */
    address public immutable roleRegistry;

    /**
     * @dev Packed value of name and symbol where combined length is 30 bytes or less
     */
    bytes32 internal nameAndSymbol_;

    /**
     * @dev Project name
     */
    string internal name_;

    /**
     * @dev Project symbol
     */
    string internal symbol_;

    /**
     * @inheritdoc IFxGenArt721
     */
    uint96 public totalSupply;

    /**
     * @inheritdoc IFxGenArt721
     */
    address public randomizer;

    /**
     * @inheritdoc IFxGenArt721
     */
    address public renderer;

    /**
     * @inheritdoc IFxGenArt721
     */
    uint96 public nonce;

    /**
     * @inheritdoc IFxGenArt721
     */
    IssuerInfo public issuerInfo;

    /**
     * @inheritdoc IFxGenArt721
     */
    MetadataInfo public metadataInfo;

    /**
     * @inheritdoc IFxGenArt721
     */
    mapping(uint256 => GenArtInfo) public genArtInfo;

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Modifier for restricting calls to only registered minters
     */
    modifier onlyMinter() {
        if (!isMinter(msg.sender)) revert UnregisteredMinter();
        _;
    }

    /**
     * @dev Modifier for restricting calls to only authorized accounts with given role
     */
    modifier onlyRole(bytes32 _role) {
        if (!IAccessControl(roleRegistry).hasRole(_role, msg.sender)) revert UnauthorizedAccount();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes FxContractRegistry and FxRoleRegistry
     */
    constructor(
        address _contractRegistry,
        address _roleRegistry
    ) ERC721("FxGenArt721", "FXHASH") EIP712("FxGenArt721", "1") {
        contractRegistry = _contractRegistry;
        roleRegistry = _roleRegistry;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxGenArt721
     */
    function initialize(
        address _owner,
        InitInfo calldata _initInfo,
        ProjectInfo memory _projectInfo,
        MetadataInfo calldata _metadataInfo,
        MintInfo[] calldata _mintInfo,
        address[] calldata _royaltyReceivers,
        uint32[] calldata _allocations,
        uint96 _basisPoints
    ) external initializer {
        (, , , uint32 lockTime, , , ) = IFxContractRegistry(contractRegistry).configInfo();
        _projectInfo.earliestStartTime = (_isVerified(_owner))
            ? uint32(block.timestamp)
            : uint32(block.timestamp) + lockTime;
        if (_projectInfo.earliestStartTime < LAUNCH_TIMESTAMP) _pause();

        issuerInfo.projectInfo = _projectInfo;
        metadataInfo = _metadataInfo;
        randomizer = _initInfo.randomizer;
        renderer = _initInfo.renderer;

        _initializeOwner(_owner);
        _registerMinters(_mintInfo);
        _setPrimaryReceiver(_initInfo.primaryReceivers, _initInfo.allocations);
        _setBaseRoyalties(_royaltyReceivers, _allocations, _basisPoints);
        _setNameAndSymbol(_initInfo.name, _initInfo.symbol);
        _setTags(_initInfo.tagIds);
        if (_initInfo.onchainData.length > 0) _setOnchainPointer(_initInfo.onchainData);

        emit ProjectInitialized(issuerInfo.primaryReceiver, _projectInfo, _metadataInfo, _mintInfo);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxGenArt721
     */
    function burn(uint256 _tokenId) external whenNotPaused {
        if (!issuerInfo.projectInfo.burnEnabled) revert BurnInactive();
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) revert NotAuthorized();
        _burn(_tokenId);
        --totalSupply;
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function fulfillSeedRequest(uint256 _tokenId, bytes32 _seed) external {
        if (msg.sender != randomizer) revert NotAuthorized();
        genArtInfo[_tokenId].seed = _seed;
        emit SeedFulfilled(randomizer, _tokenId, _seed);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function mint(address _to, uint256 _amount, uint256 /* _payment */) external onlyMinter whenNotPaused {
        if (!issuerInfo.projectInfo.mintEnabled) revert MintInactive();
        uint96 currentId = totalSupply;
        for (uint256 i; i < _amount; ++i) {
            _mintRandom(_to, ++currentId);
        }
        totalSupply = currentId;
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function mintParams(address _to, bytes calldata _fxParams) external onlyMinter whenNotPaused {
        if (!issuerInfo.projectInfo.mintEnabled) revert MintInactive();
        _mintParams(_to, ++totalSupply, _fxParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxGenArt721
     */
    function ownerMint(address _to) external onlyOwner whenNotPaused {
        _mintRandom(_to, ++totalSupply);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function ownerMintParams(address _to, bytes calldata _fxParams) external onlyOwner whenNotPaused {
        _mintParams(_to, ++totalSupply, _fxParams);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function reduceSupply(uint120 _supply) external onlyOwner {
        uint120 prevSupply = issuerInfo.projectInfo.maxSupply;
        if (_supply >= prevSupply || _supply < totalSupply) revert InvalidAmount();
        issuerInfo.projectInfo.maxSupply = _supply;
        if (_supply == 0) emit ProjectDeleted();
        emit SupplyReduced(prevSupply, _supply);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function registerMinters(MintInfo[] memory _mintInfo) external onlyOwner {
        if (issuerInfo.projectInfo.mintEnabled) revert MintActive();
        uint256 length = issuerInfo.activeMinters.length;
        for (uint256 i; i < length; ++i) {
            address minter = issuerInfo.activeMinters[i];
            issuerInfo.minters[minter] = FALSE;
        }
        delete issuerInfo.activeMinters;
        _registerMinters(_mintInfo);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function setBaseRoyalties(
        address[] calldata _receivers,
        uint32[] calldata _allocations,
        uint96 _basisPoints
    ) external onlyOwner {
        _setBaseRoyalties(_receivers, _allocations, _basisPoints);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function setBurnEnabled(bool _flag) external onlyOwner {
        if (remainingSupply() == 0) revert SupplyRemaining();
        issuerInfo.projectInfo.burnEnabled = _flag;
        emit BurnEnabled(_flag);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function setMintEnabled(bool _flag) external onlyOwner {
        issuerInfo.projectInfo.mintEnabled = _flag;
        emit MintEnabled(_flag);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function setOnchainPointer(bytes calldata _onchainData, bytes calldata _signature) external onlyOwner {
        bytes32 digest = generateOnchainPointerHash(_onchainData);
        _verifySignature(digest, _signature);
        _setOnchainPointer(_onchainData);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function setPrimaryReceivers(address[] calldata _receivers, uint32[] calldata _allocations) external onlyOwner {
        _setPrimaryReceiver(_receivers, _allocations);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function setRenderer(address _renderer, bytes calldata _signature) external onlyOwner {
        bytes32 digest = generateRendererHash(_renderer);
        _verifySignature(digest, _signature);
        renderer = _renderer;
        emit RendererUpdated(_renderer);
        emit BatchMetadataUpdate(1, totalSupply);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxGenArt721
     */
    function setRandomizer(address _randomizer) external onlyRole(ADMIN_ROLE) {
        randomizer = _randomizer;
        emit RandomizerUpdated(_randomizer);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 METADATA FUNCTIONS
     //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxGenArt721
     */
    function setBaseURI(bytes calldata _uri) external onlyRole(METADATA_ROLE) {
        metadataInfo.baseURI = _uri;
        emit BaseURIUpdated(_uri);
        emit BatchMetadataUpdate(1, totalSupply);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                MODERATOR FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxGenArt721
     */
    function pause() external onlyRole(MODERATOR_ROLE) {
        _pause();
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function setTags(uint256[] calldata _tagIds) external onlyRole(MODERATOR_ROLE) {
        _setTags(_tagIds);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function unpause() external onlyRole(MODERATOR_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                READ FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFxGenArt721
     */
    function activeMinters() external view returns (address[] memory) {
        return issuerInfo.activeMinters;
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function contractURI() external view returns (string memory) {
        return IRenderer(renderer).contractURI();
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function primaryReceiver() external view returns (address) {
        return issuerInfo.primaryReceiver;
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function generateOnchainPointerHash(bytes calldata _data) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(SET_ONCHAIN_POINTER_TYPEHASH, _data, nonce));
        return _hashTypedDataV4(structHash);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function generateRendererHash(address _renderer) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(SET_RENDERER_TYPEHASH, _renderer, nonce));
        return _hashTypedDataV4(structHash);
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function isMinter(address _minter) public view returns (bool) {
        return issuerInfo.minters[_minter] == TRUE;
    }

    /**
     * @inheritdoc IFxGenArt721
     */
    function remainingSupply() public view returns (uint256) {
        return issuerInfo.projectInfo.maxSupply - totalSupply;
    }

    /**
     * @inheritdoc ERC721
     */
    function name() public view override returns (string memory) {
        (string memory packedName, ) = LibString.unpackTwo(nameAndSymbol_);
        return (nameAndSymbol_ == bytes32(0)) ? name_ : packedName;
    }

    /**
     * @inheritdoc ERC721
     */
    function symbol() public view override returns (string memory) {
        (, string memory packedSymbol) = LibString.unpackTwo(nameAndSymbol_);
        return (nameAndSymbol_ == bytes32(0)) ? symbol_ : packedSymbol;
    }

    /**
     * @inheritdoc ERC721
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);
        bytes memory data = abi.encode(
            metadataInfo.baseURI,
            metadataInfo.onchainPointer,
            genArtInfo[_tokenId].minter,
            genArtInfo[_tokenId].seed,
            genArtInfo[_tokenId].fxParams
        );
        return IRenderer(renderer).tokenURI(_tokenId, data);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Mints single token to given account using fxParams as input
     */
    function _mintParams(address _to, uint256 _tokenId, bytes calldata _fxParams) internal {
        if (remainingSupply() == 0) revert InsufficientSupply();
        if (issuerInfo.projectInfo.inputSize < _fxParams.length) revert InvalidInputSize();
        _mint(_to, _tokenId);
        genArtInfo[_tokenId].minter = _to;
        genArtInfo[_tokenId].fxParams = _fxParams;
        IRandomizer(randomizer).requestRandomness(_tokenId);
    }

    /**
     * @dev Mints single token to given account using randomly generated seed as input
     */
    function _mintRandom(address _to, uint256 _tokenId) internal {
        if (remainingSupply() == 0) revert InsufficientSupply();
        _mint(_to, _tokenId);
        genArtInfo[_tokenId].minter = _to;
        IRandomizer(randomizer).requestRandomness(_tokenId);
    }

    /**
     * @dev Registers arbitrary number of minter contracts and sets their reserves
     */
    function _registerMinters(MintInfo[] memory _mintInfo) internal {
        address minter;
        uint64 startTime;
        uint128 totalAllocation;
        ReserveInfo memory reserveInfo;
        uint32 earliestStartTime = issuerInfo.projectInfo.earliestStartTime;
        uint120 maxSupply = issuerInfo.projectInfo.maxSupply;
        for (uint256 i; i < _mintInfo.length; ++i) {
            minter = _mintInfo[i].minter;
            reserveInfo = _mintInfo[i].reserveInfo;
            startTime = reserveInfo.startTime;

            if (!IAccessControl(roleRegistry).hasRole(MINTER_ROLE, minter)) revert UnauthorizedMinter();
            if (startTime == 0) {
                reserveInfo.startTime = (block.timestamp > earliestStartTime)
                    ? uint64(block.timestamp)
                    : earliestStartTime;
            } else if (startTime < earliestStartTime) {
                revert InvalidStartTime();
            }
            if (reserveInfo.endTime < startTime) revert InvalidEndTime();
            if (maxSupply != OPEN_EDITION_SUPPLY) totalAllocation += reserveInfo.allocation;

            issuerInfo.minters[minter] = TRUE;
            issuerInfo.activeMinters.push(minter);
            IMinter(minter).setMintDetails(reserveInfo, _mintInfo[i].params);
        }

        if (maxSupply != OPEN_EDITION_SUPPLY) {
            if (totalAllocation > remainingSupply()) revert AllocationExceeded();
        }
    }

    /**
     * @dev Sets receivers and allocations for base royalties of token sales
     */
    function _setBaseRoyalties(
        address[] calldata _receivers,
        uint32[] calldata _allocations,
        uint96 _basisPoints
    ) internal override {
        (address feeReceiver, , uint32 secondaryFeeAllocation, , , , ) = IFxContractRegistry(contractRegistry)
            .configInfo();
        _checkFeeReceiver(_receivers, _allocations, feeReceiver, secondaryFeeAllocation);
        super._setBaseRoyalties(_receivers, _allocations, _basisPoints);
    }

    /**
     * @dev Sets primary receiver address for token sales
     */
    function _setPrimaryReceiver(address[] calldata _receivers, uint32[] calldata _allocations) internal {
        (address feeReceiver, uint32 primaryFeeAllocation, , , , , ) = IFxContractRegistry(contractRegistry)
            .configInfo();
        _checkFeeReceiver(_receivers, _allocations, feeReceiver, primaryFeeAllocation);
        address receiver = _getOrCreateSplit(_receivers, _allocations);
        issuerInfo.primaryReceiver = receiver;
        emit PrimaryReceiverUpdated(receiver, _receivers, _allocations);
    }

    /**
     * @dev Packs name and symbol into single slot if combined length is 30 bytes or less
     */
    function _setNameAndSymbol(string calldata _name, string calldata _symbol) internal {
        bytes32 packed = LibString.packTwo(_name, _symbol);
        if (packed == bytes32(0)) {
            name_ = _name;
            symbol_ = _symbol;
        } else {
            nameAndSymbol_ = packed;
        }
    }

    /**
     * @dev Sets the onchain pointer for reconstructing metadata onchain
     */
    function _setOnchainPointer(bytes calldata _onchainData) internal {
        address onchainPointer = SSTORE2.write(_onchainData);
        metadataInfo.onchainPointer = onchainPointer;
        emit OnchainPointerUpdated(onchainPointer);
    }

    /**
     * @dev Emits event for setting the project tag descriptions
     */
    function _setTags(uint256[] calldata _tagIds) internal {
        emit ProjectTags(_tagIds);
    }

    /**
     * @dev Verifies that a signature was generated for the computed digest
     */
    function _verifySignature(bytes32 _digest, bytes calldata _signature) internal {
        address signer = ECDSA.recover(_digest, _signature);
        if (!IAccessControl(roleRegistry).hasRole(SIGNER_ROLE, signer)) revert UnauthorizedAccount();
        nonce++;
    }

    /**
     * @dev Checks if creator is verified by the system
     */
    function _isVerified(address _creator) internal view returns (bool) {
        return (IAccessControl(roleRegistry).hasRole(CREATOR_ROLE, _creator));
    }

    /**
     * @dev Checks if fee receiver and allocation amount are included in their respective arrays
     */
    function _checkFeeReceiver(
        address[] calldata _receivers,
        uint32[] calldata _allocations,
        address _feeReceiver,
        uint32 _feeAllocation
    ) internal pure {
        bool feeReceiverExists;
        for (uint256 i; i < _allocations.length; i++) {
            if (_receivers[i] == _feeReceiver && _allocations[i] == _feeAllocation) feeReceiverExists = true;
        }
        if (!feeReceiverExists) revert InvalidFeeReceiver();
    }

    /**
     * @inheritdoc ERC721
     */
    function _exists(uint256 _tokenId) internal view override(ERC721, RoyaltyManager) returns (bool) {
        return super._exists(_tokenId);
    }
}
