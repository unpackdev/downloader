// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Context.sol";
import "./AccessControl.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract MetaTxContext is Context, AccessControl {
    bytes32 public constant FORWARDER_ROLE = keccak256("FORWARDER_ROLE");

    constructor(address trustedForwarder) {
        _setupRole(FORWARDER_ROLE, trustedForwarder);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return hasRole(FORWARDER_ROLE, forwarder);
    }

    function _msgSender() internal view virtual override returns (address payable sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}
