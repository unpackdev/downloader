// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";

import "./ThePixelsDigitsUtility.sol";
import "./IINT.sol";
import "./IThePixelsIncExtensionStorage.sol";
import "./ICoreRewarder.sol";

contract ThePixelsIncExtensionStorage is
    Ownable,
    IThePixelsIncExtensionStorage,
    ThePixelsDigitsUtility
{
    struct Extension {
        bool isEnabled;
        uint8 beginIndex;
        uint8 endIndex;
        address operator;
    }

    bool public isLive;

    address public immutable INTAddress;
    address public immutable DAOAddress;
    address public immutable rewarderAddress;

    uint256 public extensionCount;

    mapping(uint256 => uint256) public override pixelExtensions;
    mapping(uint256 => Extension) public extensions;
    mapping(uint256 => mapping(uint256 => Variant)) public variants;
    mapping(uint256 => mapping(uint256 => Category)) public categories;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public claimedPixelVariants;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public usedCollectionTokens;
    mapping(address => uint256) public rewards;

    constructor(
        address _INTAddress,
        address _DAOAddress,
        address _rewarderAddress
    ) {
        INTAddress = _INTAddress;
        DAOAddress = _DAOAddress;
        rewarderAddress = _rewarderAddress;
    }

    // OWNER CONTROLS

    function setIsLive(bool _isLive) external onlyOwner {
        isLive = _isLive;
    }

    function setExtension(uint256 extensionId, Extension memory extension)
        public
        onlyOwner
    {
        require(
            extension.endIndex > extension.beginIndex,
            "Indexes are invalid"
        );
        extensions[extensionId] = extension;
        emitExtensionChangeEvent(extensionId, extension);
    }

    function setClaimedPixelVariants(
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool isClaimed
    ) public onlyOwner {
        claimedPixelVariants[extensionId][tokenId][variantId] = isClaimed;
        emit VariantClaimChanged(extensionId, variantId, tokenId, isClaimed);
    }

    function setExtensions(
        uint256[] memory extensionIds,
        Extension[] memory _extensions
    ) public onlyOwner {
        for (uint256 i = 0; i < extensionIds.length; i++) {
            setExtension(extensionIds[i], _extensions[i]);
        }
    }

    function enableExtension(uint256 extensionId, bool isEnabled)
        external
        onlyOwner
    {
        extensions[extensionId].isEnabled = isEnabled;
        emitExtensionChangeEvent(extensionId, extensions[extensionId]);
    }

    function setVariant(
        uint256 extensionId,
        uint256 variantId,
        Variant memory variant
    ) public onlyOwner {
        variants[extensionId][variantId] = variant;
        emitVariantChangeEvent(extensionId, variantId, variant);
    }

    function setVariants(
        uint256 extensionId,
        uint256[] memory variantIds,
        Variant[] memory _variants
    ) public onlyOwner {
        for (uint256 i; i < variantIds.length; i++) {
            setVariant(extensionId, variantIds[i], _variants[i]);
        }
    }

    function enableVariant(
        uint256 extensionId,
        uint256 variantId,
        bool isEnabled
    ) external onlyOwner {
        variants[extensionId][variantId].isEnabled = isEnabled;
        emitVariantChangeEvent(
            extensionId,
            variantId,
            variants[extensionId][variantId]
        );
    }

    function setCategory(
        uint256 extensionId,
        uint256 categoryId,
        Category memory category
    ) public onlyOwner {
        categories[extensionId][categoryId] = category;
        emitCategoryChangeEvent(extensionId, categoryId, category);
    }

    function setCategories(
        uint256 extensionId,
        uint256[] memory categoryIds,
        Category[] memory _categories
    ) public onlyOwner {
        for (uint256 i; i < categoryIds.length; i++) {
            setCategory(extensionId, categoryIds[i], _categories[i]);
        }
    }

    // PUBILC CONTROLS

    function extendWithVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        _extendWithVariant(
            owner,
            extension,
            extensionId,
            tokenId,
            variantId,
            useCollectionTokenId,
            collectionTokenId
        );
    }

    function extendMultipleWithVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenIds,
        uint256[] memory collectionTokenIds
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        for (uint256 i; i < tokenIds.length; i++) {
            _extendWithVariant(
                owner,
                extension,
                extensionId,
                tokenIds[i],
                variantIds[i],
                useCollectionTokenIds[i],
                collectionTokenIds[i]
            );
        }
    }

    function transferExtensionVariant(
        uint256 extensionId,
        uint256 variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    ) public {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        if (extension.operator != msg.sender) {
            require(
                ICoreRewarder(rewarderAddress).isOwner(msg.sender, fromTokenId),
                "Not authorised"
            );
        }

        bool ownershipOfSender = claimedPixelVariants[extensionId][fromTokenId][
            variantId
        ];
        require(ownershipOfSender, "Sender doesn't own this variant");
        uint256 currentVariantId = currentVariantIdOf(extensionId, fromTokenId);
        require(
            currentVariantId != variantId,
            "You need to detach this variant to transfer"
        );

        bool ownershipOfRecipent = claimedPixelVariants[extensionId][toTokenId][
            variantId
        ];
        require(!ownershipOfRecipent, "Recipent already has this variant");

        claimedPixelVariants[extensionId][fromTokenId][variantId] = false;
        claimedPixelVariants[extensionId][toTokenId][variantId] = true;

        emit VariantTransferred(extensionId, variantId, fromTokenId, toTokenId);
    }

    // UTILITY

    function variantDetails(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenIds,
        uint256[] memory collectionTokenIds
    ) public view override returns (Variant[] memory, VariantStatus[] memory) {
        VariantStatus[] memory statuses = new VariantStatus[](
            variantIds.length
        );
        Variant[] memory _variants = new Variant[](variantIds.length);

        address _owner = owner;
        uint256 _extensionId = extensionId;
        for (uint256 i; i < variantIds.length; i++) {
            uint256 variantId = variantIds[i];
            uint256 tokenId = tokenIds[i];
            bool useCollectionTokenId = useCollectionTokenIds[i];
            uint256 collectionTokenId = collectionTokenIds[i];

            Variant memory variant = variants[_extensionId][variantId];

            (uint128 _cost, uint128 _supply) = _costAndSupplyOfVariant(
                _extensionId,
                variant
            );

            statuses[i].cost = _cost;
            statuses[i].supply = _supply;

            bool isFreeForCollection = _shouldConsumeCollectionToken(
                _owner,
                _extensionId,
                variantId,
                useCollectionTokenId,
                collectionTokenId,
                variant
            );

            if (isFreeForCollection) {
                statuses[i].cost = 0;
            }

            if (claimedPixelVariants[_extensionId][tokenId][variantId]) {
                statuses[i].isAlreadyClaimed = true;
                statuses[i].cost = 0;
            }
            _variants[i] = variant;
        }

        return (_variants, statuses);
    }

    function balanceOfToken(
        uint256 extensionId,
        uint256 tokenId,
        uint256[] memory variantIds
    ) public view override returns (uint256) {
        uint256 balance;
        for (uint256 i; i < variantIds.length; i++) {
            uint256 variantId = variantIds[i];
            if (claimedPixelVariants[extensionId][tokenId][variantId]) {
                balance++;
            }
        }
        return balance;
    }

    function currentVariantIdOf(uint256 extensionId, uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        Extension memory extension = extensions[extensionId];
        uint256 value = pixelExtensions[tokenId];
        return
            _digitsAt(
                value,
                _digitOf(value),
                extension.beginIndex,
                extension.endIndex
            );
    }

    // INTERNAL

    function _extendWithVariant(
        address _owner,
        Extension memory _extension,
        uint256 _extensionId,
        uint256 _tokenId,
        uint256 _variantId,
        bool _useCollectionTokenId,
        uint256 _collectionTokenId
    ) internal {
        Variant memory _variant = variants[_extensionId][_variantId];
        require(_variant.isEnabled, "This variant is disabled");

        if (_variant.isOperatorExecution) {
            require(
                _extension.operator == msg.sender,
                "Not authroised - Invalid operator"
            );
        } else {
            require(
                ICoreRewarder(rewarderAddress).isOwner(msg.sender, _tokenId),
                "Not authorised - Invalid owner"
            );
        }

        if (_variant.isDisabledForSpecialPixels) {
            require(
                !_isSpecialPixel(_tokenId),
                "This variant is not for special pixels"
            );
        }

        _extend(
            _owner,
            _extensionId,
            _extension.beginIndex,
            _extension.endIndex,
            _tokenId,
            _variantId
        );

        if (!claimedPixelVariants[_extensionId][_tokenId][_variantId]) {
            (uint128 _cost, uint128 _supply) = _costAndSupplyOfVariant(
                _extensionId,
                _variant
            );

            bool shouldConsumeCollectionToken = _shouldConsumeCollectionToken(
                _owner,
                _extensionId,
                _variantId,
                _useCollectionTokenId,
                _collectionTokenId,
                _variant
            );

            if (shouldConsumeCollectionToken) {
                _cost = 0;
                usedCollectionTokens[_extensionId][_variantId][
                    _collectionTokenId
                ] = true;
            }

            if (_supply != 0) {
                require(_variant.count < _supply, "Sorry, sold out");
                variants[_extensionId][_variantId].count++;
            }

            claimedPixelVariants[_extensionId][_tokenId][_variantId] = true;

            if (_cost > 0) {
                _spendINT(
                    _owner,
                    _cost,
                    _variant.contributer,
                    _variant.contributerCut
                );
            }
        }
    }

    function _extend(
        address _owner,
        uint256 _extensionId,
        uint8 _beginIndex,
        uint8 _endIndex,
        uint256 _tokenId,
        uint256 _value
    ) internal {
        uint256 value = pixelExtensions[_tokenId];
        uint256 newValue = _replacedDigits(
            value,
            _digitOf(value),
            _beginIndex,
            _endIndex,
            _value
        );
        pixelExtensions[_tokenId] = newValue;
        emit Extended(_owner, _tokenId, _extensionId, value, newValue);
    }

    function _spendINT(
        address _owner,
        uint128 _amount,
        address _contributer,
        uint16 _contributerCut
    ) internal {
        if (_amount == 0) {
            return;
        }

        uint128 contributerAmount;
        uint128 daoAmount;
        unchecked {
            if (_contributerCut > 0) {
                contributerAmount = _amount / _contributerCut;
                daoAmount = _amount - contributerAmount;
            } else {
                daoAmount = _amount;
            }
        }

        if (daoAmount > 0) {
            IINT(INTAddress).transferFrom(_owner, DAOAddress, daoAmount);
        }

        if (contributerAmount > 0) {
            IINT(INTAddress).transferFrom(
                _owner,
                _contributer,
                contributerAmount
            );
        }
    }

    function _costAndSupplyOfVariant(
        uint256 _extensionId,
        Variant memory _variant
    ) internal view returns (uint128, uint128) {
        uint128 _cost = _variant.cost;
        uint128 _supply = _variant.supply;

        if (_variant.categoryId > 0) {
            Category memory _category = categories[_extensionId][
                _variant.categoryId
            ];
            _cost = _category.cost;
            _supply = _category.supply;
        }

        return (_cost, _supply);
    }

    function _shouldConsumeCollectionToken(
        address _owner,
        uint256 _extensionId,
        uint256 _variantId,
        bool _useCollectionTokenId,
        uint256 _collectionTokenId,
        Variant memory _variant
    ) internal view returns (bool) {
        if (_variant.isFreeForCollection && _useCollectionTokenId) {
            if (
                !usedCollectionTokens[_extensionId][_variantId][
                    _collectionTokenId
                ] &&
                IERC721(_variant.collection).ownerOf(_collectionTokenId) ==
                _owner
            ) {
                return true;
            }
        }
        return false;
    }

    function _isSpecialPixel(uint256 tokenId) internal pure returns (bool) {
        if (
            tokenId == 5061 ||
            tokenId == 5060 ||
            tokenId == 5059 ||
            tokenId == 5058 ||
            tokenId == 5057
        ) {
            return true;
        }
        return false;
    }

    // EVENTS

    function emitExtensionChangeEvent(
        uint256 extensionId,
        Extension memory extension
    ) internal {
        emit ExtensionChanged(
            extensionId,
            extension.operator,
            extension.beginIndex,
            extension.endIndex
        );
    }

    function emitVariantChangeEvent(
        uint256 extensionId,
        uint256 variantId,
        Variant memory variant
    ) internal {
        emit VariantChanged(
            extensionId,
            variantId,
            variant.isOperatorExecution,
            variant.isFreeForCollection,
            variant.isEnabled,
            variant.isDisabledForSpecialPixels,
            variant.contributerCut,
            variant.cost,
            variant.supply,
            variant.count,
            variant.contributer,
            variant.collection
        );
    }

    function emitCategoryChangeEvent(
        uint256 extensionId,
        uint256 categoryId,
        Category memory category
    ) internal {
        emit CategoryChanged(
            extensionId,
            categoryId,
            category.cost,
            category.supply
        );
    }

    event Extended(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 extensionId,
        uint256 previousExtension,
        uint256 newExtension
    );

    event ExtensionChanged(
        uint256 indexed extensionId,
        address operator,
        uint8 beginIndex,
        uint8 endIndex
    );

    event VariantChanged(
        uint256 indexed extensionId,
        uint256 indexed variantId,
        bool isOperatorExecution,
        bool isFreeForCollection,
        bool isEnabled,
        bool isDisabledForSpecialPixels,
        uint16 contributerCut,
        uint128 cost,
        uint128 supply,
        uint128 count,
        address contributer,
        address collection
    );

    event CategoryChanged(
        uint256 indexed extensionId,
        uint256 indexed categoryId,
        uint128 cost,
        uint128 supply
    );

    event VariantTransferred(
        uint256 indexed extensionId,
        uint256 indexed variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    );

    event VariantClaimChanged(
        uint256 indexed extensionId,
        uint256 indexed variantId,
        uint256 tokenId,
        bool isClaimed
    );
}
