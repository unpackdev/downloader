pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract Timelock is Ownable {

    constructor() public {
        __Ownable_init();
    }

    function executeTransactions(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) public onlyOwner payable {
        for (uint i = 0; i < targets.length; i++) {
            executeTransaction(targets[i], values[i], signatures[i], calldatas[i]);
        }
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public onlyOwner payable returns (bytes memory) {
        bytes memory callData;
        require(bytes(signature).length > 0, "executeTransaction: Parameter signature can not be empty!");
        callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        return returnData;
    }
}
