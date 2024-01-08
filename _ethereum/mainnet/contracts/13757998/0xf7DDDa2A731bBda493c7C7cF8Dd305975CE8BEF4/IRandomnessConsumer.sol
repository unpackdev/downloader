// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomnessConsumer {
    function setRandomnessResult(bytes32 requestId, uint256 randomness)
        external;

    function process(uint256 amount) external;

    function processNext() external returns (bool);

    function setRandomnessProvider(address _randomnessProvider) external;

    function updateRandomnessFee(uint256 _fee) external;

    function rescueLINK(uint256 amount) external;
}
