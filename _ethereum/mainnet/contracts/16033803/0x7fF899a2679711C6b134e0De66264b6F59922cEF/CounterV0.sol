// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Address.sol";

contract CounterV0 {
    using Address for address payable;

    address public immutable relayTransit;
    uint256 public counter;

    constructor(address _relayTransit) {
        relayTransit = _relayTransit;
    }

    event GetBalance(uint256 balance);
    event IncrementCounter(uint256 newCounterValue);

    function increment(uint256 _fee) external {
        payable(msg.sender).sendValue(_fee);

        counter++;

        emit IncrementCounter(counter);
    }

    function getBalance() external {
        emit GetBalance(address(this).balance);
    }
}
