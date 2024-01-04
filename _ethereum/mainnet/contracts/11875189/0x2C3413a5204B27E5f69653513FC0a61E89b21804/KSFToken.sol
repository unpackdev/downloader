// contracts/KSFToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


/*
   "KSF", "KESEF.FINANCE", the Kesef.finance token contract

   Properties used from OpenZeppelin:
     ERC20PresetMinterPauserUpgradeable.sol -- preset for mintable, pausable, burnable ERC20 token
     ERC20PermitUpgradeable.sol -- ported from drafts (test added) to implement permit()
*/
contract KSFToken is ERC20PresetMinterPauserUpgradeable, ERC20PermitUpgradeable {
    using SafeERC20 for IERC20;

    // initializer is defined within preset
    function initialize(string memory name, string memory symbol) public override initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
        __ERC20Permit_init(name);
    }

    function uniqueIdentifier() public pure returns(string memory) {
        return "KesefToken";
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20PresetMinterPauserUpgradeable, ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    // all contracts that do not hold funds have this emergency function if someone occasionally
	// transfers ERC20 tokens directly to this contract
	// callable only by owner
	function emergencyTransfer(address _token, address _destination, uint256 _amount) public {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin only");
		IERC20(_token).safeTransfer(_destination, _amount);
	}
}
