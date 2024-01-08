pragma solidity 0.8.1;

import "./IPieRegistry.sol";
import "./Ownable.sol";

contract SmartPoolRegistry is IPieRegistry, Ownable {
    mapping(address => bool) public override inRegistry;
    address[] public override entries;

    function addSmartPool(address _smartPool) external override onlyOwner {
        require(!inRegistry[_smartPool], "SmartPoolRegistry.addSmartPool: POOL_ALREADY_IN_REGISTRY");
        entries.push(_smartPool);
        inRegistry[_smartPool] = true;
    }

    function removeSmartPool(uint256 _index) public override onlyOwner {
        address registryAddress = entries[_index];

        inRegistry[registryAddress] = false;

        // Move last to index location
        entries[_index] = entries[entries.length - 1];
        // Pop last one off
        entries.pop();
    }
    
    function removeSmartPoolByAddress(address _address) external onlyOwner {
        // Search for pool and remove it if found. Otherwise do nothing
        for(uint256 i = 0; i < entries.length; i ++) {
            if(_address == entries[i]) {
                removeSmartPool(i);
                break;
            }
        }   
    }
}