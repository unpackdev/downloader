// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IX2TimeDistributor.sol";

contract X2TimeDistributor is IX2TimeDistributor {
    using SafeMath for uint256;

    uint256 public constant DISTRIBUTION_INTERVAL = 1 hours;

    address public gov;

    mapping (address => uint256) public override ethPerInterval;
    mapping (address => uint256) public override lastDistributionTime;

    event Distribute(address receiver, uint256 amount);
    event DistributionChange(address receiver, uint256 amount);

    constructor() public {
        gov = msg.sender;
    }

    receive() external payable {}

    function setDistribution(address[] calldata _receivers, uint256[] calldata _amounts) external {
        require(msg.sender == gov, "X2TimeDistributor: forbidden");

        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];

            if (lastDistributionTime[receiver] != 0) {
                uint256 currentTime = block.timestamp;
                uint256 timeDiff = currentTime.sub(lastDistributionTime[receiver]);
                uint256 intervals = timeDiff.div(DISTRIBUTION_INTERVAL);
                require(intervals == 0, "X2TimeDistributor: pending distribution");
            }

            uint256 amount = _amounts[i];
            ethPerInterval[receiver] = amount;
            lastDistributionTime[receiver] = block.timestamp;
            emit DistributionChange(receiver, amount);
        }
    }

    function distribute() external returns (uint256) {
        address receiver = msg.sender;
        uint256 intervals = getIntervals(receiver);

        if (intervals == 0) { return 0; }

        uint256 amount = getDistributionAmount(receiver);
        lastDistributionTime[msg.sender] = block.timestamp;

        if (amount == 0) { return 0; }

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "X2TimeDistributor: transfer failed");

        emit Distribute(msg.sender, amount);
        return amount;
    }

    function getDistributionAmount(address receiver) public override view returns (uint256) {
        uint256 _ethPerInterval = ethPerInterval[receiver];
        if (_ethPerInterval == 0) { return 0; }

        uint256 intervals = getIntervals(receiver);
        uint256 amount = _ethPerInterval.mul(intervals);

        if (address(this).balance < amount) { return 0; }

        return amount;
    }

    function getIntervals(address receiver) public view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastDistributionTime[receiver]);
        return timeDiff.div(DISTRIBUTION_INTERVAL);
    }
}
