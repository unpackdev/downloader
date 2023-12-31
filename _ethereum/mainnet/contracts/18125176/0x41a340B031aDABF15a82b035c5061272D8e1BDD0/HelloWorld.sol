pragma solidity 0.8.18;

contract HelloWorld {

    event Hello();
    error Unauthed(address expected, address actual);
    bool helloed;
    address allowed;

    constructor(address _allowed) {
        allowed = _allowed;
    }

    function helloWorld() public {
        if(msg.sender != allowed) {
            revert Unauthed(allowed, msg.sender);
        }
        helloed = true;
        emit Hello();
    }
}