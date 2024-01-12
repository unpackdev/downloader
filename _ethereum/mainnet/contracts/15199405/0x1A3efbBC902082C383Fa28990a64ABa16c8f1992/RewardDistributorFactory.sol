// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./Clones.sol";
import "./IERC20.sol";
import "./IRewardDistributor.sol";

contract RewardDistributorFactory {
    using Clones for address;

    event NewImpl(address pairLogic, uint256 timestamp);
    event NewRewardDistributor(address distributor, uint256 timestamp);

    /// @dev owner
    address public owner;

    /// @dev implementation
    address public distributorImplementation;

    /// @dev list of all distributors
    address[] public rewardDistributors;

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(address _owner, address _distributorImplementation) {
        owner = _owner;
        distributorImplementation = _distributorImplementation;
    }

    function setDistributorImplementation(address _impl) external onlyOwner {
        require(_impl != address(0), "INVALID_IMPL");
        distributorImplementation = _impl;
        emit NewImpl(_impl, block.timestamp);
    }

    function createRewardDistributor(
        string calldata _name,
        IERC20 _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian
    ) external {
        bytes32 salt =
            keccak256(
                abi.encode(
                    _rewardToken,
                    _amountDistributePerSecond,
                    _startTimestamp,
                    _guardian,
                    rewardDistributors.length
                )
            );

        IRewardDistributor newDistributor =
            IRewardDistributor(distributorImplementation.cloneDeterministic(salt));

        // initialize
        newDistributor.initialize(
            _name,
            _rewardToken,
            _amountDistributePerSecond,
            _startTimestamp,
            _endTimestamp,
            _guardian
        );

        rewardDistributors.push(address(newDistributor));

        emit NewRewardDistributor(address(newDistributor), block.timestamp);
    }
}
