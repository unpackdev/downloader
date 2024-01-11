// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IDistributor {
    enum TrancheType {
        ONCE,
        LINEAR
    }

    function setReleaseInfo(
        string calldata _campaignID,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        TrancheType[] calldata _trancheTypes
    ) external;

    function withdraw(string calldata _campaignID) external;

    function emergencyWithdraw(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function getWithdrawableAmount(string calldata _campaignID, address _user)
        external
        view
        returns (uint256);

    function getWithdrawedAmount(string calldata _campaignID, address _user)
        external
        view
        returns (uint256);
}
