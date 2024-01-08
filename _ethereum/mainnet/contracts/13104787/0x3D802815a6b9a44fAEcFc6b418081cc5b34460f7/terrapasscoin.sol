// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract TerrapassCoinMainnet is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function initialize() initializer public {
        __ERC20_init("Terrapass Coin", "TPSC");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, 25000 * 10 ** decimals());
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

//Extra code added from this point on
    function burnFrom(address account, uint256 amount) public virtual override {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ModifiedAccessControl: Only DEFAULT_ADMIN_ROLE may use burnFrom"
        );

        super.burnFrom(account, amount);
    }
    function burn(uint256 amount) public virtual override {
      require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ModifiedAccessControl: Only DEFAULT_ADMIN_ROLE may use burn"
        );

        super.burn(amount);
    }

    function multiTransfer(address[] calldata dests, uint256[] calldata values) external returns (uint256) {
       
        uint256 i = 0;
        while (i < dests.length) {
        transfer(dests[i], values[i]);
        i += 1;
        }
        return(i);
    }
}