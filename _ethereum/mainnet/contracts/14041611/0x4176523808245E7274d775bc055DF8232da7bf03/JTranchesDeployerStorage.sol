// SPDX-License-Identifier: MIT
/**
 * Created on 2021-02-11
 * @summary: Jibrel Compound Tranche Deployer Storage
 * @author: Jibrel Team
 */
pragma solidity 0.8.8;


contract JTranchesDeployerStorage {
/* WARNING: NEVER RE-ORDER VARIABLES! Always double-check that new variables are added APPEND-ONLY. Re-ordering variables can permanently BREAK the deployed proxy contract.*/

    address public jAaveAddress;
    address public jAdminToolsAddress;
}