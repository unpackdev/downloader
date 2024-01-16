// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Metadata.sol";
import "./ICompetitionContract.sol";

interface IRegularCompetitionContract is Metadata {
    struct Competition {
        string competitionId;
        string team1;
        string team2;
        uint256 sportTypeAlias;
        uint256 winnerReward;
        bool resulted;
    }

    struct BetOption {
        Mode mode;
        uint256 attribute;
        string id;
        uint256[] brackets;
    }

    event PlaceBet(address indexed buyer, uint256[] brackets, uint256 fee);
    event RequestData(
        bytes32 indexed _requestId,
        string _competitionId,
        string _queryString
    );

    function oracle() external view returns (address);

    function setBasic(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee,
        uint256 _minEntrant,
        uint256 _scheduledStartTime,
        uint256 _minimumBetime
    ) external returns (bool);

    function start() external;

    function setOracle(address _oracle) external;

    function setCompetition(
        string memory _competitionId,
        string memory _team1,
        string memory _team2,
        uint256 _sportTypeAlias,
        address _sportManager
    ) external;

    function setGapvalidationTime(uint256 _gapTime) external;

    function getDataToCheckRefund() external view returns (bytes32, uint256);

    function getTicketSell(uint256[] memory _brackets)
        external
        view
        returns (address[] memory);

    function setBetOptions(BetOption[] memory _betOptions) external;

    function setIsResult() external;
}
