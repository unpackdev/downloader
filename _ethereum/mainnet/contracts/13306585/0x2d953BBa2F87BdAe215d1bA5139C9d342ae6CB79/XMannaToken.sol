// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

contract XMannaToken is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    uint256 private _cap;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    function initialize() public initializer {
        __ERC20_init("XMANNA TOKEN", "XMAN");
        __Pausable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(PREDICATE_ROLE, msg.sender);
        _setupRole(WHITELIST_ROLE, msg.sender);
        _cap = 7777777777 * 10**decimals();
    }

    function _mintCapped(address account, uint256 amount) internal virtual {
        require(totalSupply() + amount <= cap(), "cap exceeded");
        _mint(account, amount);
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address user, uint256 amount)
        public
        onlyRole(PREDICATE_ROLE)
    {
        _mintCapped(user, amount);
    }

    // Matic specific
    function deposit(address user, bytes calldata depositData)
        external
        onlyRole(DEPOSITOR_ROLE)
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _mintCapped(user, amount);
    }

    // Matic specific
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!hasRole(WHITELIST_ROLE, _msgSender())) {
            require(!paused(), "can not transfer while locked");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}
