// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IDistributor.sol";
import "./ITokenSalePool.sol";

interface IDistributorFactory {
    function setTokenSalePool(ITokenSalePool _tokenSalePool) external;

    function createDistributor(string calldata _poolID) external;

    function createDistributorWithReleaseInfo(
        string calldata _poolID,
        string[] calldata _campaignIDs,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        IDistributor.TrancheType[] calldata _trancheTypes
    ) external;

    function emergencyWithdraw(
        string calldata _poolID,
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function withdraw(string calldata _poolID, string calldata _campaignID)
        external;

    function withdrawManyCampaigns(
        string calldata _poolID,
        string[] calldata _campaignIDs
    ) external;

    function setReleaseInfo(
        string calldata _poolID,
        string calldata _campaignID,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        IDistributor.TrancheType[] calldata _trancheTypes
    ) external;

    function setReleaseInfoSameInManyCampaigns(
        string calldata _poolID,
        string[] calldata _campaignIDs,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        IDistributor.TrancheType[] calldata _trancheTypes
    ) external;

    function getWithdrawableAmount(
        string calldata _poolID,
        string calldata _campaignID,
        address _user
    ) external view returns (uint256);

    function getWithdrawableAmountManyCampaigns(
        string calldata _poolID,
        string[] calldata _campaignIDs,
        address _user
    ) external view returns (uint256);

    function getWithdrawedAmount(
        string calldata _poolID,
        string calldata _campaignID,
        address _user
    ) external view returns (uint256);

    function getWithdrawedAmountManyCampaigns(
        string calldata _poolID,
        string[] calldata _campaignIDs,
        address _user
    ) external view returns (uint256);

    function getDistributorAddress(string calldata _poolID)
        external
        view
        returns (address);
}
