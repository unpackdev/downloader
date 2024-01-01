// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IGetStatus.sol";
import "./IGetUserStatus.sol";
import "./VerboseReverts.sol";

import "./ERC165.sol";

bytes4 constant USER_LOCK_HASH = 0x91659165;

// Check if user is blocked and perform action
contract UserBlocklist is ERC165 {
    struct BlocklistInfo {
        bool enabled;
        address blocklist;
    }

    event BlocklistChanged(address indexed oldBlocklist, address indexed newBlocklist);
    event BlocklistStatusChanged(bool indexed newStatus);

    string internal constant USERLOCK_MESSAGE = "UserBlocklist: Action is blocked for";

    // For some gas optimization these two variables are in the same slot, so they can be read in one SLOAD
    BlocklistInfo private _blocklistInfo;

    /**
     * @param blocklist_ address of the blocklist
     */
    constructor(address blocklist_) {
        _setBlocklist(blocklist_);
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == USER_LOCK_HASH || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the address of the blocklist.
     * @return address of the blocklist
     */
    function blocklist() public view returns (address) {
        return _blocklistInfo.blocklist;
    }

    /**
     * @dev If true the blocklist is enabled, false otherwise.
     * @param state true if the blocklist is enabled, false otherwise
     */
    function _changeBlocklistState(bool state) internal virtual {
        emit BlocklistStatusChanged(state);
        _blocklistInfo.enabled = state;
    }

    /**
     * @dev Sets the address of the blocklist.
     * @param blocklist_ address of the blocklist
     */
    function _setBlocklist(address blocklist_) internal virtual {
        emit BlocklistChanged(_blocklistInfo.blocklist, blocklist_);
        _blocklistInfo.blocklist = blocklist_;

        _changeBlocklistState(blocklist_ == address(0) ? false : true);
    }

    /**
     * @dev Returns blocklist info.
     * @return Full blocklist info
     */
    function _getBlocklist() internal view returns (BlocklistInfo memory) {
        return _blocklistInfo;
    }

    /**
     * @dev Reverts if the user is blocked.
     * @param user address of the user
     * @param message message to revert with
     */
    function _checkIfActionIsAllowed(address user, string memory message) internal view virtual {
        BlocklistInfo memory ri = _blocklistInfo;
        if (!ri.enabled) return;
        _checkIfActionIsAllowed(ri.blocklist, user, message);
    }

    /**
     * @dev Reverts if the user is blocked.
     * @param blocklist_ address of the blocklist
     * @param user address of the user
     * @param message message to revert with
     */
    function _checkIfActionIsAllowed(address blocklist_, address user, string memory message) internal view virtual {
        if (IGetUserStatus(blocklist_).isUserBlocked(user)) {
            VerboseReverts._revertWithAddress(bytes(message).length > 0 ? message : USERLOCK_MESSAGE, user);
        }
    }

    /**
     * @dev Reverts if any of the users are blocked.
     * @param users array of addresses of the users
     * @param message message to revert with
     */
    function _batchCheckIfActionIsAllowed(address[] memory users, string memory message) internal view virtual {
        BlocklistInfo memory ri = _blocklistInfo;
        if (!ri.enabled) return;
        _batchCheckIfActionIsAllowed(ri.blocklist, users, message);
    }

    /**
     * @dev Reverts if any of the users are blocked.
     * @param blocklist_ address of the blocklist
     * @param users array of addresses of the users
     * @param message message to revert with
     */
    function _batchCheckIfActionIsAllowed(
        address blocklist_,
        address[] memory users,
        string memory message
    ) internal view virtual {
        bool[] memory statuses = IGetUserStatus(blocklist_).batchIsUserBlocked(users);
        for (uint256 i = 0; i < users.length; i++) {
            if (statuses[i]) {
                VerboseReverts._revertWithAddress(bytes(message).length > 0 ? message : USERLOCK_MESSAGE, users[i]);
            }
        }
    }
}
