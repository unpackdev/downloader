pragma solidity ^0.5.16;

import "./ChainlinkClient.sol";
import "./SportFeed.sol";
import "./IOracleInstance.sol";
import "./Owned.sol";
import "./Integers.sol";

contract SportFeedOracleInstance is IOracleInstance, Owned {
    using Chainlink for Chainlink.Request;
    using Integers for uint;

    address public sportFeed;
    string public targetName;
    string public targetOutcome;
    string public eventName;

    bool public outcome;
    bool public resolvable;

    bool private forcedOutcome;

    constructor(
        address _owner,
        address _sportFeed,
        string memory _targetName,
        string memory _targetOutcome,
        string memory _eventName
    ) public Owned(_owner) {
        sportFeed = _sportFeed;
        targetName = _targetName;
        targetOutcome = _targetOutcome;
        eventName = _eventName;
    }

    function getOutcome() external view returns (bool) {
        if (forcedOutcome) {
            return outcome;
        } else {
            SportFeed sportFeedOracle = SportFeed(sportFeed);
            return sportFeedOracle.isCompetitorAtPlace(targetName, Integers.parseInt(targetOutcome));
        }
    }

    function setOutcome(bool _outcome) public onlyOwner {
        outcome = _outcome;
        forcedOutcome = true;
    }

    function clearOutcome() public onlyOwner {
        forcedOutcome = false;
    }

    function setResolvable(bool _resolvable) public onlyOwner {
        resolvable = _resolvable;
    }
}
