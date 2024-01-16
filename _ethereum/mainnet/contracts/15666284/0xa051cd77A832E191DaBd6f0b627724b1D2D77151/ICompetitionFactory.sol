// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IRegularCompetitionContract.sol";

interface ICompetitionFactory {
    enum CompetitionType {
        P2PCompetition,
        RegularCompetition,
        GuaranteedCompetition
    }

    struct Entrant {
        uint256 minEntrant;
        uint256 maxEntrant;
    }

    struct Time {
        uint256 startBetTime;
        uint256 endBetTime;
        uint256 scheduledStartMatchTime;
    }

    event UpdateSportManager(address _old, address _new);
    event UpdateOracle(address _old, address _new);
    event UpdateCompetitionFactory(
        address _p2p,
        address _regular,
        address _guarantee
    );
    event UpdateTypeToAddress(CompetitionType _type, address _newAddr);

    function createRegularCompetitionContract(
        address _creator,
        string memory _competitionId,
        Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external returns (address);

    function createP2PCompetitionContract(
        address _creator,
        address _player2,
        uint256 _entryFee,
        uint256 _startBetTime,
        uint256 _startP2PTime,
        uint256 _sportTypeAlias,
        bool _head2head
    ) external returns (address);

    function createNewGuaranteedCompetitionContract(
        address _creator,
        string memory _competitionId,
        Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _sportTypeAlias,
        uint256 _guaranteedFee,
        Entrant memory _entrant,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external returns (address);
}
