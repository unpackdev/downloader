// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import "./ITransferHook.sol";

import "./ERC20SnapshotUpgradeable.sol";

/**
 * @title EthixERC20Snapshot
 * @notice Modified OZ ERC20Snapshot to add Aave stuff
 * @author Ethichub
 **/
contract EthixERC20Snapshot is ERC20SnapshotUpgradeable {

    function __EthixERC20Snapshot_init(string memory name_, string memory symbol_)
        public
        initializer
    {
        __ERC20Snapshot_init();
        __ERC20_init(name_, symbol_);
    }

    /// @dev reference to the Ethix governance contract to call (if initialized) on _beforeTokenTransfer
    /// !!! IMPORTANT The Ethix governance is considered a trustable contract, being its responsibility
    /// to control all potential reentrancies by calling back the this contract
    ITransferHook public _ethixGovernance;

    function _setEthixGovernance(ITransferHook ethixGovernance) internal virtual {
        _ethixGovernance = ethixGovernance;
    }

}
