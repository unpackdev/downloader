pragma solidity ^0.5.0;

contract Originstamp {

    address public owner;

    event onSubmission(bytes32 indexed docHash);

    modifier onlyOwner() {
        require(msg.sender == owner,"Sender not authorized");
        _;
    }

    constructor () public {
    	owner = msg.sender;
    }

    function publishHash(bytes32  docHash) external onlyOwner() {
       emit onSubmission(docHash);
    }
}