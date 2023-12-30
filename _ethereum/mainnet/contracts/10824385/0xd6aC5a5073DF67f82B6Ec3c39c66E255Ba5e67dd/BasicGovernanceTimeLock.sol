pragma solidity ^0.5.0;

contract BasicGovernanceTimeLock {
    
    NUTS constant squirrel = NUTS(0x84294FC9710e1252d407d3D80A84bC39001bd4A8);
    uint256 public constant UPDATE_DELAY = 72 hours;
    address seeder = msg.sender;
    
    struct PendingGovernanceUpdate {
        address newGovernance;
        uint256 eta;
    }
    
    PendingGovernanceUpdate public pending;
    
    function beginGovernanceUpdate(address newGovernance) external {
        require(msg.sender == seeder);
        uint256 eta = now + UPDATE_DELAY;
        pending = PendingGovernanceUpdate(newGovernance, eta);
    }
    
    function triggerGovernanceUpdate() external {
        require(pending.eta > 0 && pending.eta < now);
        squirrel.updateGovernance(pending.newGovernance);
    }
    
}

contract NUTS {
    function updateGovernance(address newGovernance) external;
    function mint(uint256 amount, address recipient) external;
}