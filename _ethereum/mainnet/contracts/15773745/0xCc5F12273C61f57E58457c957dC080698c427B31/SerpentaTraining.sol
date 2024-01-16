// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControlEnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ISerpentaTraining.sol";
import "./ISerpenta.sol";

contract SerpentaTraining is
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ISerpentaTraining
{
    /* ------------------------------------------------------------------------------------------ */
    /*                                           STORAGE                                          */
    /* ------------------------------------------------------------------------------------------ */

    /// @inheritdoc ISerpentaTraining
    address public serpenta;

    /// @dev (uint256 id) returns (TokenInfo tokenInfo)
    mapping(uint256 => TokenInfo) internal _getTokenInfo;

    /// @dev (address user) returns (UserInfo userInfo)
    mapping(address => UserInfo) internal _getUserInfo;

    /* ------------------------------------------------------------------------------------------ */
    /*                                         INITIALIZER                                        */
    /* ------------------------------------------------------------------------------------------ */

    function initialize(address admin, address _serpenta) external initializer {
        require(admin != address(0), "Invalid admin");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        __ReentrancyGuard_init();
        _pause();

        serpenta = _serpenta;
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                      PUBLIC FUNCTIONS                                      */
    /* ------------------------------------------------------------------------------------------ */

    /// @inheritdoc ISerpentaTraining
    function enableTraining(uint256[] calldata ids) external nonReentrant whenNotPaused {
        unchecked {
            uint256 len = ids.length;
            if (len == 0) revert InvalidTokens();

            uint256[] storage userIds = _getUserInfo[msg.sender].ids;
            uint64 ts = uint64(block.timestamp);
            for (uint256 i; i < len; i++) {
                uint256 id = ids[i];

                TokenInfo storage ti = _getTokenInfo[id];
                ti.lastTimestamp = ts;

                userIds.push(id);
            }

            // transferFrom checks if the token is owned by `from` and if this contract is approved
            ISerpenta(serpenta).batchTransferFrom(msg.sender, address(this), ids);
        }
    }

    /// @inheritdoc ISerpentaTraining
    function disableTraining(uint256[] calldata ids) external nonReentrant whenNotPaused {
        uint256 len = ids.length;
        uint256 userLen = _getUserInfo[msg.sender].ids.length;
        if (userLen == 0) revert NoTokensInTraining();
        if (len == 0 || len > userLen) revert InvalidTokens();

        _checkIdsAndRemoveStaked(msg.sender, ids);

        ISerpenta(serpenta).batchSafeTransferFrom(address(this), msg.sender, ids, "");
    }

    /// @inheritdoc ISerpentaTraining
    function getUserTokens(address user) external view returns (uint256[] memory) {
        return _getUserInfo[user].ids;
    }

    /// @inheritdoc ISerpentaTraining
    function inTraining(uint256[] calldata ids) external view returns (bool[] memory b) {
        uint256 len = ids.length;
        if (len == 0) return b;

        b = new bool[](len);
        for (uint256 i; i < len; i++) {
            b[i] = _getTokenInfo[ids[i]].lastTimestamp != 0;
        }
    }

    /// @inheritdoc ISerpentaTraining
    function inTrainingFor(uint256[] calldata ids) external view returns (uint256[] memory ts) {
        uint256 len = ids.length;
        if (len == 0) return ts;

        uint256 bts = block.timestamp;
        ts = new uint256[](len);
        for (uint256 i; i < len; i++) {
            uint256 itf = _getTokenInfo[ids[i]].lastTimestamp;
            ts[i] = itf == 0 ? 0 : bts - itf;
        }
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                       ADMIN FUNCTIONS                                      */
    /* ------------------------------------------------------------------------------------------ */

    /// @notice Pauses the contract.
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Sets the new Serpenta contract address.
    function setSerpenta(address _serpenta) external onlyRole(DEFAULT_ADMIN_ROLE) {
        serpenta = _serpenta;
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                     INTERNAL FUNCTIONS                                     */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Checks if all IDs in `checkIds` are present also in `userIds`.
    function _checkIds(uint256[] calldata checkIds, uint256[] memory userIds) internal pure {
        uint256 checkNr = checkIds.length;
        // checking nothing
        if (checkNr == 0) return;

        uint256 userNr = userIds.length;

        if (userNr == 0) revert NoTokensInTraining();
        if (checkNr > userNr) revert InvalidTokens();

        unchecked {
            for (uint256 i; i < checkNr; i++) {
                uint256 checkId = checkIds[i];
                bool staked;

                for (uint256 j; j < userNr; j++) {
                    if (checkId == userIds[j]) {
                        staked = true;
                        break;
                    }
                }

                if (!staked) revert TokenNotOwned();
            }
        }
    }

    /// @dev Checks if all IDs in `ids` are present in `user`'s IDs and removes them.
    function _checkIdsAndRemoveStaked(address user, uint256[] calldata ids) internal {
        unchecked {
            // length checks done in disableTraining()
            uint256[] storage userIdsPtr = _getUserInfo[user].ids;
            uint256[] memory userIdsCache = userIdsPtr;

            // Normal order:
            // ids = [1]
            // user.ids == [1, 2, 3]
            // -> want to remove an id that is not the last

            // have to "swap" id with last item
            // user.ids == [3, 2, 3]

            // pop to remove last item
            // user.ids == [3, 2]

            // total: SSTORE + .pop()

            // Reverse order:
            // ids = [3]
            // user.ids == [1, 2, 3]

            // want to remove last id, can pop directly
            // user.ids == [1, 2]

            // total: .pop()
            uint256 userLen = userIdsCache.length;
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                bool check;

                for (uint256 j; j < userLen; j++) {
                    if (id != userIdsCache[j]) continue;

                    // overwrite current item with last item
                    uint256 lastIndex = userLen - 1;
                    if (lastIndex != j) {
                        uint256 lastId = userIdsCache[lastIndex];
                        userIdsPtr[j] = lastId;
                        userIdsCache[j] = lastId;
                    }

                    // pop to delete last item
                    userIdsPtr.pop();
                    userLen--;

                    // set ts to 0
                    delete _getTokenInfo[id].lastTimestamp;

                    check = true;
                    break;
                }

                if (!check) revert TokenNotOwned();
            }
        }
    }
}
