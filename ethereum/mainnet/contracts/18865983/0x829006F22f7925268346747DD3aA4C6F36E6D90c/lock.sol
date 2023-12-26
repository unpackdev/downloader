// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract lock {
    address public receiver;
    uint256 public duration;

    constructor(address _receiver, uint256 _duration) {
        receiver = _receiver;
        duration = _duration;
    }

    fallback() external payable {}

    receive() external payable {}

    function withdraw() external {
        require(duration < block.timestamp, "Wait");
        payable(receiver).transfer(address(this).balance);
    }
}