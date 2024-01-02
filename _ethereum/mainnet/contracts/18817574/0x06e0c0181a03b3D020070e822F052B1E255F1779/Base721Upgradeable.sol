// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC721EnumerableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721WithPermitUpgradable.sol";
import "./RolesUpgradeable.sol";
import "./UniqueCheckingUpgradeable.sol";
import "./PaymenProcessingUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Helper.sol";
import "./ItemTypes.sol";
import "./Types.sol";
import "./Constants.sol";

contract PhygitalXNFT is
    RolesUpgradeable,
    PaymenProcessingUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721WithPermitUpgradable,
    ReentrancyGuardUpgradeable,
    UniqueCheckingUpgradeable
{
    error Order__ZeroValue();
    error Order__Expired();
    error InvalidSignature();

    using Helper for *;
    using ItemTypes for ItemTypes.ItemOrder;
    event BuyItem(address recipient, uint256 tokenId, bytes32 metadata);

    uint256 private _idCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        FeeInfo calldata clientInfo_,
        address[] calldata operators_,
        address admin_,
        address signer_,
        address symtemAddress_
    ) external initializer {
        __ReentrancyGuard_init_unchained();
        __ERC721WithPermitUpgradable_init(name_, symbol_);
        __RolesUpgradeable_init_unchained(admin_, signer_, operators_);
        __FeeCollector_init_unchained(clientInfo_);
        systemAddress = symtemAddress_;
        _idCounter = 1;
    }

    function buyItem(ItemTypes.ItemOrder calldata item_, address recipient_) external payable nonReentrant {
        _setUsed(item_.nonce);
        _validateOrder(item_);
        _processPayment(item_.currency, item_.price, _msgSender(), item_.referrer);

        uint256 tokenId = _idCounter;
        _safeMint(recipient_, tokenId);
        emit BuyItem(recipient_, tokenId, item_.metadata);
        _idCounter = ++tokenId;
    }

    function _validateOrder(ItemTypes.ItemOrder calldata item_) private view {
        bytes32 operatorHash = item_.operatorHash();
        bytes32 systemHash = item_.hash();

        // Verify the price is not 0
        if (item_.price == 0) revert Order__ZeroValue();

        // Verify order timestamp
        if (item_.deadline < block.timestamp) revert Order__Expired();

        _verify(OPERATOR_ROLE, operatorHash, item_.operatorSignature);
        _verify(SIGNER_ROLE, systemHash, item_.systemSignature);
    }

    function _verify(bytes32 role_, bytes32 hash_, Types.Signature calldata signature_) internal view {
        address recoveredAddress;
        bytes32 digest = _hashTypedDataV4(hash_);

        (recoveredAddress, ) = ECDSAUpgradeable.tryRecover(digest, signature_.v, signature_.r, signature_.s);

        if (recoveredAddress == address(0) || !hasRole(role_, recoveredAddress)) revert InvalidSignature();
    }

    function setBaseTokenURI(string calldata baseTokenURI_) external onlyRole(OPERATOR_ROLE) {
        _setBaseURI(baseTokenURI_);
    }

    // The following functions are overrides required by Solidity.

    function _baseURI() internal view override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return _baseUri;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 batchSize_
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, tokenId_, batchSize_);
    }

    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal override(ERC721Upgradeable, ERC721WithPermitUpgradable) {
        super._transfer(from_, to_, tokenId_);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControlEnumerableUpgradeable,
            ERC721EnumerableUpgradeable,
            ERC721Upgradeable,
            ERC721WithPermitUpgradable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
