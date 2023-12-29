// SPDX-License-Identifier: Not Licensed
pragma solidity 0.8.9;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

import "./ERC20SupplyControlledToken.sol";
import "./ERC20BatchTransferrableToken.sol";

/**
 * ERC20 token with cap, role based access control, burning, and batch transfer functionalities.
 */
contract WFCAToken is
    Context,
    ERC20Capped,
    AccessControl,
    ERC20Burnable,
    ERC20SupplyControlledToken,
    ERC20BatchTransferrableToken
{
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(address _initialSupplyRecipient)
        ERC20SupplyControlledToken(
            "World Friendship Cash",
            "WFCA",
            18,
            1_000_000_000 * (10**18),
            1_000_000_000 * (10**18),
            _initialSupplyRecipient
        )
    {
        address _initialAdmin = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _grantRole(BURNER_ROLE, _initialAdmin);
    }

    function decimals()
        public
        view
        virtual
        override(ERC20, ERC20SupplyControlledToken)
        returns (uint8)
    {
        return ERC20SupplyControlledToken.decimals();
    }

    /**
     * Override to restrict access.
     */
    function burn(uint256 amount) public override onlyRole(BURNER_ROLE) {
        super.burn(amount);
    }

    /**
     * Override to restrict access.
     */
    function burnFrom(address account, uint256 amount)
        public
        override
        onlyRole(BURNER_ROLE)
    {
        super.burnFrom(account, amount);
    }

    // The following functions are overrides required by Solidity.

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        ERC20Capped._mint(account, amount);
    }
}
