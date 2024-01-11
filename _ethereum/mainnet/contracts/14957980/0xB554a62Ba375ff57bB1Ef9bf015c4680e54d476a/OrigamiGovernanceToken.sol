// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./ERC20CappedUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

/// @custom:security-contact contract-security@joinorigami.com
contract OrigamiGovernanceToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20CappedUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool private _burnEnabled;
    bool private _transferEnabled;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        string memory _name,
        string memory _symbol,
        uint256 _supplyCap
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC20Capped_init(_supplyCap);

        // Temporarily grant admin to caller so it can grant the following roles.
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // grant all roles to the admin
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);

        // revoke admin grant for caller
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _burnEnabled = false;
        _transferEnabled = false;
    }

    function burnable() public view returns (bool) {
        return _burnEnabled;
    }

    function enableBurn() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotBurnable {
        _burnEnabled = true;
    }

    function disableBurn() public onlyRole(DEFAULT_ADMIN_ROLE) whenBurnable {
        _burnEnabled = false;
    }

    function transferrable() public view returns (bool) {
        return _transferEnabled;
    }

    function enableTransfer() public onlyRole(DEFAULT_ADMIN_ROLE) whenNontransferrable {
        _transferEnabled = true;
    }

    function disableTransfer() public onlyRole(DEFAULT_ADMIN_ROLE) whenTransferrable {
        _transferEnabled = false;
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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override whenTransferrable returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount) public virtual override whenTransferrable returns (bool) {
        return super.transfer(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Upgradeable) whenNotPaused whenBurnable {
        super._burn(account, amount);
    }

    modifier whenNotBurnable() {
        require(!burnable(), "Burnable: burning is enabled");
        _;
    }

    modifier whenBurnable() {
        require(burnable(), "Burnable: burning is disabled");
        _;
    }

    modifier whenNontransferrable() {
        require(!transferrable(), "Transferrable: transfers are enabled");
        _;
    }

    modifier whenTransferrable() {
        require(transferrable(), "Transferrable: transfers are disabled");
        _;
    }
}
