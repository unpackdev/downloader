// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IENSResolver.sol";

abstract contract Resolver is IENSResolver {
    mapping(bytes4 => bool) internal _supportedInterfaces;

    constructor() {
        registerSupportedInterface(type(IERC165).interfaceId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    function registerSupportedInterface(bytes4 interfaceID)
        internal
    {
        _supportedInterfaces[interfaceID] = true;
    }
}
