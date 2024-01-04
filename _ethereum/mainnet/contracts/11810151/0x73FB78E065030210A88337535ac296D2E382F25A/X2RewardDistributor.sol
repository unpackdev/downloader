// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IX2RewardDistributor.sol";

contract X2RewardDistributor is IX2RewardDistributor {
    using SafeMath for uint256;

    uint256 public constant DISTRIBUTION_INTERVAL = 1 hours;
    address public gov;

    mapping (address => address) public rewardTokens;
    mapping (address => uint256) public override tokensPerInterval;
    mapping (address => uint256) public override lastDistributionTime;

    event Distribute(address receiver, uint256 amount);
    event DistributionChange(address receiver, uint256 amount, address rewardToken);

    constructor() public {
        gov = msg.sender;
    }

    receive() external payable {}

    function setDistribution(address[] calldata _receivers, uint256[] calldata _amounts, address[] calldata _rewardTokens) external {
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
            address rewardToken = _rewardTokens[i];
            tokensPerInterval[receiver] = amount;
            rewardTokens[receiver] = rewardToken;
            lastDistributionTime[receiver] = block.timestamp;
            emit DistributionChange(receiver, amount, rewardToken);
        }
    }

    function distribute() external returns (uint256) {
        address receiver = msg.sender;
        uint256 intervals = getIntervals(receiver);

        if (intervals == 0) { return 0; }

        uint256 amount = getDistributionAmount(receiver);
        lastDistributionTime[msg.sender] = block.timestamp;

        if (amount == 0) { return 0; }

        IERC20(rewardTokens[receiver]).transfer(msg.sender, amount);

        emit Distribute(msg.sender, amount);
        return amount;
    }

    function getDistributionAmount(address _receiver) public override view returns (uint256) {
        uint256 _tokensPerInterval = tokensPerInterval[_receiver];
        if (_tokensPerInterval == 0) { return 0; }

        uint256 intervals = getIntervals(_receiver);
        uint256 amount = _tokensPerInterval.mul(intervals);

        if (IERC20(rewardTokens[_receiver]).balanceOf(address(this)) < amount) { return 0; }

        return amount;
    }

    function getIntervals(address _receiver) public view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastDistributionTime[_receiver]);
        return timeDiff.div(DISTRIBUTION_INTERVAL);
    }
}
