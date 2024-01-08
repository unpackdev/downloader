// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;


import "./AccessControl.sol";
import "./Context.sol";
import "./ERC20Pausable.sol";
import "./ERC20Capped.sol";

contract XPX is Context, AccessControl, ERC20Capped, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 cap, address admin, address pauser, address minter) ERC20(name, symbol) ERC20Capped(cap) public {
        _setupDecimals(decimals);

        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        _setupRole(PAUSER_ROLE, pauser);
        _setupRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "XPX: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "XPX: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "XPX: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Capped, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
