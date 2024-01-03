pragma solidity 0.7.0;

contract Custody {

    event MessageReceived(string msg, address sender);

    function emitProof(string calldata _msg)
        external {
            emit MessageReceived(_msg, msg.sender);
        }

}