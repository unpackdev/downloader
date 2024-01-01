// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

/*
  _______                   ____  _____  
 |__   __|                 |___ \|  __ \ 
    | | ___  __ _ _ __ ___   __) | |  | |
    | |/ _ \/ _` | '_ ` _ \ |__ <| |  | |
    | |  __/ (_| | | | | | |___) | |__| |
    |_|\___|\__,_|_| |_| |_|____/|_____/ 

    https://team3d.io
    https://discord.gg/team3d
    ETH Storage

    @author Team3d.R&D
*/

import "./UniswapV3Integration.sol";
import "./IERC20.sol";
import "./AccessControl.sol";

contract Storage is AccessControl, UniswapV3Integration {
	address vidya = 0x3D3D35bb9bEC23b06Ca00fe472b50E7A4c692C30;
	address vault = 0xe4684AFE69bA238E3de17bbd0B1a64Ce7077da42;

	bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");

	constructor() {
		_setRoleAdmin(CALLER_ROLE, DEFAULT_ADMIN_ROLE);
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(CALLER_ROLE, msg.sender);
	}

	function setVault(address _newVault) external onlyRole(DEFAULT_ADMIN_ROLE) {
		vault = _newVault;
	}

	function sendEthToVaultOwner(uint256 amountOfEth, uint256 amountOut) external onlyRole(CALLER_ROLE) {
		require(amountOfEth <= address(this).balance, "Not enough eth in contract");
		_buyTokenETH(vidya, amountOfEth, amountOut, vault);
	}

	function sendEthToVault(uint256 amountOut) external payable{
		uint256 amount = msg.value;
		_buyTokenETH(vidya, amount,amountOut, vault);
	}
	
	// Rescue all the ERC20's that get sent here and if it's VIDYA, send it to Vault 
	function rescueERC20(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
		IERC20 tkn = IERC20(_token);
		uint256 balance = tkn.balanceOf(address(this));

		if (_token != vidya) {
			require(tkn.transfer(msg.sender, balance), "Token transfer failed!");
		} else {
			require(tkn.transfer(vault, balance), "Token transfer to vault failed!");
		}
	}

	receive() external payable {}
}