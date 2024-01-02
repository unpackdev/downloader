// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./RolesUpgradeable.sol";
import "./BitMaps.sol";
import "./Helper.sol";
import "./Constants.sol";

abstract contract BusinessAddressesUpgradeable is RolesUpgradeable {
    using Helper for address;
    using BitMaps for BitMaps.BitMap;

    error BusinessAddress__NotAccepted();

    BitMaps.BitMap private _isAccepted;

    function __BusinessAddressUpgradeable_init(address[] calldata businessAddresses) internal onlyInitializing {
        __BusinessAddressUpgradeable_init_unchained(businessAddresses);
    }

    function __BusinessAddressUpgradeable_init_unchained(
        address[] calldata businessAddresses
    ) internal onlyInitializing {
        uint256 length = businessAddresses.length;
        for (uint256 i = 0; i < length; ) {
            _setBusinessAddress(businessAddresses[i], true);
            unchecked {
                ++i;
            }
        }
    }

    function isBusiness(address businessAddress) public view returns (bool) {
        return _isAccepted.get(businessAddress.toUint256());
    }

    function setBusinessAddress(address address_, bool status_) external onlyRole(OPERATOR_ROLE) {
        _setBusinessAddress(address_, status_);
    }

    function _setBusinessAddress(address address_, bool status_) internal {
        uint256 collection = address_.toUint256();
        _isAccepted.setTo(collection, status_);
    }

    function _onlyBusiness(address account_) internal view {
        if (!_isAccepted.get(account_.toUint256())) revert BusinessAddress__NotAccepted();
    }

    uint256[19] private __gap;
}
