//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title OpenSea contract helper that defines a few things
/// @author Simon Fremaux (@dievrarump)
/// @dev This is a contract used to add OpenSea's support
///      This is a contract made to work with upgradeable contract,
///      if you ever add state variables, you must update __gap accordingly.
///      -> https://forum.openzeppelin.com/t/what-exactly-is-the-reason-for-uint256-50-private-gap/798
///      if you do not use Upgradeable contracts, you should comment the line that defines __gap
contract BaseOpenSea {
    string private _contractURI;
    ProxyRegistry private _proxyRegistry;

    /// @dev If you ever add new state variable please add BEFORE this comment, and update __gap accordingly
    /// @dev https://forum.openzeppelin.com/t/what-exactly-is-the-reason-for-uint256-50-private-gap/798
    uint256[10] private __gap;

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    //          about a contract (owner, royalties etc...)
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Helper for OpenSea gas-less trading
    /// @dev Allows to check if `operator` is owner's OpenSea proxy
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            // we have a proxy address
            address(proxyRegistry) != address(0) &&
            // current operator is owner's proxy address
            address(proxyRegistry.proxies(owner)) == operator;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
