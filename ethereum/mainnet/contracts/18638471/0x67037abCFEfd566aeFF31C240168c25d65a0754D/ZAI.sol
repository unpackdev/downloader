// SPDX-License-Identifier: Not-License
pragma solidity ^0.8.9;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

import "./ERC20SupplyControlledToken.sol";
import "./ERC20MintableToken.sol";
import "./ERC20BatchTransferableToken.sol";
import "./ERC20VotesToken.sol";

contract ZAI is
    Context,
    ERC20Capped,
    AccessControl,
    ERC20Burnable,
    ERC20MintableToken,
    ERC20BatchTransferableToken,
    ERC20Permit,
    ERC20VotesToken,
    ERC20SupplyControlledToken
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        address _initialSupplyRecipient
    )
        ERC20SupplyControlledToken(
            "ZAIHO",
            "ZAI",
            18,
            1000000000000000000000000000,
            0,
            _initialSupplyRecipient
        )
        ERC20Permit("ZAIHO")
    {
        address _initialAdmin = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _grantRole(MINTER_ROLE, _initialAdmin);
        _grantRole(BURNER_ROLE, _initialAdmin);
    }

    function decimals()
        public
        view
        virtual
        override(ERC20, ERC20SupplyControlledToken)
        returns (uint8)
    {
        return super.decimals();
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Capped, ERC20VotesToken) onlyRole(MINTER_ROLE) {
        super._mint(account, amount);
    }

    function _finishMinting() internal override onlyRole(MINTER_ROLE) {
        super._finishMinting();
    }

    function burn(uint256 amount) public override onlyRole(BURNER_ROLE) {
        super.burn(amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyRole(BURNER_ROLE) {
        super.burnFrom(account, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20VotesToken)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20VotesToken)
    {
        super._burn(account, amount);
    }
}
