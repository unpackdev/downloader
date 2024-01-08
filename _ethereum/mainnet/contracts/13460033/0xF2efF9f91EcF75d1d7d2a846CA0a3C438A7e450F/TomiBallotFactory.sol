// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./TomiBallot.sol";
import "./TomiBallotRevenue.sol";

contract TomiBallotFactory {
    address public TOMI;

    event Created(address indexed proposer, address indexed ballotAddr, uint256 createTime);
    event RevenueCreated(address indexed proposer, address indexed ballotAddr, uint256 createTime);

    constructor(address _TOMI) public {
        TOMI = _TOMI;
    }

    function create(
        address _proposer,
        uint256 _value,
        uint256 _endTime,
        uint256 _executionTime,
        string calldata _subject,
        string calldata _content
    ) external returns (address) {
        require(_value >= 0, 'TomiBallotFactory: INVALID_PARAMTERS');
        address ballotAddr = address(
            new TomiBallot(TOMI, _proposer, _value, _endTime, _executionTime, msg.sender, _subject, _content)
        );
        emit Created(_proposer, ballotAddr, block.timestamp);
        return ballotAddr;
    }

    function createShareRevenue(
        address _proposer,
        uint256 _endTime,
        uint256 _executionTime,
        string calldata _subject,
        string calldata _content
    ) external returns (address) {
        address ballotAddr = address(
            new TomiBallotRevenue(TOMI, _proposer, _endTime, _executionTime, msg.sender, _subject, _content)
        );
        emit RevenueCreated(_proposer, ballotAddr, block.timestamp);
        return ballotAddr;
    }
}
