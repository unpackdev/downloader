// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.14;

import "./ContextUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract ERC2771ContextUpgradeable is
    ContextUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant FORWARDER_ROLE = keccak256("FORWARDER_ROLE");

    function __ERC2771ContextUpgradeable_init(address trustedForwarder)
        internal
        onlyInitializing
    {
        __ERC2771ContextUpgradeable_init_unchained(trustedForwarder);
    }

    function __ERC2771ContextUpgradeable_init_unchained(
        address trustedForwarder
    ) internal onlyInitializing {
        _grantRole(FORWARDER_ROLE, trustedForwarder);
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (hasRole(FORWARDER_ROLE, msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }
}
