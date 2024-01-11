// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ISharedData {
    struct Token {
        address _tokenAddress;
        uint256 _presaleRate;
    }

    struct VestingInfo {
        uint256 _time;
        uint256 _percent;
    }

    struct VestingInfoParams {
        VestingInfo[] _vestingInfo;
    }

    struct IDOParams {
        uint256 _minimumContributionLimit;
        uint256 _maximumContributionLimit;
        uint256 _softCap;
        uint256 _hardCap;
        uint256 _startDepositTime;
        uint256 _endDepositTime;
        uint256 _presaleRate;
        address _tokenAddress;
        address _admin;
        address _manager;
        Token[] _tokens;
        address[] _allowance;
        VestingInfo[] _vestingInfo;
    }
}
