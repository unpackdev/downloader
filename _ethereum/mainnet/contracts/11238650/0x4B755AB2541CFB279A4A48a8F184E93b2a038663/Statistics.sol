//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.6.10;

import "./ReentrancyGuard.sol";

contract StatisticsDataStructure {
    uint public lastFilledWeek;
    uint public startWeek;

    mapping (uint => Datapoint) weeklyData;
    struct Datapoint {
        uint deaths;
        uint infections;
        bool filled;
    }
    event WeeklyData (uint deaths, uint infections, uint weekId);

    constructor (uint deaths, uint infections) public {
        lastFilledWeek = block.timestamp / 1 weeks;
        startWeek = block.timestamp / 1 weeks;

        pushWeeklyData(getCurrentWeek(), deaths, infections);
    }

    function pushWeeklyData (uint weekId, uint deaths, uint infections) internal {
        Datapoint storage target = weeklyData[weekId];

        require(target.filled == false, "target week is already filled");
        
        target.deaths = deaths;
        target.infections = infections;
        target.filled = true;

        lastFilledWeek = weekId;

        emit WeeklyData(deaths, infections, weekId);
    }

    function getCurrentWeek () public view returns (uint) {
        return block.timestamp / 1 weeks;
    }

    function getNextWeek () public view returns (uint) {
        return lastFilledWeek + 1;
    }

    function getWeeklyData (uint weekId) verifyWeekId(weekId) public view returns (uint deaths, uint infections) {
        require(weeklyData[weekId].filled == true, "No data for selected week");
        return (weeklyData[weekId].deaths, weeklyData[weekId].infections);
    }

    modifier verifyWeekId (uint weekId) {
        require(weekId >= startWeek, "No data recorded for given weekId");
        require(weekId <= getCurrentWeek(), "weekId bigger than recorded weeklyData");
        _;
    }
}

contract SignableStatistics is StatisticsDataStructure {
    address signerOne;
    address signerTwo;

    bool public signerOneApproval;
    bool public signerTwoApproval;

    uint public proposedDeaths;
    uint public proposedInfections;
    uint public proposedWeek;


    function resetApproval () private {
        signerOneApproval = false;
        signerTwoApproval = false;
    }

    constructor (
        address _signerOne,
        address _signerTwo,
        uint thisWeeksDeaths,
        uint thisWeeksInfections
    ) StatisticsDataStructure(
        thisWeeksDeaths,
        thisWeeksInfections
    ) public {
        signerOne = _signerOne;
        signerTwo = _signerTwo;
    }

    function pushProposal () public isApproved {
        pushWeeklyData(proposedWeek, proposedDeaths, proposedInfections);
        _clearProposal();
    }

    function propose (uint _proposedDeaths, uint _proposedInfections) isSigner public {
        uint nextWeek = getNextWeek();

        require(lastFilledWeek < nextWeek, "Data for this week has already been recorded");
        require(getCurrentWeek() >= nextWeek, "Suggested data is for a date later than the current date");

        resetApproval();

        proposedDeaths = _proposedDeaths;
        proposedInfections = _proposedInfections;
        proposedWeek = nextWeek;
    }

    function clearProposal () isSigner public {
        _clearProposal();
    }
    function _clearProposal () isSigner private {
        proposedDeaths = 0;
        proposedInfections = 0;
        proposedWeek = 0;
        signerOneApproval = false;
        signerTwoApproval = false;
    }

    function approve () public {
        bool success;

        if (msg.sender == signerOne) {
            success = true;
            signerOneApproval = true;
        }
        if (msg.sender == signerTwo) {
           success = true;
           signerTwoApproval = true;
        }

        require(success, 'Not authorized');
    }

    modifier isApproved () {
        bool success;

        if (signerOneApproval == true && signerTwoApproval == true) {
            success = true;
        }
        require(success, "Not everybody has approved the proposed values");
        _;
    }

    modifier isSigner () {
        bool isIndeedSigner;
        if (msg.sender == signerOne || msg.sender == signerTwo) {
            isIndeedSigner = true;
        }
        require(isIndeedSigner, "");
        _;
    }
}
