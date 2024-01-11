// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";

abstract contract ERC2771ContextUpgradeable is OwnableUpgradeable {
    address private _trustedForwarder;

    function setTrustedForwarder(address newTrustedForwarder) external onlyOwner {
        _trustedForwarder = newTrustedForwarder;
    }

    function isTrustedForwarder(address trustedForwarder) public view returns (bool) {
        return trustedForwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function __ERC2771ContextUpgradeable_init() internal onlyInitializing {
        __Ownable_init();

        __ERC2771ContextUpgradeable_init_unchained();
    }

    function __ERC2771ContextUpgradeable_init_unchained() internal onlyInitializing {
    }

    uint256[49] private __gap;
}