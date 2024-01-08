pragma solidity 0.6.12;

import "./Ownable.sol";
import "./Initializable.sol";
import "./SafeMath.sol";
import "./BaseTokenMonetaryPolicy.sol";
import "./BaseTokenOrchestrator.sol";

contract ChainlinkKeeperRebaser is OwnableUpgradeSafe {
    using SafeMath for uint256;

    BaseTokenOrchestrator public orchestrator;
    BaseTokenMonetaryPolicy public policy;

    function initialize()
        public
        initializer
    {
        __Ownable_init();
    }

    function setContracts(address _policy, address _orchestrator) public onlyOwner {
        policy = BaseTokenMonetaryPolicy(_policy);
        orchestrator = BaseTokenOrchestrator(_orchestrator);
    }

    function performUpkeep(bytes calldata performData) external {
        orchestrator.rebase();
    }

    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = policy.inRebaseWindow()
                    && policy.lastRebaseTimestampSec().add(policy.minRebaseTimeIntervalSec()) < now;
        return (upkeepNeeded, performData);
    }
}
