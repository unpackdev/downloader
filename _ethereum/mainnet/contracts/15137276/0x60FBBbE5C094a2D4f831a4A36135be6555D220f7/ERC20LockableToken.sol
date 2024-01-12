// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "./Initializable.sol";
import "./AccessControl.sol";
import "./ERC165Storage.sol";
import "./Pausable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";

import "./ERC20RoleBasedLockingExtension.sol";

contract ERC20LockableToken is
    Initializable,
    ERC165Storage,
    AccessControl,
    ERC20,
    ERC20Burnable,
    Pausable,
    ERC20RoleBasedLockingExtension
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _name;
    string private _symbol;

    struct Config {
        string name;
        string symbol;
    }

    constructor(Config memory config) ERC20(config.name, config.symbol) {
        initialize(config, msg.sender);
    }

    function initialize(Config memory config, address deployer)
        public
        initializer
    {
        _name = config.name;
        _symbol = config.symbol;

        _grantRole(DEFAULT_ADMIN_ROLE, deployer);
        _grantRole(PAUSER_ROLE, deployer);
        _grantRole(MINTER_ROLE, deployer);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /* ADMIN */

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, AccessControl, ERC20RoleBasedLockingExtension)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override(ERC20, ERC20RoleBasedLockingExtension)
        whenNotPaused
    {
        ERC20RoleBasedLockingExtension._beforeTokenTransfer(from, to, amount);
    }
}
