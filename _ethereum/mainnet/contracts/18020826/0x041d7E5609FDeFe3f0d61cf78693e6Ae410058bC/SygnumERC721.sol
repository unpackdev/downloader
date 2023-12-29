// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Strings.sol";
import "./ERC721Upgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./Initializable.sol";
import "./IBaseOperators.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

/// @custom:security-contact Team 3301 <team3301@sygnum.com>
/**
 * @title SygnumERC721
 * @dev Extends ERC721 Non-Fungible Token Standard and Ownable contracts from OpenZeppelin with support of the opensea on-chain royalties.
 */
contract SygnumERC721 is Initializable, DefaultOperatorFiltererUpgradeable, ERC721Upgradeable, Ownable2StepUpgradeable {
    using Strings for uint256;

    error SygnumERC721AmountExceedsMaxSupply();
    error SygnumERC721InvalidBaseOperators();
    error SygnumERC721MintingZeroToken();
    error SygnumERC721InvalidBaseUri();
    error SygnumERC721InvalidMaxTokenSupply();
    error SygnumERC721MismatchingInputSize();
    error SygnumERC721BatchLimitExceeded();
    error SygnumERC721AlreadyRevealed();
    error SygnumERC721InvalidTokenID();
    error SygnumERC721OwnerIsZeroAddress();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role"
     */
    error OperatorableCallerNotOperator();

    uint256 public maxTokenSupply;
    uint256 public constant BATCH_LIMIT = 32;
    string public baseUri;
    address public baseOperators;
    bool public revealed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Reverts if sender does not have operator role associated.
     */
    modifier onlyOperator() {
        if (!IBaseOperators(baseOperators).isOperator(msg.sender)) revert OperatorableCallerNotOperator();
        _;
    }

    /**
     * @dev Initializes the contract with the given parameters and sets the owner.
     * @param data The encoded parameters for contract initialization.
     * @param _baseOperators The address of the base operators contract.
     */
    function initialize(bytes calldata data, address _baseOperators) public initializer {
        (
            string memory _name,
            string memory _symbol,
            uint256 _maxTokenSupply,
            string memory _baseUri,
            bool _revealed,
            address owner
        ) = abi.decode(data, (string, string, uint256, string, bool, address));
        if (_baseOperators.code.length == 0) revert SygnumERC721InvalidBaseOperators();
        if (bytes(_baseUri).length == 0) revert SygnumERC721InvalidBaseUri();
        if (_maxTokenSupply == 0) revert SygnumERC721InvalidMaxTokenSupply();
        __ERC721_init(_name, _symbol);
        __Ownable2Step_init();
        __DefaultOperatorFilterer_init();
        if (_revealed) revealed = _revealed;
        if (owner != address(0)) transferOwnership(owner);
        baseOperators = _baseOperators;
        maxTokenSupply = _maxTokenSupply;
        baseUri = _baseUri;
    }

    /**
     * @dev Returns the base URI for metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Function returning the URI to access token metadata
     * @param tokenId The token ID
     * @return string The corresponding URI in string format
     */
    function uri(uint256 tokenId) external view virtual returns (string memory) {
        if (!_exists(tokenId)) revert SygnumERC721InvalidTokenID();

        string memory baseURI = baseUri;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Function returning the URI to access token metadata
     * @param tokenId The token ID
     * @return string The corresponding URI in string format
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert SygnumERC721InvalidTokenID();

        string memory baseURI = baseUri;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Returns the base URI for metadata.
     */
    function reveal(string memory _uri) external onlyOperator {
        if (revealed) revert SygnumERC721AlreadyRevealed();
        revealed = true;
        baseUri = _uri;
    }

    /**
     * @dev Creates a new token and assigns it to `to`. This function can only be
     * called by the contract operator.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The ID of the token to mint.
     */
    function mint(address to, uint256 tokenId) external virtual onlyOperator {
        if (tokenId == 0) revert SygnumERC721MintingZeroToken();
        if (tokenId > maxTokenSupply) revert SygnumERC721InvalidTokenID();
        _mint(to, tokenId);
    }

    /**
     * @dev Mints multiple tokens to multiple addresses in a single batch.
     * @param tos The list of addresses to mint tokens to.
     * @param tokenIds The list of token IDs to mint.
     * Requirements:
     * - The length of `tos` and `tokenIds` must be the same.
     * - The length of `tos` must not exceed `BATCH_LIMIT`.
     * - Each token ID in `tokenIds` must not exceed `maxTokenSupplies`.
     * Emits a {TransferBatch} event.
     */
    function batchMint(address[] memory tos, uint256[] memory tokenIds) external virtual onlyOperator {
        if (tos.length > BATCH_LIMIT) revert SygnumERC721BatchLimitExceeded();
        if (tos.length != tokenIds.length) revert SygnumERC721MismatchingInputSize();
        for (uint256 i = 0; i < tos.length; i++) {
            if (tokenIds[i] > maxTokenSupply) revert SygnumERC721AmountExceedsMaxSupply();
            _mint(tos[i], tokenIds[i]);
        }
    }

    /**
     * @dev Returns the current version of the contract.
     * @return The version number of the contract.
     */
    function version() external pure virtual returns (uint256) {
        return 1;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferOwnershipOperator(address newOwner) public virtual onlyOperator {
        if (newOwner != address(0)) _transferOwnership(newOwner);
        else revert SygnumERC721OwnerIsZeroAddress();
    }
}
