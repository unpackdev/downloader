// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Ownable.sol";

import "./UserBlocklist.sol";
import "./BridgeRoles.sol";

abstract contract BridgeUserBlocklist is BridgeRoles, UserBlocklist {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, UserBlocklist) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || UserBlocklist.supportsInterface(interfaceId);
    }

    string internal constant USERBLOCK_MESSAGE = "Bridge: Action is blocked for";

    constructor(address blocklist_) UserBlocklist(blocklist_) {
        if (blocklist_ == address(0)) {
            _changeBlocklistState(false);
        }
    }

    function changeBlocklistState(bool state) external onlyAdmin {
        _changeBlocklistState(state);
    }

    function setBlocklist(address blocklist_) external onlyOwner {
        _setBlocklist(blocklist_);
    }

    modifier userIsNotBlocked(address user) {
        _checkIfActionIsAllowed(user, USERBLOCK_MESSAGE);
        _;
    }
}
