// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ProxyOFT.sol";
import "./AccessControlUpgradeable.sol";

contract MntProxyOft is ProxyOFT, AccessControlUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _lzEndpoint,
        address _token,
        address _owner
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        innerToken = IERC20(_token);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function _msgSender() internal view override(ContextUpgradeable, Context) returns (address) {
        return ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, Context) returns (bytes calldata) {
        return ContextUpgradeable._msgData();
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(OFTCore, AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IOFTCore).interfaceId ||
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC20).interfaceId; // EIP-20 - 0x36372b07
    }

    /// @dev Function with this modifier can be executed only by accounts with DEFAULT_ADMIN_ROLE.
    ///      Override standard `Ownable` behavior to keep original implementation of `LzApp` contract.
    modifier onlyOwner() override {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }
}
