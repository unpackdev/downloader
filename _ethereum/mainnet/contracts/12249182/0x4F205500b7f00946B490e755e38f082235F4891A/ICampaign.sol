// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1;

import "./IERC20.sol";

interface ICampaign {
    function initialize(string memory _name, IERC20 _token, uint256 _duration, uint256 _openTime, uint256 _releaseTime, uint256 _ethRate, uint256 _ethRateDecimals, address _walletAddress) external;
}