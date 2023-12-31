// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./CCIPReceiver.sol";
import "./Client.sol";
import "./Ownable.sol";
import "./Membership.sol";

/**
@title Receiver
@dev A contract designed to execute function calls on another contract.
*/

contract Receiver is CCIPReceiver, Ownable{
    address public mycontract;

    //Emitted when a transaction associated with a specific message ID is successfully completed.
    event TransactionCompleted(bytes32 messageId);

    /**
     * @dev Initializes the contract with the router address and contract.
     * @param router The address of the router contract.
     * @param _mycontract The contract address to which it routes function calls.
     */
    constructor(address router, address _mycontract) CCIPReceiver(router) {
        mycontract = _mycontract;
    }

    /**
     * @dev  handle a received message
     * @param message The message to be processed.
     */
    function _ccipReceive( Client.Any2EVMMessage memory message
    ) internal override {
        Membership token = Membership(mycontract);
        (bool success, ) = address(token).call(message.data);
        require(success, "Transaction failed");

        emit TransactionCompleted(message.messageId);
    }

}