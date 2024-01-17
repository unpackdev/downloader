// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./DataStructures.sol";


abstract contract MultichainRouterRole is DataStructures {

    error OnlyMultichainRouterError();

    address[] public multichainRouterList;
    mapping(address => OptionalValue) public multichainRouterIndexMap;

    event SetMultichainRouter(address indexed account, bool indexed value);

    modifier onlyMultichainRouter() {
        if (!isMultichainRouter(msg.sender)) {
            revert OnlyMultichainRouterError();
        }

        _;
    }

    function isMultichainRouter(address _account) public view virtual returns (bool) {
        return multichainRouterIndexMap[_account].isSet;
    }

    function multichainRouterCount() public view virtual returns (uint256) {
        return multichainRouterList.length;
    }

    function _setMultichainRouter(address _account, bool _value) internal virtual {
        uniqueAddressListUpdate(multichainRouterList, multichainRouterIndexMap, _account, _value);

        emit SetMultichainRouter(_account, _value);
    }
}
