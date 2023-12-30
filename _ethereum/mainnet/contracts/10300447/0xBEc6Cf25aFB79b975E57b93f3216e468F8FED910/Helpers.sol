pragma solidity ^0.6.10;

contract OnlyDeployer {
    address deployer;

    constructor () public {
        deployer = msg.sender;
    }

    modifier onlyDeployer () {
        require(msg.sender == deployer, "Method is preserved for the deployer");
        _;
    }
}

contract OnlyOnce {
    mapping (string => bool) onlyOnceData;

    modifier onlyOnce (string memory id) {
        require(!onlyOnceData[id], "Can only be executed once");
        _;
        onlyOnceData[id] = true;
    }
}