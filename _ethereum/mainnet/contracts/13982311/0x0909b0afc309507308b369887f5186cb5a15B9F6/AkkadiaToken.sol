// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

/// @custom:security-contact security@akkadia.one
contract AkkadiaToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 private _maxSupply;
    uint256 private _initialSupply;
    address private _origin;
    uint256 private _version;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("Akkadia", "AKKADI");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _version = 1;
        _origin = msg.sender;
        _maxSupply = 600_000_000 * 10 ** decimals();
        _initialSupply = 324_000_000 * 10 ** decimals(); // 54% of the max supply

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(_origin, _initialSupply);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    /**
     * @dev Returns the initial supply that was minted when the contract was deployed.
     */
    function initialSupply() public view virtual returns (uint256) {
        return _initialSupply;
    }

    /**
     * @dev Returns the max supply that can be minted.
     */
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev See {ERC20Upgradeable-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(totalSupply() + amount <= maxSupply(), "AkkadiaToken: max supply exceeded");
        super._mint(account, amount);
    }

    function getOwner() public view returns(address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, getRoleMemberCount(DEFAULT_ADMIN_ROLE) - 1);
    }

    function origin() public view returns(address) {
        return _origin;
    }
    
    function version() public view returns(uint256) {
        return _version;
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

    function setVersion(uint256 version_) public onlyRole(UPGRADER_ROLE) {
        _version = version_;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}