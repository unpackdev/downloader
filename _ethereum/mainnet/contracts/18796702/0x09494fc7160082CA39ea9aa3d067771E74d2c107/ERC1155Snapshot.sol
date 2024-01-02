// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155Upgradeable.sol";
import "./ArraysUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "./ERC1155SupplyUpgradeable.sol";

/**
 * @title ERC1155SnapshotUpgradeable
 * @dev Abstract contract extending ERC1155 with snapshot mechanism.
 * Snapshots capture token balances and total supply at specific points in time.
 */
abstract contract ERC1155SnapshotUpgradeable is
    Initializable,
    ERC1155SupplyUpgradeable
{
    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * @dev Struct to store snapshots data.
     */
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(uint256 => mapping(address => Snapshots))
        private _accountBalanceSnapshots;
    mapping(uint256 => Snapshots) private _totalSupplySnapshots;

    CountersUpgradeable.Counter private _currentSnapshotId;

    event Snapshot(uint256 id);

    /**
     * @dev Initializes the contract by setting the URI for all token types.
     * @param _uri String of the URI.
     */
    function __ERC1155Snapshot_init(
        string memory _uri
    ) internal onlyInitializing {
        __ERC1155_init_unchained(_uri);
        __ERC1155Snapshot_init_unchained();
    }

    function __ERC1155Snapshot_init_unchained() internal onlyInitializing {}

    /**
     * @dev Creates a new snapshot and returns its ID.
     * @return The ID of the created snapshot.
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();
        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of an account for a specific token ID at a given snapshot ID.
     * @param account Address whose balance to retrieve.
     * @param tokenId Token ID for which to retrieve the balance.
     * @param snapshotId Snapshot ID to retrieve the balance at.
     * @return The balance of the account at the given snapshot ID.
     */
    function balanceOfAt(
        address account,
        uint256 tokenId,
        uint256 snapshotId
    ) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _accountBalanceSnapshots[tokenId][account]
        );
        return snapshotted ? value : balanceOf(account, tokenId);
    }

    /**
     * @dev Retrieves the total supply of a specific token ID at a given snapshot ID.
     * @param tokenId Token ID for which to retrieve the total supply.
     * @param snapshotId Snapshot ID to retrieve the total supply at.
     * @return The total supply of the token at the given snapshot ID.
     */
    function totalSupplyAt(
        uint256 tokenId,
        uint256 snapshotId
    ) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _totalSupplySnapshots[tokenId]
        );
        return snapshotted ? value : totalSupply(tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning.
     * Updates account snapshots and total supply snapshots before the transfer.
     * @param operator Address which initiated the transfer.
     * @param from Address from which tokens are transferred.
     * @param to Address to which tokens are transferred.
     * @param ids Array of token IDs being transferred.
     * @param amounts Array of amounts of tokens being transferred.
     * @param data Additional data with no specified format.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            if (from == address(0)) {
                _updateAccountSnapshot(to, ids[i]);
                _updateTotalSupplySnapshot(ids[i]);
            } else if (to == address(0)) {
                _updateAccountSnapshot(from, ids[i]);
                _updateTotalSupplySnapshot(ids[i]);
            } else {
                _updateAccountSnapshot(from, ids[i]);
                _updateAccountSnapshot(to, ids[i]);
            }
        }
    }

    function _valueAt(
        uint256 snapshotId,
        Snapshots storage snapshots
    ) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC1155Snapshot: id is 0");
        require(
            snapshotId <= _currentSnapshotId.current(),
            "ERC1155Snapshot: nonexistent id"
        );

        uint256 index = snapshots.ids.findUpperBound(snapshotId);
        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account, uint256 tokenId) private {
        _updateSnapshot(
            _accountBalanceSnapshots[tokenId][account],
            balanceOf(account, tokenId)
        );
    }

    function _updateTotalSupplySnapshot(uint256 tokenId) private {
        _updateSnapshot(_totalSupplySnapshots[tokenId], totalSupply(tokenId));
    }

    function _updateSnapshot(
        Snapshots storage snapshots,
        uint256 currentValue
    ) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(
        uint256[] storage ids
    ) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    uint256[50] private __gap;
}
