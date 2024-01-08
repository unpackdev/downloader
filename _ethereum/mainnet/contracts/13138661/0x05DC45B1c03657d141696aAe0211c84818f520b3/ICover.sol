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

interface ICover {
    function getPremium(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256[] memory rewardPercentages
    )
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256[] memory
        );

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external payable;

    function unlockRewardByController(address owner, address to) external returns (uint256);

    function getRewardAmount() external view returns (uint256);

    function getCoverOwnerRewardAmount(uint256 premiumAmount2Insur, uint256 overwrittenRewardPctg) external view returns (uint256, uint256);

    function getINSURRewardBalanceDetails() external view returns (uint256, uint256);

    function removeINSURRewardBalance(address toAddress, uint256 amount) external;

    function setBuyCoverMaxBlkNumLatency(uint256 numOfBlocks) external;

    function setBuyCoverSigner(address signer, bool enabled) external;
}
