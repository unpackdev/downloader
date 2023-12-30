pragma solidity 0.6.2;

contract MultiSignTest {
    address addr;

    constructor(
    ) public {
        addr = msg.sender;
    }

    function updateAddr(address _newAddr) public {
        require(msg.sender == addr, "deny!");
        addr = _newAddr;
    }
}
