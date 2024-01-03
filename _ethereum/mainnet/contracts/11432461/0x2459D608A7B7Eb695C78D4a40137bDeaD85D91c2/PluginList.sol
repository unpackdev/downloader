pragma solidity ^0.4.25;

/**
 * 
 * "Stash" (v0.2 beta)
 * A simple tool for a personal smart contract wallet to help protect your assets.
 * 
 * For more info checkout: https://squirrel.finance
 * 
 */

contract PluginList {
    
    address governance = msg.sender; // For beta until upgraded
    mapping(address => bool) approvedPlugins;
    
    function upgradeGovernance(address newGovernance) external {
        require(msg.sender == governance);
        governance = newGovernance;
    }
    
    function updatePlugin(address plugin, bool hasAccess) external {
        require(msg.sender == governance);
        approvedPlugins[plugin] = hasAccess;
    }
    
    function isValid(address candidate) external view returns (bool) {
        return approvedPlugins[candidate];
    }
    
}