// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

contract AvailableIdsMixinUpgradeable is Initializable {
    uint256[] public availableIds;

    function __AvailableIdsMixinUpgradeable_init() internal onlyInitializing {
        __AvailableIdsMixinUpgradeable_init_unchained();
    }

    function __AvailableIdsMixinUpgradeable_init_unchained()
        internal
        onlyInitializing
    {
        availableIds = new uint256[](0);
    }

    function _addIds(uint256[] memory _ids) internal {
        require(
            _ids.length > 0,
            "FactorySequentialERC1155Upgradeable#addIds: must add at least 1 id"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            availableIds.push(_ids[i]);
        }
    }

    function availableSupply() public view returns (uint256) {
        return availableIds.length;
    }

    

    uint256[49] private __gap;
}
