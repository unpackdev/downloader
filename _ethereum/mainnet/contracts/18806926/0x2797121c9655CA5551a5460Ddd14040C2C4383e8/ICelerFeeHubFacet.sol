// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/// @title CelerFeeHubFacet Interface
/// @author Daniel <danieldegendev@gmail.com>
interface ICelerFeeHubFacet {
    /// Registers the successful deployment of the fees to the given chain
    /// @param _chainId chain id
    /// @param _message encoded message
    function deployFeesWithCelerConfirm(uint64 _chainId, bytes memory _message) external;
}
