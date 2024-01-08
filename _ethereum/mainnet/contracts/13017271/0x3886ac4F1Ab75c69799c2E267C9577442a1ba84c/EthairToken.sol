// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";

/**
 * @title Ethair Token Contract.
 * @dev Standard ERC20 token contract with metatransaction capability.
 */
contract EthairToken is ERC2771ContextUpgradeable, ERC20PresetMinterPauserUpgradeable {

    /*----------  Initializer  ----------*/

    /**
     * @param name_ Token Name
     * @param symbol_ Token Symbol
     * @param forwarder_ Trusted forwarder address
     */
    function initialize(string memory name_, string memory symbol_, address forwarder_)
        initializer
        public
    {
      __ERC2771Context_init(forwarder_);
      __ERC20PresetMinterPauser_init(name_, symbol_);
    }

    function _msgSender() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender) {
        sender = ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

}