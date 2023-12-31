// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ERC721Base.sol";
import "./MetadataEncryption.sol";
import "./IPostTransfer.sol";
import "./IPostBurn.sol";
import "./IERC721GeneralMint.sol";
import "./ERC721AURIStorageUpgradeable.sol";

/**
 * @title Generalized Base ERC721
 * @author highlight.xyz
 * @notice Generalized Base NFT smart contract
 */
abstract contract ERC721GeneralSequenceBase is ERC721Base, ERC721AURIStorageUpgradeable, IERC721GeneralMint {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Throw when attempting to mint, while mint is frozen
     */
    error MintFrozen();

    /**
     * @notice Throw when requested token is not in range within bounds of limit supply
     */
    error TokenNotInRange();

    /**
     * @notice Throw when new supply is over limit supply
     */
    error OverLimitSupply();

    /**
     * @notice Throw when array lengths are mismatched
     */
    error MismatchedArrayLengths();

    /**
     * @notice Throw when string is empty
     */
    error EmptyString();

    /**
     * @notice Contract metadata
     */
    string public contractURI;

    /**
     * @notice Limit the supply to take advantage of over-promising in summation with multiple mint vectors
     */
    uint256 public limitSupply;

    /**
     * @notice Emitted when uris are set for tokens
     * @param ids IDs of tokens to set uris for
     * @param uris Uris to set on tokens
     */
    event TokenURIsSet(uint256[] ids, string[] uris);

    /**
     * @notice Emitted when limit supply is set
     * @param newLimitSupply Limit supply to set
     */
    event LimitSupplySet(uint256 indexed newLimitSupply);

    /**
     * @notice See {IERC721GeneralMint-mintOneToOneRecipient}
     */
    function mintOneToOneRecipient(address recipient) external onlyMinter nonReentrant returns (uint256) {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }

        uint256 tempSupply = _nextTokenId();
        _requireLimitSupply(tempSupply);

        _mint(recipient, 1);

        return tempSupply;
    }

    /**
     * @notice See {IERC721GeneralMint-mintAmountToOneRecipient}
     */
    function mintAmountToOneRecipient(address recipient, uint256 amount) external onlyMinter nonReentrant {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        uint256 tempSupply = _nextTokenId() - 1; // cache

        _mint(recipient, amount);

        _requireLimitSupply(tempSupply + amount);
    }

    /**
     * @notice See {IERC721GeneralMint-mintOneToMultipleRecipients}
     */
    function mintOneToMultipleRecipients(address[] calldata recipients) external onlyMinter nonReentrant {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        uint256 recipientsLength = recipients.length;
        uint256 tempSupply = _nextTokenId() - 1; // cache

        for (uint256 i = 0; i < recipientsLength; i++) {
            _mint(recipients[i], 1);
        }

        _requireLimitSupply(tempSupply + recipientsLength);
    }

    /**
     * @notice See {IERC721GeneralMint-mintSameAmountToMultipleRecipients}
     */
    function mintSameAmountToMultipleRecipients(
        address[] calldata recipients,
        uint256 amount
    ) external onlyMinter nonReentrant {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        uint256 recipientsLength = recipients.length;
        uint256 tempSupply = _nextTokenId() - 1; // cache

        for (uint256 i = 0; i < recipientsLength; i++) {
            _mint(recipients[i], amount);
        }

        _requireLimitSupply(tempSupply + recipientsLength * amount);
    }

    /* solhint-disable no-empty-blocks */

    /**
     * @notice Mint a chosen token id to a single recipient
     * @dev Unavailable for ERC721GeneralSequenceBase, keep interface adhered for backwards compatiblity
     */
    function mintSpecificTokenToOneRecipient(address recipient, uint256 tokenId) external {}

    /**
     * @notice Mint chosen token ids to a single recipient
     * @dev Unavailable for ERC721GeneralSequenceBase, keep interface adhered for backwards compatiblity
     */
    function mintSpecificTokensToOneRecipient(address recipient, uint256[] calldata tokenIds) external {}

    /* solhint-enable no-empty-blocks */

    /**
     * @notice Override base URI system for select tokens, with custom per-token metadata
     * @param ids IDs of tokens to override base uri system for with custom uris
     * @param uris Custom uris
     */
    function setTokenURIs(uint256[] calldata ids, string[] calldata uris) external nonReentrant {
        uint256 idsLength = ids.length;
        if (idsLength != uris.length) {
            _revert(MismatchedArrayLengths.selector);
        }

        for (uint256 i = 0; i < idsLength; i++) {
            _setTokenURI(ids[i], uris[i]);
        }

        emit TokenURIsSet(ids, uris);
        observability.emitTokenURIsSet(ids, uris);
    }

    /**
     * @notice Set base uri
     * @param newBaseURI New base uri to set
     */
    function setBaseURI(string calldata newBaseURI) external nonReentrant {
        if (bytes(newBaseURI).length == 0) {
            _revert(EmptyString.selector);
        }

        address _manager = defaultManager;

        if (_manager == address(0)) {
            if (_msgSender() != owner()) {
                _revert(Unauthorized.selector);
            }
        } else {
            if (!ITokenManager(_manager).canUpdateMetadata(_msgSender(), 0, bytes(newBaseURI))) {
                _revert(Unauthorized.selector);
            }
        }

        _setBaseURI(newBaseURI);
        observability.emitBaseUriSet(newBaseURI);
    }

    /**
     * @notice Set limit supply
     * @param _limitSupply Limit supply to set
     */
    function setLimitSupply(uint256 _limitSupply) external onlyOwner nonReentrant {
        // allow it to be 0, for post-mint
        limitSupply = _limitSupply;

        emit LimitSupplySet(_limitSupply);
        observability.emitLimitSupplySet(_limitSupply);
    }

    /**
     * @notice Set contract name
     * @param newName New name
     * @param newSymbol New symbol
     * @param newContractUri New contractURI
     */
    function setContractMetadata(
        string calldata newName,
        string calldata newSymbol,
        string calldata newContractUri
    ) external onlyOwner {
        _setContractMetadata(newName, newSymbol);
        contractURI = newContractUri;

        observability.emitContractMetadataSet(newName, newSymbol, newContractUri);
    }

    /**
     * @notice See {IERC721-burn}. Overrides default behaviour to check associated tokenManager.
     */
    function burn(uint256 tokenId) public nonReentrant {
        address _manager = tokenManager(tokenId);
        address msgSender = _msgSender();

        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostBurn).interfaceId)) {
            address owner = ownerOf(tokenId);
            IPostBurn(_manager).postBurn(msgSender, owner, tokenId);
        } else {
            // default to restricting burn to owner or operator if a valid TM isn't present
            if (!_isApprovedOrOwner(msgSender, tokenId)) {
                _revert(Unauthorized.selector);
            }
        }

        _burn(tokenId);

        observability.emitTransfer(msgSender, address(0), tokenId);
    }

    /**
     * @notice Overrides tokenURI to first rotate the token id
     * @param tokenId ID of token to get uri for
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return ERC721AURIStorageUpgradeable.tokenURI(tokenId);
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165Upgradeable, ERC721AUpgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Hook called after transfers
     * @param from Account token is being transferred from
     * @param to Account token is being transferred to
     * @param tokenId ID of token being transferred
     */
    function _afterTokenTransfers(address from, address to, uint256 tokenId) internal override {
        address _manager = tokenManager(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, "");
        }

        observability.emitTransfer(from, to, tokenId);
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgSender() internal view virtual override(ERC721Base, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgData() internal view virtual override(ERC721Base, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure virtual override(ERC721AUpgradeable, ERC721Base) {
        ERC721AUpgradeable._revert(errorSelector);
    }

    /**
     * @notice Override base URI system for select tokens, with custom per-token metadata
     * @param tokenId Token to set uri for
     * @param _uri Uri to set on token
     */
    function _setTokenURI(uint256 tokenId, string calldata _uri) private {
        address _manager = tokenManager(tokenId);
        address msgSender = _msgSender();

        address tempOwner = owner();
        if (_manager == address(0)) {
            if (msgSender != tempOwner) {
                _revert(Unauthorized.selector);
            }
        } else {
            if (!ITokenManager(_manager).canUpdateMetadata(msgSender, tokenId, bytes(_uri))) {
                _revert(Unauthorized.selector);
            }
        }

        _tokenURIs[tokenId] = _uri;
    }

    /**
     * @notice Require the new supply of tokens after mint to be less than limit supply
     * @param newSupply New supply
     */
    function _requireLimitSupply(uint256 newSupply) private view {
        uint256 _limitSupply = limitSupply;
        if (_limitSupply != 0 && newSupply > _limitSupply) {
            _revert(OverLimitSupply.selector);
        }
    }
}
