// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC20Metadata.sol";

import "./Wrapper.sol";

contract WrapperFactory is Ownable {
    event NewWrapperContract(address indexed wrapper);

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
     * @param _admin: admin address with ownership
     * @return address of new smart chef contract
     */
    function deployPool(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardToken.totalSupply() >= 0);
        require(_stakedToken != _rewardToken, "Tokens must be different");

        bytes memory bytecode = type(Wrapper).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startTimestamp));
        address wrapperAddress;

        assembly {
            wrapperAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        Wrapper(wrapperAddress).initialize(
            _stakedToken,
            _rewardToken,
            _rewardPerSecond,
            _startTimestamp,
            _endTimestamp,
            _admin
        );

        emit NewWrapperContract(wrapperAddress);
    }
}