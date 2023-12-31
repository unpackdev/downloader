// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC20Metadata.sol";

import "./SmartChefInitializable.sol";

contract SmartChefFactory is Ownable {
    event NewSmartChefContract(address indexed smartChef);

    constructor() {
        //
    }

    /*
     * @notice Deploy the pool
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerSecond: reward per second (in rewardToken)
     * @param _startTimestamp: start block timestamp
     * @param _endTimestamp: end block timestamp
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _numberSecondsForUserLimit: seconds available for user limit (after start block)
     * @param _pancakeProfile: Pancake Profile address
     * @param _pancakeProfileIsRequested: Pancake Profile is requested
     * @param _pancakeProfileThresholdPoints: Pancake Profile need threshold points
     * @param _admin: admin address with ownership
     * @return address of new smart chef contract
     */
    function deployPool(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _poolLimitPerUser,
        uint256 _numberSecondsForUserLimit,
        address _pancakeProfile,
        bool _pancakeProfileIsRequested,
        uint256 _pancakeProfileThresholdPoints,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardToken.totalSupply() >= 0);
        require(_stakedToken != _rewardToken, "Tokens must be be different");

        bytes memory bytecode = type(SmartChefInitializable).creationCode;
        // pass constructor argument
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode(_pancakeProfile, _pancakeProfileIsRequested, _pancakeProfileThresholdPoints)
        );
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startTimestamp));
        address smartChefAddress;

        assembly {
            smartChefAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        SmartChefInitializable(smartChefAddress).initialize(
            _stakedToken,
            _rewardToken,
            _rewardPerSecond,
            _startTimestamp,
            _endTimestamp,
            _poolLimitPerUser,
            _numberSecondsForUserLimit,
            _admin
        );

        emit NewSmartChefContract(smartChefAddress);
    }
}
