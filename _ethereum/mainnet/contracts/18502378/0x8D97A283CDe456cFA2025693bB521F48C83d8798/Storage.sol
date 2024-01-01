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




contract Storage is AccessControl, UniswapV3Integration{



    address vidya = 0x3D3D35bb9bEC23b06Ca00fe472b50E7A4c692C30;
    address vault = 0xe4684AFE69bA238E3de17bbd0B1a64Ce7077da42;


    bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");

    constructor(){
        _setRoleAdmin(CALLER_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CALLER_ROLE, msg.sender);
    }

    function setVault(address _newVault) external onlyRole(DEFAULT_ADMIN_ROLE){
        vault = _newVault;
    }

    function sendEthToVaultOwner() external onlyRole(CALLER_ROLE){
        uint256 amount = address(this).balance;
        _buyTokenETH(vidya, amount, vault);
    }

    function sendEthToVault() external payable{
        uint256 amount = msg.value;
        _buyTokenETH(vidya, amount, vault);
    }

    receive() external payable {}

}

