// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20SnapshotUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./BlocklistableUpgradeable.sol";

/// @custom:security-contact https://telum.tech
contract RubiToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    BlocklistableUpgradable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable {

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant BLOCKLISTER_ROLE = keccak256("BLOCKLISTER_ROLE");
    bytes32 public constant TAX_FREE_ROLE = keccak256("TAX_FREE_ROLE");

    address public treasury;
    uint16 public taxFee;

    // -----------------------------------------------------------------------

    event UpdatedTreasury(address indexed sender, address indexed dao);
    event UpdatedTaxFee(address indexed sender, uint16 fee);

    // -----------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public virtual {
        // __ERC20_init("RubiToken", "RUBY");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __Blocklistable_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(BLOCKLISTER_ROLE, msg.sender);
        //_setupRole(TAX_FREE_ROLE, msg.sender);

        treasury = msg.sender;
        taxFee = 0; // NOTE: Default tax rate is 0%. A tax rate of 1% would be represented by 100.
    }

    // -----------------------------------------------------------------------

    function updateTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = _treasury;
        emit UpdatedTreasury(msg.sender, treasury);
    }

    function updateTaxFee(uint16 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        taxFee = fee;
        emit UpdatedTaxFee(msg.sender, fee);
    }

    // -----------------------------------------------------------------------

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
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

    function burn(uint256 amount) override public onlyRole(BURNER_ROLE) {
        ERC20BurnableUpgradeable.burn(amount);
    }

    function burnFrom(address account, uint256 amount) override public onlyRole(BURNER_ROLE) {
        ERC20BurnableUpgradeable.burnFrom(account, amount);
    }

    function blocklist(address account) public onlyRole(BLOCKLISTER_ROLE) {
        _blocklist(account);
    }

    function unblocklist(address account) public onlyRole(BLOCKLISTER_ROLE) {
        _unblocklist(account);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE)
    {
    }

    // -----------------------------------------------------------------------

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        whenNotBlocklisted(from)
        whenNotBlocklisted(to)
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 tax = calculateTax(msg.sender, recipient, amount);
        if (tax == 0) {
            super.transfer(recipient, amount);
        } else {
            uint256 leftAmount = amount - tax;
            super.transfer(treasury, tax);
            super.transfer(recipient, leftAmount);    
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 tax = calculateTax(sender, recipient, amount);
        if (tax == 0) {
            super.transferFrom(sender, recipient, amount);
        } else {
            uint256 leftAmount = amount - tax;
            super.transferFrom(sender, treasury, tax);
            super.transferFrom(sender, recipient, leftAmount);    
        }
        return true;
    }

    function calculateTax(address sender, address recipient, uint256 amount) public view virtual returns (uint256) {
        if (taxFee == 0) {
            return 0;
        } else if (hasRole(TAX_FREE_ROLE, msg.sender) || hasRole(TAX_FREE_ROLE, sender)) {
            return 0;
        } else if (hasRole(TAX_FREE_ROLE, recipient)) {
            return 0;
        } else {
            return (amount * uint256(taxFee)) / 10000;
        }
    }
}