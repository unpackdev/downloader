pragma solidity ^0.5.0;

contract OperatorRole {
    
    mapping (address => bool) private bearer;
    
    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);
    
    modifier onlyOperator() {
        require(isOperator(msg.sender), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return bearer[account];
    }

    function addOperator() public {
        bearer[msg.sender] = true;
        emit OperatorAdded(msg.sender);
    }

    function renounceOperator() public {
        bearer[msg.sender] = false;
        emit OperatorRemoved(msg.sender);
    }
}