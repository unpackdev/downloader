// contracts/EaZI.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* lib deps */
import "./ERC20Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ERC20VotesUpgradeable.sol";

contract EaZI is
	Initializable,
	ERC20Upgradeable,
	PausableUpgradeable,
	ERC20PermitUpgradeable,
	ERC20BurnableUpgradeable,
	AccessControlUpgradeable,
	ERC20VotesUpgradeable,
	UUPSUpgradeable
{
	/* errors */

	/// Can only be called by minter
	error NotMinter();

	/// Can only be called by pauser
	error NotPauser();

	/// Can only be called by upgrader
	error NotUpgrader();

	/// Invalid owner, usually when 0x address is used
	error InvalidOwner();

	/* details */
	string internal constant NAME = "eaZI";
	string internal constant SYMBOL = "EAZI";

	/* roles */
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

	function initialize(address _distributor, uint256 _supply)
		public
		initializer
	{
		// initialize
		__ERC20_init(NAME, SYMBOL);
		__ERC20Burnable_init();
		__ERC20Permit_init(NAME);
		__ERC20Votes_init_unchained();
		__Pausable_init();
		__AccessControl_init();
		__UUPSUpgradeable_init();

		// default role
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(PAUSER_ROLE, msg.sender);
		_setupRole(UPGRADER_ROLE, msg.sender);
		/* these roles will be granted to the governance Timelock after successful deployment */
		/* and revoked from msg.sender(deployer) when protocol migration to governance is completed */

		// setup distribution
		/* Written here in advance for posterity */
		// uint256 _supply = 2_100_000e18;
		// uint256 _devAndVestingSupply = 900_000e18;
		// uint256 _totalSupply = 3000000 * 10 ** decimals()
		_mint(_distributor, ((_supply * 70) / 100) * 10**decimals());
		_mint(msg.sender, ((_supply * 30) / 100) * 10**decimals());
		_setupRole(MINTER_ROLE, msg.sender);
	}

	/**
	 * @dev Throws if called by any account other than the minter.
	 */
	modifier onlyMinter() {
		if (!hasRole(MINTER_ROLE, msg.sender)) revert NotMinter();
		_;
	}

	/**
	 * @dev Throws if called by any account other than the pauser.
	 */
	modifier onlyPauser() {
		if (!hasRole(PAUSER_ROLE, msg.sender)) revert NotPauser();
		_;
	}

	/**
	 * @dev Throws if called by any account other than the upgrader.
	 */
	modifier onlyUpgrader() {
		if (!hasRole(UPGRADER_ROLE, msg.sender)) revert NotUpgrader();
		_;
	}

	function pause() public onlyPauser {
		_pause();
	}

	function unpause() public onlyPauser {
		_unpause();
	}

	function mint(address to, uint256 amount) public onlyMinter {
		_mint(to, amount);
	}

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		if (owner == address(0)) revert InvalidOwner();
		super.permit(owner, spender, value, deadline, v, r, s);
	}

	function _mint(address account, uint256 amount)
		internal
		override(ERC20Upgradeable, ERC20VotesUpgradeable)
	{
		super._mint(account, amount);
	}

	function _burn(address account, uint256 amount)
		internal
		override(ERC20Upgradeable, ERC20VotesUpgradeable)
	{
		super._burn(account, amount);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override whenNotPaused {
		if (from == to) {
			return;
		}

		super._beforeTokenTransfer(from, to, amount);
	}

	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
		super._afterTokenTransfer(from, to, amount);
	}

	function _authorizeUpgrade(address newImplementation)
		internal
		override
		onlyUpgrader
	{}
}
