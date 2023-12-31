// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IBaseCollectionTypeUpgradeable.sol";
import "./BaseUpgradeable.sol";
import "./Constants.sol";

abstract contract BaseTypeCollectionUpgradeable is IBaseCollectionTypeUpgradeable, BaseUpgradeable {
    mapping(uint256 => TypeInfo) internal _typeInfo;
    mapping(uint256 => uint256) internal _sold;

    function __BaseTypeCollection_init(
        uint256[] calldata types_,
        TypeInfo[] calldata typeInfos_
    ) internal onlyInitializing {
        __BaseTypeCollection_init_unchained(types_, typeInfos_);
    }

    function __BaseTypeCollection_init_unchained(
        uint256[] calldata types_,
        TypeInfo[] calldata typeInfos_
    ) internal onlyInitializing {
        uint256 length = typeInfos_.length;
        for (uint256 i = 0; i < length; ) {
            unchecked {
                _typeInfo[types_[i]] = typeInfos_[i];
                ++i;
            }
        }
    }

    function getSold(uint256 typeNFT) external view returns (uint256) {
        return _sold[typeNFT];
    }

    function getTypeNFT(uint256 typeNFT) external view returns (bool, address, uint256, uint256) {
        return (
            _typeInfo[typeNFT].executeOperation,
            _typeInfo[typeNFT].paymentToken,
            _typeInfo[typeNFT].price,
            _typeInfo[typeNFT].limit
        );
    }

    function setTypes(uint256[] calldata types_, TypeInfo[] calldata typeInfos_) external onlyRole(OPERATOR_ROLE) {
        _setTypes(types_, typeInfos_);
    }

    function _setTypes(uint256[] calldata types_, TypeInfo[] calldata typeInfos_) internal {
        uint256 length = types_.length;
        for (uint256 i = 0; i < length; ) {
            _setType(types_[i], typeInfos_[i]);
            emit SetTypeNFT(types_[i], typeInfos_[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _setType(uint256 type_, TypeInfo calldata typeInfo_) internal {
        if (_sold[type_] > typeInfo_.limit) revert BaseCollectionTypeUpgradeable__ExceedLimit(type_);
        _typeInfo[type_] = typeInfo_;
    }

    function _setSold(uint256 typeNFT_, uint256 quantity_) internal {
        _sold[typeNFT_] = _sold[typeNFT_] + quantity_;
        if (_sold[typeNFT_] > _typeInfo[typeNFT_].limit) revert BaseCollectionTypeUpgradeable__ExceedLimit(typeNFT_);
    }

    uint256[48] private __gap;
}
