//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BaseContractUtils
/// @author Simon Fremaux (@dievardump)
abstract contract BaseContractUtils {
    string private _contractURI;
    address private _proxyRegistry;

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    //          about a contract (owner, royalties etc...)
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }
}
