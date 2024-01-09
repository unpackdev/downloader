/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

// solhint-disable-next-line no-empty-blocks
interface IRewardController {
    function insur() external returns (address);

    function stakingController() external returns (address);

    function vestingDuration() external view returns (uint256);

    function vestingVestingAmountPerAccount(address _account) external view returns (uint256);

    function vestingStartBlockPerAccount(address _account) external view returns (uint256);

    function vestingEndBlockPerAccount(address _account) external view returns (uint256);

    function vestingWithdrawableAmountPerAccount(address _account) external view returns (uint256);

    function vestingWithdrawedAmountPerAccount(address _account) external view returns (uint256);

    function unlockReward(
        address[] memory _tokenList,
        bool _bBuyCoverUnlockedAmt,
        bool _bClaimUnlockedAmt,
        bool _bReferralUnlockedAmt
    ) external;

    function getRewardInfo() external view returns (uint256, uint256);

    function withdrawReward(uint256 _amount) external;
}
