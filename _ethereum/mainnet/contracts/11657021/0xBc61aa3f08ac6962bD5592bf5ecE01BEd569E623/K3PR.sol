pragma solidity 0.6.12;

contract K3PR {
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    function send(address payable _dst, uint256 _amt) public {
        require(msg.sender == owner);
        _dst.transfer(_amt);
    }
}