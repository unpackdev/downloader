// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./IERC20.sol";

interface IStETH is IERC20 {
    function submit(address _referral) external payable returns (uint _recievedShares);
}
