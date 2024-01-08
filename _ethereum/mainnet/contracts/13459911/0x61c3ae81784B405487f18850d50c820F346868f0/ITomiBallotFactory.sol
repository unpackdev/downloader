pragma solidity >=0.5.0;

interface ITomiBallotFactory {
    function create(
        address _proposer,
        uint _value,
        uint _endTime,
        uint _executionTime,
        string calldata _subject,
        string calldata _content
    ) external returns (address);

     function createShareRevenue(
        address _proposer,
        uint _endTime,
        uint _executionTime,
        string calldata _subject,
        string calldata _content
    ) external returns (address);
}