pragma solidity ^0.8.0;

import "./Ownable.sol";

contract SeekerRenumerations is Ownable {
    constructor() {}

    function batchTransfer(
        address[] memory _receivers,
        uint256[] memory _amounts
    ) payable external onlyOwner {
        require(
            _receivers.length == _amounts.length,
            "receivers and amounts must have equal length"
        );

        for (uint256 i = 0; i < _receivers.length; i++) {
            payable(_receivers[i]).transfer(_amounts[i]);
        }
    }

    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
    }
}
