// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./Math.sol";
import "./ChonkyChkns.sol";
import "./FeedToken.sol";

interface ITraitsManager {
    function getNumericalTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (uint256);

    function getCategoricalTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (bytes32);

    function getFreeFormTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (bytes32);

    function getNumericalTraitIncreasePrice(bytes32 _traitName)
        external
        view
        returns (uint128);

    function getNumericalTraitDecreasePrice(bytes32 _traitName)
        external
        view
        returns (uint128);

    function getCategoricalTraitAddPrice(
        bytes32 _traitName,
        bytes32 _traitValue
    ) external view returns (uint128);

    function getCategoricalTraitRemovePrice(
        bytes32 _traitName,
        bytes32 _traitValue
    ) external view returns (uint128);

    function getFreeFormTraitAddPrice(bytes32 _traitName)
        external
        view
        returns (uint128);

    function getFreeFormTraitRemovePrice(bytes32 _traitName)
        external
        view
        returns (uint128);

    function increaseNumericalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        uint256 _countToAdd
    ) external;

    function decreaseNumericalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        uint256 _countToSubtract
    ) external;

    function setCategoricalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        bytes32 _traitValue
    ) external;

    function removeCategoricalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName
    ) external;

    function setFreeFormTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        bytes32 _traitValue
    ) external;

    function removeFreeFormTraitForToken(uint256 _tokenId, bytes32 _traitName)
        external;
}

