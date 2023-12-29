// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./Address.sol";
import "./ProjectProxy.sol";

/**
 * @dev ERC721Project Upgradeable Proxy
 */
contract ERC1155ProjectProxy is ProjectProxy {
    constructor(address _impl) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_impl);
        Address.functionDelegateCall(_impl, abi.encodeWithSignature("initialize()"));
    }
}
