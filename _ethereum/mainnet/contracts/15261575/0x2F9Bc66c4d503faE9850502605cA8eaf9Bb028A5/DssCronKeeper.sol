// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./KeeperCompatible.sol";
import "./Ownable.sol";
import "./IJob.sol";
import "./IUpkeepRefunder.sol";

interface SequencerLike {
    function numJobs() external view returns (uint256);

    function jobAt(uint256 index) external view returns (address);

    function isMaster(bytes32 network) external view returns (bool);
}

/**
 * @title DssCronKeeper
 * @notice Checks for Maker protocol cron jobs that need work and runs them.
 * Checks if upkeep funding is needed and executes it.
 */
contract DssCronKeeper is KeeperCompatibleInterface, Ownable {
    SequencerLike public sequencer;
    IUpkeepRefunder public upkeepRefunder;
    bytes32 public network;

    event ExecutedJob(address job);

    constructor(address _sequencer, bytes32 _network) {
        setSequencer(_sequencer);
        setNetwork(_network);
    }

    // ACTIONS

    /**
     * @notice Check whether upkeep needs funding or there is a pending job
     */
    function checkUpkeep(bytes calldata)
        external
        override
        returns (bool, bytes memory)
    {
        if (address(upkeepRefunder) != address(0) && upkeepRefunder.shouldRefundUpkeep()) {
            return (true, abi.encodeWithSelector(this.refundUpkeep.selector));
        }
        (address job, bytes memory args) = _getPendingJob();
        if (job != address(0)) {
            return (true, abi.encodeWithSelector(this.runJob.selector, job, args));
        }
        return (false, "");
    }

    /**
     * @notice Execute contract function with arguments
     * @dev Called by the keeper
     */
    function performUpkeep(bytes calldata _performData) external override {
        (bool success, ) = address(this).delegatecall(_performData);
        require(success, "failed to perform upkeep");
    }

    /**
     * @notice Execute cron job with params
     * @dev The IJob work function checks if the job is pending and the network is in turn,
     * otherwise it reverts with an error
     * @param _job Address of the job
     * @param _args Arguments to pass to the job's work function
     */
    function runJob(address _job, bytes memory _args) public {
        IJob(_job).work(network, _args);
        emit ExecutedJob(_job);
    }

    /**
     * @notice Call the associated topup contract to fund the upkeep
     */
    function refundUpkeep() public {
        upkeepRefunder.refundUpkeep();
    }

    // GETTERS

    /**
     * @notice Find a pending job when the network is in turn
     * @return Job address and arguments for the work function
     */
    function _getPendingJob() internal returns (address, bytes memory) {
        if (sequencer.isMaster(network)) {
            for (uint256 i = 0; i < sequencer.numJobs(); i++) {
                address job = sequencer.jobAt(i);
                (bool canWork, bytes memory args) = IJob(job).workable(network);
                if (canWork) return (job, args);
            }
        }
        return (address(0), "no pending jobs");
    }

    // SETTERS

    /**
     * @dev Setting it to zero address will disable the upkeep refunding
     */
    function setUpkeepRefunder(address _upkeepRefunder) external onlyOwner {
        upkeepRefunder = IUpkeepRefunder(_upkeepRefunder);
    }

    function setNetwork(bytes32 _network) public onlyOwner {
        require(_network.length > 0, "invalid network");
        network = _network;
    }

    function setSequencer(address _sequencer) public onlyOwner {
        require(_sequencer != address(0), "invalid sequencer address");
        sequencer = SequencerLike(_sequencer);
    }
}
