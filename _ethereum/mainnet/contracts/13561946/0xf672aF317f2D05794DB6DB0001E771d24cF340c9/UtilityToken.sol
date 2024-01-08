// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Pausable.sol";
import "./AccessControlEnumerable.sol";

/// @custom:security-contact astridfox@protonmail.com
contract UtilityToken is ERC20, Pausable, AccessControlEnumerable {
    
    event TokenSpent(address indexed spender, uint256 amount, uint256 indexed serviceId, bytes data);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EXTERNAL_SPENDER_ROLE = keccak256("EXTERNAL_SPENDER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        address admin,
        address pauser,
        address minter)
        ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(PAUSER_ROLE, pauser);
        _setupRole(MINTER_ROLE, minter);
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

     /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(
        uint256 amount,
        uint256 serviceId,
        bytes calldata data
    ) public virtual {
        _burn(msg.sender, amount);
        emit TokenSpent(msg.sender, amount, serviceId, data);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(
        address account,
        uint256 amount,
        uint256 serviceId,
        bytes calldata data
    ) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
        emit TokenSpent(account, amount, serviceId, data);
    }

        /**
     * @dev Destroys `amount` tokens from `account`.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - The sender must be granted the EXTERNAL_SPENDER_ROLE role.
     */
    function externalBurnFrom(
        address account,
        uint256 amount,
        uint256 serviceId,
        bytes calldata data
    ) external virtual onlyRole(EXTERNAL_SPENDER_ROLE) {
        _burn(account, amount);
        emit TokenSpent(account, amount, serviceId, data);
    }
}