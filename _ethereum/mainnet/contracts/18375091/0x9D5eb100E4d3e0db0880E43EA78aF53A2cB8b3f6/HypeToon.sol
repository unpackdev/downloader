// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract HypeToon is ERC20, ERC20Permit, ERC20Votes {
	uint256 public constant TOTAL_SUPPLY_LIMIT = 2_000_000_000 * 1e18; // WEI
	address public constant GENESIS_VAULT_ADDRESS = 0x11FFc5bA95377eA1aFb7a8f62Ee394d91371Bd63; // Safe Multi-Sig Vault
	//address public constant GENESIS_VAULT_ADDRESS = 0x07fA2a8fF5eF3825430987E25b34541b0156e017; // Testnet wallet

	//---------------------------------------------------------------
	// Events
	//---------------------------------------------------------------
	event Mint(address indexed to, uint256 amount);
	
	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor() ERC20("Hypetoon", "HYPE") ERC20Permit("Hypetoon") {
		mint(GENESIS_VAULT_ADDRESS, TOTAL_SUPPLY_LIMIT);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function mint(address _to, uint256 _amount) private
	{
		require(totalSupply()+_amount <= TOTAL_SUPPLY_LIMIT, "mint: limit exceed");
		
		super._mint(_to, _amount);
		
		emit Mint(_to, _amount);
	}

	function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes)	{
		super._afterTokenTransfer(from, to, amount);
	}

	function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
		super._mint(to, amount);
	}

	function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
		super._burn(account, amount);
	}
}
