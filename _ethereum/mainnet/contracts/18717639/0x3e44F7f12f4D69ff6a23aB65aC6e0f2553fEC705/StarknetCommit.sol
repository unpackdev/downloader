// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "./IStarknetCore.sol";
import "./Uint256.sol";

/// @notice Allows StarkNet transactions to be committed via a transaction on L1. The contract works in combination with a corresponding auth strategy contract on StarkNet.
/// @dev This contract is designed to be a generic standard that that can be used by any StarkNet protocol that wants to allow interactions via an L1 transaction.
contract StarknetCommit {
    using Uint256 for address;

    // prettier-ignore
    /// @notice Selector for the L1 handler in the auth strategy on StarkNet, found via:
    /// from starkware.starknet.compiler.compile import get_selector_from_name
    /// print(get_selector_from_name('commit'))
    uint256 private constant L1_COMMIT_HANDLER = 0x17dd2cbe677d6dda22dd4a01edec54ba307cd2b1f7d130707ba5a29cc019c1d;

    /// @notice The StarkNet core contract
    IStarknetCore public immutable starknetCore;

    /// @param _starknetCore The StarkNet core contract
    constructor(address _starknetCore) {
        starknetCore = IStarknetCore(_starknetCore);
    }

    /// @notice Commit a hash and the sender address to StarkNet
    /// @param authStrategy The Starknet auth strategy that will recieve the commit
    /// @param _hash The hash to commit
    function commit(uint256 authStrategy, uint256 _hash) external payable {
        uint256[] memory payload = new uint256[](2);
        payload[0] = msg.sender.toUint256();
        payload[1] = _hash;
        starknetCore.sendMessageToL2{ value: msg.value }(authStrategy, L1_COMMIT_HANDLER, payload);
    }
}
