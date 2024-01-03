// File: contracts/deposits/DfProfits.sol

pragma solidity ^0.5.16;

contract DfProfits {
    address public controller;

    constructor(address _controller) public {
        controller = _controller;
    }

    function cast(address payable _to, bytes memory _data) public payable {
        require(msg.sender == controller);

        (bool success, bytes memory returndata) = address(_to).call.value(
            msg.value
        )(_data);
        require(success, "low-level call failed");
    }
}