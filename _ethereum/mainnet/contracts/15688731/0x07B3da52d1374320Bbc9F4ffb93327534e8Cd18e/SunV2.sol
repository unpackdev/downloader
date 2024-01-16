// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract SunV2 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("Sun", "SUN");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    /**
     * mints $SUN to a recipient
     * @param to the recipient of the $SUN
     * @param amount the amount of $SUN to mint
     */
    function mint(address to, uint256 amount) public {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    /**
     * burns $SUN from a holder
     * @param from the holder of the $SUN
     * @param amount the amount of $SUN to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
