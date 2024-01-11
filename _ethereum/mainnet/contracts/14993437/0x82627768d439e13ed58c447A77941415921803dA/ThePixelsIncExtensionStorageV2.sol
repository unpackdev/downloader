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
import "./IThePixelsIncExtensionStorageV2.sol";
import "./ICoreRewarder.sol";

contract ThePixelsIncExtensionStorageV2 is
    Ownable,
    IThePixelsIncExtensionStorageV2,
    ThePixelsDigitsUtility
{
    struct Extension {
        bool isEnabled;
        bool isSticky;
        uint8 beginIndex;
        uint8 endIndex;
        address operator;
    }

    bool public isLive;

    address public immutable INTAddress;
    address public DAOAddress;
    address public rewarderAddress;

    uint256 public extensionCount;

    mapping(uint256 => uint256) public override pixelExtensions;
    mapping(uint256 => Extension) public extensions;
    mapping(uint256 => mapping(uint256 => Variant)) public variants;
    mapping(uint256 => mapping(uint256 => Category)) public categories;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public claimedPixelVariants;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public usedCollectionTokens;

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

    function setDAOAddress(address _DAOAddress) external onlyOwner {
        DAOAddress = _DAOAddress;
    }

    function setRewarderAddress(address _rewarderAddress) external onlyOwner {
        rewarderAddress = _rewarderAddress;
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

    // Used for migration
    function setClaimedPixelVariants(
        uint256[] memory extensionIds,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory isClaimeds
    ) public onlyOwner {
        for (uint256 i; i < extensionIds.length; i++) {
            claimedPixelVariants[extensionIds[i]][tokenIds[i]][
                variantIds[i]
            ] = isClaimeds[i];
        }
    }

    // Used for migration
    function setPixelExtensions(
        uint256[] memory tokenIds,
        uint256[] memory _pixelExtensions
    ) public onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            pixelExtensions[tokenIds[i]] = _pixelExtensions[i];
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

    function detachVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        _detachExtensionVariant(owner, extension, extensionId, tokenId);
    }

    function detachVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        for (uint256 i; i < tokenIds.length; i++) {
            _detachExtensionVariant(owner, extension, extensionId, tokenIds[i]);
        }
    }

    function transferExtensionVariant(
        address owner,
        uint256 extensionId,
        uint256 variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");
        require(!extension.isSticky, "This extension is sticky");

        Variant memory _variant = variants[extensionId][variantId];
        require(_variant.isEnabled, "This variant is disabled");

        require(
            extension.operator == msg.sender || owner == msg.sender,
            "Not authorised - Invalid owner or operator"
        );

        require(
            ICoreRewarder(rewarderAddress).isOwner(owner, fromTokenId),
            "Not authorised - Invalid owner"
        );

        bool ownershipOfSender = claimedPixelVariants[extensionId][fromTokenId][
            variantId
        ];
        require(ownershipOfSender, "Sender doesn't own this variant");
        uint256 currentVariantId = currentVariantIdOf(extensionId, fromTokenId);
        if (currentVariantId == variantId) {
            _detach(
                msg.sender,
                extensionId,
                extension.beginIndex,
                extension.endIndex,
                fromTokenId
            );
        }

        bool ownershipOfRecipent = claimedPixelVariants[extensionId][toTokenId][
            variantId
        ];
        require(!ownershipOfRecipent, "Recipent already has this variant");

        claimedPixelVariants[extensionId][fromTokenId][variantId] = false;
        claimedPixelVariants[extensionId][toTokenId][variantId] = true;

        emit VariantTransferred(extensionId, variantId, fromTokenId, toTokenId);
    }

    // UTILITY

    function variantDetail(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) public view override returns (Variant memory, VariantStatus memory) {
        Variant memory variant = variants[extensionId][variantId];
        VariantStatus memory status;

        (uint128 _cost, uint128 _supply) = _costAndSupplyOfVariant(
            extensionId,
            variant
        );

        status.cost = _cost;
        status.supply = _supply;

        bool isFreeForCollection = _shouldConsumeCollectionToken(
            owner,
            extensionId,
            variantId,
            useCollectionTokenId,
            collectionTokenId,
            variant
        );

        if (isFreeForCollection) {
            status.cost = 0;
        }

        if (claimedPixelVariants[extensionId][tokenId][variantId]) {
            status.isAlreadyClaimed = true;
            status.cost = 0;
        }

        return (variant, status);
    }

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

        for (uint256 i; i < tokenIds.length; i++) {
            (
                Variant memory _variant,
                VariantStatus memory _status
            ) = variantDetail(
                    owner,
                    extensionId,
                    tokenIds[i],
                    variantIds[i],
                    useCollectionTokenIds[i],
                    collectionTokenIds[i]
                );
            _variants[i] = _variant;
            statuses[i] = _status;
        }

        return (_variants, statuses);
    }

    function variantsOfExtension(
        uint256 extensionId,
        uint256[] memory variantIds
    ) public view override returns (Variant[] memory) {
        Variant[] memory _variants = new Variant[](variantIds.length);

        for (uint256 i; i < variantIds.length; i++) {
            _variants[i] = variants[extensionId][variantIds[i]];
        }

        return _variants;
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
        return _digitsAt(value, extension.beginIndex, extension.endIndex);
    }

    function currentVariantIdsOf(uint256 extensionId, uint256[] memory tokenIds)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _variants = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            _variants[i] = currentVariantIdOf(extensionId, tokenIds[i]);
        }
        return _variants;
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
            require(_owner == msg.sender, "Not authroised - Invalid owner");
        }

        require(
            ICoreRewarder(rewarderAddress).isOwner(_owner, _tokenId),
            "Not authorised - Invalid owner"
        );

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

    function _detachExtensionVariant(
        address _owner,
        Extension memory _extension,
        uint256 _extensionId,
        uint256 _tokenId
    ) internal {
        require(!_extension.isSticky, "This extension is sticky");
        require(
            _extension.operator == msg.sender || _owner == msg.sender,
            "Not authorised - Invalid owner or operator"
        );

        require(
            ICoreRewarder(rewarderAddress).isOwner(_owner, _tokenId),
            "Not authorised - Invalid owner"
        );

        _detach(
            _owner,
            _extensionId,
            _extension.beginIndex,
            _extension.endIndex,
            _tokenId
        );
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
            _beginIndex,
            _endIndex,
            _value
        );
        pixelExtensions[_tokenId] = newValue;
        emit Extended(_owner, _tokenId, _extensionId, value, newValue);
    }

    function _detach(
        address _owner,
        uint256 _extensionId,
        uint8 _beginIndex,
        uint8 _endIndex,
        uint256 _tokenId
    ) internal {
        uint256 value = pixelExtensions[_tokenId];
        uint256 newValue = _clearDigits(value, _beginIndex, _endIndex);
        pixelExtensions[_tokenId] = newValue;
        emit Detached(_owner, _tokenId, _extensionId, value, newValue);
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

        emit INTSpent(_owner, _contributer, contributerAmount, daoAmount);
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
            extension.isEnabled,
            extension.isSticky,
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

    event Detached(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 extensionId,
        uint256 previousExtension,
        uint256 newExtension
    );

    event ExtensionChanged(
        uint256 indexed extensionId,
        address operator,
        bool isEnabled,
        bool isSticky,
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

    event INTSpent(
        address indexed owner,
        address contributer,
        uint256 contributerAmount,
        uint256 daoAmount
    );
}
