// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Clones.sol";
import "./Ownable.sol";
import "./IVaultManager.sol";
import "./IMEVVault.sol";

/*
    Reference Materials
    https://docs.openzeppelin.com/contracts/4.x/api/proxy - openzeppelin clones

*/

contract VaultManager is Ownable, IVaultManager{

    address public MEVVaultImplementation;
    uint256 public JinoroFee;

    //This is the inverse of the information we can obtain using getAccountVault
    //The deterministic prediction can get us from user to vault, but it is also useful to store the inverse
    mapping(address => address) public vaultToAccount;

    function accountToVault(address account) public view implementationSet returns(address){
        bytes32 salt = keccak256(abi.encodePacked(account));
        return Clones.predictDeterministicAddress(MEVVaultImplementation, salt);
    }

    //If vault has been cloned into, code size will be greater than 0
    function checkIfVaultBuilt(address account) public view returns (bool) {
        uint32 size;
        address vaultAddress = accountToVault(account);
        assembly {
            size := extcodesize(vaultAddress)
        }
        return (size > 0);
    }

    //A tiny bit more expensive than calling extract directly from the vault
    //But also clones into vault address if it has not already been cloned
    function collectVaultRewards(address account) public {
        if(!checkIfVaultBuilt(account)) buildVault(account);
        IMEVVault(accountToVault(account)).extractMEV();
    }

    function collectVaultRewards() external {
        collectVaultRewards(msg.sender);
    }

    function collectVaultRewardsBulk(address[] calldata accounts) external {
        for(uint256 i = 0; i<accounts.length; i++){
            collectVaultRewards(accounts[i]);
        }
    }

    function buildVault(address account) public implementationSet returns(address) {
        bytes32 salt = keccak256(abi.encodePacked(account));

        //This will revert if the vault is already built, so no need to check that case
        address vault = Clones.cloneDeterministic(MEVVaultImplementation, salt);

        //Set starting fee inside vault
        IMEVVault(vault).updateFee();

        //populate inverse mapping
        vaultToAccount[vault] = account;
        return vault;
    }

    //This should be done by the deployment script
    function setMEVVaultImplementation(address impl) external onlyOwner {
        require(MEVVaultImplementation == address(0x0), "VAULTMANAGER: Impl Already Set");
        MEVVaultImplementation = impl;
    }

    function setJinoroFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1e27, "VAULTMANAGER: Fee Above 100%");
        JinoroFee = newFee;
    }

    function takeOperationFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    modifier implementationSet() {
        require(MEVVaultImplementation != address(0x0), "VAULTMANAGER: Impl not set"); //Keep message under 32 chars
        _;
    }

    //Allow contract to receive eth
    receive() external payable{
    }

}
