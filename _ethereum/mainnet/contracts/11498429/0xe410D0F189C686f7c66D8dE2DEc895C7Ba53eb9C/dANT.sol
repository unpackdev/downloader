pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

contract dANT is ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(uint256 initialSupply)
        public
        ERC20("Digital Antares Dollar", "dANT")
        AccessControl()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), initialSupply * 10**18);
    }

    /**
     * @dev Set the DEFAULT_ADMIN_ROLE to `_newAdmin`.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function changeAdmin(address _newAdmin) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "changeAdmin: bad role"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Creates `_amount` new tokens for `_to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "mint: bad role");
        _mint(_to, _amount);
    }
}
