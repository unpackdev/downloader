// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./MasterCaller.sol";

contract TrustList is MasterCaller {
    
    mapping(address => bool) whiteMap;

    event WhiteListUpdate(address indexed _account, bool _trustable);

    function updateList(address _account, bool _trustable) public  onlyMasterCaller() {
        whiteMap[_account] = _trustable;

        emit WhiteListUpdate(_account, _trustable);
    }

    function trustable(address _account) internal returns (bool) {
        return whiteMap[_account];
    }

}
