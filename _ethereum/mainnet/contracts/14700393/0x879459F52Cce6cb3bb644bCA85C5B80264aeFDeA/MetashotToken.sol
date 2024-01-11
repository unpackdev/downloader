// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract MetashotToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    // Total token allocations
    uint256 public maxSupply;

    /**
     * @dev Throws if called by any account other than a controller.
     */
    modifier onlyController() {
        require(controllers[msg.sender], "MetashotToken: caller is not a controller");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("Metashot", "METASHOT");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        maxSupply = 40000000000 ether;
    }

    // @dev only controller functions
    function mint(address to, uint256 amount) public onlyController {
        require((amount + totalSupply()) <= maxSupply, "MetashotToken: maximum has been reached");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyController {
        _burn(from, amount);
    }
    // @dev end of only controller functions

    // @dev only owner functions
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
    // @dev end of only owner functions


    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
