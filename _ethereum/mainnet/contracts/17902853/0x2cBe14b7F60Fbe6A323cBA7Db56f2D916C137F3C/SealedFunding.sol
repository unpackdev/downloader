pragma solidity ^0.8.7;

interface IExchange {
    function deposit(address receiver) external payable;
}

contract SealedFunding {
    constructor(address _owner, address _exchange) {
        IExchange(_exchange).deposit{value: address(this).balance}(_owner);
        assembly {
            // Ensures the runtime bytecode is a single opcode: `INVALID`. This reduces contract
            // deploy costs & ensures that no one can accidentally send ETH to the contract once
            // deployed.
            mstore8(0, 0xfe)
            return(0, 1)
        }
    }
}
