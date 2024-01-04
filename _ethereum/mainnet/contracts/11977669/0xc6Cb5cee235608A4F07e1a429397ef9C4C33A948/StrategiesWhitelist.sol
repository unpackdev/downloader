pragma solidity 0.6.6;

import "./Ownable.sol";

contract StrategiesWhitelist is Ownable {
    mapping(address => uint8) public whitelistedAllocationStrategies;

    event AllocationStrategyWhitelisted(address indexed submittedBy, address indexed allocationStrategy);
    event AllocationStrategyRemovedFromWhitelist(address indexed submittedBy, address indexed allocationStrategy);

    constructor() public {
        _setOwner(msg.sender);
    }

    function isWhitelisted(address _allocationStrategy) external view returns (uint8 answer) {
        return whitelistedAllocationStrategies[_allocationStrategy];
    }

    function addToWhitelist(address _allocationStrategy) external onlyOwner {
        whitelistedAllocationStrategies[_allocationStrategy] = 1;
        emit AllocationStrategyWhitelisted(msg.sender, _allocationStrategy);
    }

    function removeFromWhitelist(address _allocationStrategy) external onlyOwner {
        whitelistedAllocationStrategies[_allocationStrategy] = 0;
        emit AllocationStrategyRemovedFromWhitelist(msg.sender, _allocationStrategy);
    }
}