contract CustomTraitsManager is Ownable {
    // Mapping of (token id => (trait name => trait value))
    mapping(uint256 => mapping(bytes32 => uint256)) public numericalTraits;
    mapping(uint256 => mapping(bytes32 => bytes32)) public categoricalTraits;
    mapping(uint256 => mapping(bytes32 => bytes32)) public freeFormTraits;

    // Mappings of (numerical/categorical trait type => (price to add a unit, price to remove a unit)).
    struct Prices {
        uint128 addPrice;
        uint128 removePrice;
    }
    mapping(bytes32 => Prices) public traitPrices;
    mapping(bytes32 => mapping(bytes32 => Prices))
        public categoricalTraitPrices;

    // ===============================

    // Map of contracts that have the ability to modify trait values on tokens,
    // to perform tasks such as:
    //  - trait boosts/giveaways
    //  - affiliated NFTs that get linked to ChonkyChkns through traits
    mapping(address => bool) public traitModifiersList;

    ChonkyChkns public chonkyContract;
    IFeedToken public feedToken;

    constructor(address _chonkyChkns) {
        chonkyContract = ChonkyChkns(_chonkyChkns);
        feedToken = chonkyContract.feedToken();
    }

    function addTrustedContract(address _contract) external onlyOwner {
        traitModifiersList[_contract] = true;
    }

    function removeTrustedContract(address _contract) external onlyOwner {
        traitModifiersList[_contract] = false;
    }

    function addNewNumericalTrait(
        bytes32 _traitName,
        uint128 _traitPriceToIncrease,
        uint128 _traitPriceToDecrease
    ) external virtual onlyOwner {
        require(!_isValidTrait(_traitName), "Trait already exists");
        traitPrices[_traitName] = Prices(
            _traitPriceToIncrease,
            _traitPriceToDecrease
        );
    }

    function addNewCategoricalTrait(
        bytes32 _traitName,
        bytes32[] calldata _traitValues,
        uint128[] calldata _addPrices,
        uint128[] calldata _removePrices
    ) external virtual onlyOwner {
        require(
            _traitValues.length == _addPrices.length,
            "Trait value and Prices should be the same length."
        );
        require(
            _traitValues.length == _removePrices.length,
            "Trait value and Prices should be the same length."
        );
        unchecked {
            for (uint256 i; i < _traitValues.length; ++i) {
                bytes32 traitValue = _traitValues[i];
                require(
                    !_isValidCategoricalTrait(_traitName, traitValue),
                    "Categorical trait already exists"
                );
                categoricalTraitPrices[_traitName][traitValue] = Prices(
                    _addPrices[i],
                    _removePrices[i]
                );
            }
        }
    }

    function addNewFreeFormTrait(
        bytes32 _traitName,
        uint128 _addPrice,
        uint128 _removePrice
    ) external virtual onlyOwner {
        require(!_isValidTrait(_traitName), "Trait already exists");
        traitPrices[_traitName] = Prices(_addPrice, _removePrice);
    }

    function updateNumericalTraitPrice(
        bytes32 _traitName,
        uint128 _traitIncreaseUnitPrice,
        uint128 _traitDecreaseUnitPrice
    ) external virtual onlyOwner {
        _requireValidTrait(_traitName);
        traitPrices[_traitName] = Prices(
            _traitIncreaseUnitPrice,
            _traitDecreaseUnitPrice
        );
    }

    function updateCategoricalTraitPrice(
        bytes32 _traitName,
        bytes32 _traitValue,
        uint128 _traitAddPrice,
        uint128 _traitRemovePrice
    ) external virtual onlyOwner {
        _requireValidCategoricalTrait(_traitName, _traitValue);
        categoricalTraitPrices[_traitName][_traitValue] = Prices(
            _traitAddPrice,
            _traitRemovePrice
        );
    }

    function updateFreeFormTraitPrice(
        bytes32 _traitName,
        uint128 _traitIncreaseUnitPrice,
        uint128 _traitDecreaseUnitPrice
    ) external virtual onlyOwner {
        _requireValidTrait(_traitName);
        traitPrices[_traitName] = Prices(
            _traitIncreaseUnitPrice,
            _traitDecreaseUnitPrice
        );
    }

    // GETTERS
    function getNumericalTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (uint256)
    {
        _requireValidTrait(_traitName);
        return numericalTraits[_tokenId][_traitName];
    }

    function getCategoricalTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (bytes32)
    {
        bytes32 traitValue = categoricalTraits[_tokenId][_traitName];
        _requireValidCategoricalTrait(_traitName, traitValue);
        return traitValue;
    }

    function getFreeFormTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (bytes32)
    {
        _requireValidTrait(_traitName);
        return freeFormTraits[_tokenId][_traitName];
    }

    function getSortedTokenIdsByTrait(bytes32 _traitName, bool ascending)
        external
        view
        returns (uint256[2][] memory)
    {
        _requireValidTrait(_traitName);
        uint256 numTokens = chonkyContract.totalSupply();
        uint256[2][] memory ranks = new uint256[2][](numTokens);

        unchecked {
            uint256 ranksLength = 0;
            for (uint256 i = 0; i < numTokens; ++i) {
                uint256 traitValue = numericalTraits[i][_traitName];
                if (traitValue > 0) {
                    ranks[ranksLength] = [i, traitValue];
                    ranksLength++;
                }
            }
            if (ranksLength > 0) {
                _quickSortArrayOfTuples(ranks, 0, ranksLength - 1);
            }
            uint256[2][] memory sortedTokens = new uint256[2][](ranksLength);
            if (ascending) {
                for (uint256 i = 0; i < ranksLength; ++i) {
                    sortedTokens[i] = ranks[i];
                }
            } else {
                for (uint256 i = 0; i < ranksLength; ++i) {
                    sortedTokens[i] = ranks[ranksLength - i - 1];
                }
            }
            return sortedTokens;
        }
    }

    function getNumericalTraitIncreasePrice(bytes32 _traitName)
        external
        view
        returns (uint128)
    {
        _requireValidTrait(_traitName);
        return traitPrices[_traitName].addPrice;
    }

    function getNumericalTraitDecreasePrice(bytes32 _traitName)
        external
        view
        returns (uint128)
    {
        _requireValidTrait(_traitName);
        return traitPrices[_traitName].removePrice;
    }

    function getCategoricalTraitAddPrice(
        bytes32 _traitName,
        bytes32 _traitValue
    ) external view returns (uint128) {
        _requireValidCategoricalTrait(_traitName, _traitValue);
        return categoricalTraitPrices[_traitName][_traitValue].addPrice;
    }

    function getCategoricalTraitRemovePrice(
        bytes32 _traitName,
        bytes32 _traitValue
    ) external view returns (uint128) {
        _requireValidCategoricalTrait(_traitName, _traitValue);
        return categoricalTraitPrices[_traitName][_traitValue].removePrice;
    }

    function getFreeFormTraitAddPrice(bytes32 _traitName)
        external
        view
        returns (uint128)
    {
        _requireValidTrait(_traitName);
        return traitPrices[_traitName].addPrice;
    }

    function getFreeFormTraitRemovePrice(bytes32 _traitName)
        external
        view
        returns (uint128)
    {
        _requireValidTrait(_traitName);
        return traitPrices[_traitName].removePrice;
    }

    // SETTERS

    function setFeedToken(address _feedToken) external onlyOwner {
        feedToken = IFeedToken(_feedToken);
    }

    function increaseNumericalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        uint256 _countToAdd
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );
        Prices memory traitPrice = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, _countToAdd * uint256(traitPrice.addPrice));
        numericalTraits[_tokenId][_traitName] += _countToAdd;
    }

    function decreaseNumericalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        uint256 _countToSubtract
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );
        Prices memory traitPrice = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(
            tokenOwner,
            _countToSubtract * uint256(traitPrice.removePrice)
        );
        numericalTraits[_tokenId][_traitName] -= _countToSubtract;
    }

    function setCategoricalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        bytes32 _traitValue
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );
        Prices memory traitPrice = categoricalTraitPrices[_traitName][
            _traitValue
        ];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, uint256(traitPrice.addPrice));
        categoricalTraits[_tokenId][_traitName] = _traitValue;
    }

    function removeCategoricalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );

        Prices memory traitPrice = categoricalTraitPrices[_traitName][
            categoricalTraits[_tokenId][_traitName]
        ];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, uint256(traitPrice.removePrice));
        categoricalTraits[_tokenId][_traitName] = 0;
    }

    function setFreeFormTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        bytes32 _traitValue
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );
        Prices memory traitPrice = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, uint256(traitPrice.addPrice));
        freeFormTraits[_tokenId][_traitName] = _traitValue;
    }

    function removeFreeFormTraitForToken(uint256 _tokenId, bytes32 _traitName)
        external
    {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );

        Prices memory traitPrice = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, uint256(traitPrice.removePrice));
        freeFormTraits[_tokenId][_traitName] = 0;
    }

    // INTERNAL FUNCTIONS

    function _isTrustedCaller() internal view returns (bool) {
        return traitModifiersList[_msgSender()];
    }

    function _quickSortArrayOfTuples(
        uint256[2][] memory arr,
        uint256 left,
        uint256 right
    ) internal pure {
        unchecked {
            uint256 i = left;
            uint256 j = right;
            if (i == j) return;
            uint256 pivot = arr[uint256(left + (right - left) / 2)][1];
            while (i <= j) {
                while (arr[uint256(i)][1] < pivot) i++;
                while (pivot < arr[uint256(j)][1]) j--;
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (
                        arr[uint256(j)],
                        arr[uint256(i)]
                    );
                    i++;
                    if (j == 0) break;
                    j--;
                }
            }
            if (left < j) _quickSortArrayOfTuples(arr, left, j);
            if (i < right) _quickSortArrayOfTuples(arr, i, right);
        }
    }

    function _requireValidTrait(bytes32 _traitName) internal view {
        require(_isValidTrait(_traitName), "This trait does not exist");
    }

    function _requireValidCategoricalTrait(
        bytes32 _traitName,
        bytes32 _traitValue
    ) internal view {
        require(
            _isValidCategoricalTrait(_traitName, _traitValue),
            "This trait does not exist"
        );
    }

    function _isValidTrait(bytes32 _traitName) internal view returns (bool) {
        Prices memory existingPrices = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            return existingPrices.addPrice + existingPrices.removePrice > 0;
        }
    }

    function _isValidCategoricalTrait(bytes32 _traitName, bytes32 _traitValue)
        internal
        view
        returns (bool)
    {
        Prices memory existingPrices = categoricalTraitPrices[_traitName][
            _traitValue
        ];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            return existingPrices.addPrice + existingPrices.removePrice > 0;
        }
    }
}
