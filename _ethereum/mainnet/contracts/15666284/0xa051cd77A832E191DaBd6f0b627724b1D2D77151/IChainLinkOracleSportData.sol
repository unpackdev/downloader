// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Metadata.sol";
import "./IRegularCompetitionContract.sol";

interface IChainLinkOracleSportData {
    function getPayment() external returns (uint256);

    function requestData(
        string memory _matchId,
        uint256 sportId,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external returns (bytes32);

    function getData(bytes32 _id)
        external
        view
        returns (uint256[] memory, address);

    function checkFulfill(bytes32 _requestId) external view returns (bool);
}
