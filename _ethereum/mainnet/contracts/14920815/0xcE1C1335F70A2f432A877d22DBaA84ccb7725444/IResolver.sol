// SPDX-FileCopyrightText: 2021 Tenderize <info@tenderize.me>

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

interface IResolver {
     function rebaseChecker (address _tenderizer) 
        external
        view
    returns (bool canExec, bytes memory execPayload);

    function register(
        string memory _name,
        address _tenderizer,
        IERC20 _steak,
        address _stakingContract,
        uint256 _depositInterval,
        uint256 _depositThreshold,
        uint256 _rebaseInternval,
        uint256 _rebaseThreshold
    ) external;

    function setGov(address _gov) external;

    function claimRewardsExecutor(address _tenderizer) external ;
}