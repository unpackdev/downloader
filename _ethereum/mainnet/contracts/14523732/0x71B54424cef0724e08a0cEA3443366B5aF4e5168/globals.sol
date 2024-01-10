// SPDX-License-Identifier: LGPL-3.0-or-later
/**
 * @title obscurityDAO
 * @email obscuirtyceo@gmail.com
 * @dev Nov 3, 2020
 * ERC-20 
 * obscurityDAO Copyright and Disclaimer Notice:
 */
pragma solidity ^0.8.7 <0.9.0;

import "./AccessControlUpgradeable.sol";
abstract contract globals is AccessControlUpgradeable{

    address payable ADMIN_ADDRESS;
    bytes32 PAUSER_ROLE; // can pause the network
    bytes32 MINTER_ROLE; // Allows minting of new tokens
    bytes32 UPGRADER_ROLE; // see admin
    bytes32 ADMIN_ROLE; // COMPANY WALLET ROLE USED AS ADDITIONAL LAYER OFF PROTECTION initiats upgrades, founder wallet changes
    bytes32 FOUNDER_ROLE; // USED AS ADDITIONAL LAYER OFF PROTECTION (WE CANT LOSE ACCESS TO THESE WALLETS) approves new charites
   
    function globals_init() internal onlyInitializing{
        __AccessControl_init();
                           
        ADMIN_ADDRESS = payable(address(0x00d807590d776bA30Db945C775aeED85ABFa7020));
        PAUSER_ROLE = keccak256("P_R"); // can pause the network
        MINTER_ROLE = keccak256("M_R"); // Allows minting of new tokens
        UPGRADER_ROLE = keccak256("U_R"); // see admin
        ADMIN_ROLE = keccak256("A_R"); // COMPANY WALLET ROLE USED AS ADDITIONAL LAYER OFF PROTECTION initiats upgrades, founder wallet changes
        FOUNDER_ROLE = keccak256("F_R"); // USED AS ADDITIONAL LAYER OFF PROTECTION (WE CANT LOSE ACCESS TO THESE WALLETS) approves new charites    
    }

    modifier contains (string memory what, string memory where) {
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);

        uint256 found = 0;

        for (uint i = 0; i < whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = 1;
                break;
            }
        }
    require (found == 1);
    _;
    }
}

