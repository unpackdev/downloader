// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "./Structs.sol";

/// @title Fee Distributor Interface
/// @author Daniel <danieldegendev@gmail.com>
interface IFeeDistributorFacet {
    // this is guarateed to get the tokens before being executed
    /// Pushes the fee to the desired receivers
    /// @param _token the token address being received
    /// @param _amount amount of tokens being received
    /// @param _dto the dto of the fee store to determine the split of _amount
    /// @dev an updated dto needs to be created since the receiving amount is not
    ///      matching the sent amount anymore. The contract will 100% receive the
    ///      _token _amount before being executed
    /// @dev only available to FEE_DISTRIBUTOR_PUSH_ROLE role
    /// @dev if the token doesn't match, it will fail.
    function pushFees(address _token, uint256 _amount, FeeConfigSyncHomeDTO calldata _dto) external payable;
}
