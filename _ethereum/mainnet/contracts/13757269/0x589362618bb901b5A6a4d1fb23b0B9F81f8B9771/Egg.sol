// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./Proxied.sol";

contract Egg is ERC20Upgradeable, Proxied {
    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    // constructor() {
    //     __ERC20_init('EGG', 'EGG');
    // }

    function initialize() public initializer {
        __ERC20_init('EggHeist.game Egg', 'EGG');
    }

    /**
     * mints $EGG to a recipient
     * @param to the recipient of the $EGG
     * @param amount the amount of $EGG to mint
     */
    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], 'Only controllers can mint');
        _mint(to, amount);
    }

    /**
     * burns $EGG from a holder
     * @param from the holder of the $EGG
     * @param amount the amount of $EGG to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], 'Only controllers can burn');
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyProxyAdmin {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyProxyAdmin {
        controllers[controller] = false;
    }
}
