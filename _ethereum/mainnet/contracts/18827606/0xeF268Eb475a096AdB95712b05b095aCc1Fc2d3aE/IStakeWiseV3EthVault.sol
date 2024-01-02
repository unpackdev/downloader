// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <council@enzyme.finance>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity >=0.6.0 <0.9.0;

/// @title IStakeWiseV3EthVault Interface
/// @author Enzyme Council <security@enzyme.finance>
interface IStakeWiseV3EthVault {
    function calculateExitedAssets(
        address _receiver,
        uint256 _positionTicket,
        uint256 _timestamp,
        uint256 _exitQueueIndex
    ) external view returns (uint256 leftShares_, uint256 claimedShares_, uint256 claimedAssets_);

    function claimExitedAssets(uint256 _positionTicket, uint256 _timestamp, uint256 _exitQueueIndex)
        external
        returns (uint256 newPositionTicket_, uint256 claimedShares_, uint256 claimedAssets_);

    function convertToShares(uint256 _assets) external view returns (uint256 shares_);

    function convertToAssets(uint256 _shares) external view returns (uint256 assets_);

    function deposit(address _receiver, address _referrer) external payable returns (uint256 shares_);

    function enterExitQueue(uint256 _shares, address _receiver) external returns (uint256 positionTicket_);

    function getExitQueueIndex(uint256 _positionTicket) external view returns (int256 exitQueueIndex_);

    function getShares(address _account) external view returns (uint256 shares_);

    function redeem(uint256 _shares, address _receiver) external returns (uint256 assets_);
}
