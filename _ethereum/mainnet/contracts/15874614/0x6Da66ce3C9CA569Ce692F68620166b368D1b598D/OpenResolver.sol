// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (utils/introspection/ERC165Ckecker.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165Checker.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//        |
//        ————————————————
//        |              |
//   OpenChecker     OpenERC173
//        |              |
//    OpenGetter    OpenRegistry
//        |              |
//        ————————————————
//        |
//  OpenResolver —— IOpenResolver
//
pragma solidity 0.8.9;

import "./OpenRegistry.sol";
import "./OpenGetter.sol";
import "./IOpenResolver.sol";

abstract contract OpenResolver is IOpenResolver, OpenRegistry, OpenGetter {
    /// @notice isValid, by default all addresses valid
    modifier onlyValid(address addr) override (OpenRegistry) {
        require(isCollection(addr), "Not Collection");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenRegistry, OpenGetter)
        returns (bool)
    {
        return interfaceId == type(IOpenResolver).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function getCollectionsInfos(
        address[] memory collections,
        address account,
        bytes4[] memory interfaceIds
    ) public view override (IOpenResolver) returns (CollectionInfos[] memory collectionsInfos) {
        collectionsInfos = new CollectionInfos[](collections.length);
        for (uint256 i = 0; i < collections.length; i++) {
            collectionsInfos[i] = _getCollectionInfos(collections[i], account, interfaceIds);
        }
    }

    function _getCollectionsInfos(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (CollectionInfos[] memory collectionsInfos)
    {
        CollectionInfos[] memory collectionsInfosAll =
            getCollectionsInfos(getAddresses(), account, interfaceIds);

        uint256 len;
        for (uint256 i = 0; i < collectionsInfosAll.length; i++) {
            if (collectionsInfosAll[i].balanceOf > 0 || collectionsInfosAll[i].owner == account) {
                len++;
            }
        }

        collectionsInfos = new CollectionInfos[](len);

        uint256 j;
        for (uint256 i = 0; i < collectionsInfosAll.length; i++) {
            if (collectionsInfosAll[i].balanceOf > 0 || collectionsInfosAll[i].owner == account) {
                collectionsInfos[j++] = collectionsInfosAll[i];
            }
        }
    }
}
