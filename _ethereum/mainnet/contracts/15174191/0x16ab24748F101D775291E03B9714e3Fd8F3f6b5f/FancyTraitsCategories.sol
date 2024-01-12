// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AccessControlEnumerable.sol";
import "./tag.sol";

contract FancyTraitsCategories is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(address => mapping(string => bool))
        public categoryApprovedByCollection;
    mapping(address => string[]) public categoryListByCollection;

    event CategoryAddedToCollection(address _collection, string _category);
    event CategoryRemovedFromCollection(address _collection, string _category);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addCategoriesToCollections(
        address[] calldata _collections,
        string[][] calldata _categories
    ) public onlyRole(MANAGER_ROLE) {
        require(
            _collections.length == _categories.length,
            "addCategoriesToCollections: arguments must match in length"
        );

        for (uint256 i = 0; i < _collections.length; i++) {
            for (uint256 j = 0; j < _categories[i].length; j++) {
                categoryApprovedByCollection[_collections[i]][
                    _categories[i][j]
                ] = true;
                categoryListByCollection[_collections[i]].push(
                    _categories[i][j]
                );
                emit CategoryAddedToCollection(
                    _collections[i],
                    _categories[i][j]
                );
            }
        }
    }

    function clearCategoriesInCollection(address[] calldata _collections)
        public
        onlyRole(MANAGER_ROLE)
    {
        for (uint256 i = 0; i < _collections.length; i++) {
            for (
                uint256 j = 0;
                j < categoryListByCollection[_collections[i]].length;
                j++
            ) {
                delete categoryApprovedByCollection[_collections[i]][
                    categoryListByCollection[_collections[i]][j]
                ];
            }
            delete categoryListByCollection[_collections[i]];
        }
    }

    function getCategoriesByCollection(address _collection) public view returns (string[] memory) {
        return categoryListByCollection[_collection];
    }

}
