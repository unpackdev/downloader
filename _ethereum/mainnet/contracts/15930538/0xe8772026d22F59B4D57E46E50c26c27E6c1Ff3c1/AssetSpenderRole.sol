// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./DataStructures.sol";


abstract contract AssetSpenderRole is DataStructures {

    error OnlyAssetSpenderError();

    address[] public assetSpenderList;
    mapping(address => OptionalValue) public assetSpenderListIndex;

    event SetAssetSpender(address indexed account, bool indexed value);

    modifier onlyAssetSpender {
        if (!isAssetSpender(msg.sender)) {
            revert OnlyAssetSpenderError();
        }

        _;
    }

    function isAssetSpender(address _account) public view virtual returns (bool) {
        return assetSpenderListIndex[_account].isSet;
    }

    function assetSpenderCount() public view virtual returns (uint256) {
        return assetSpenderList.length;
    }

    function _setAssetSpender(address _account, bool _value) internal virtual {
        if (_value) {
            uniqueAddressListAdd(assetSpenderList, assetSpenderListIndex, _account);
        } else {
            uniqueAddressListRemove(assetSpenderList, assetSpenderListIndex, _account);
        }

        emit SetAssetSpender(_account, _value);
    }
}
