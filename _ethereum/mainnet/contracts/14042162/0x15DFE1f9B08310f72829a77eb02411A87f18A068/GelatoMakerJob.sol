// SPDX-License-Identifier: UNLICENSED
//solhint-disable compiler-version
pragma solidity 0.8.11;
import "./GelatoBytes.sol";

interface ISequencer {
    struct WorkableJob {
        address job;
        bool canWork;
        bytes args;
    }

    function getNextJobs(
        bytes32 network,
        uint256 startIndex,
        uint256 endIndexExcl
    ) external returns (WorkableJob[] memory);

    function numJobs() external view returns (uint256);
}

contract GelatoMakerJob {
    using GelatoBytes for bytes;

    address public immutable pokeMe;

    constructor(address _pokeMe) {
        pokeMe = _pokeMe;
    }

    //solhint-disable code-complexity
    //solhint-disable function-max-lines
    function checker(
        address _sequencer,
        bytes32 _network,
        uint256 _startIndex,
        uint256 _endIndex
    ) external returns (bool, bytes memory) {
        ISequencer sequencer = ISequencer(_sequencer);
        uint256 numJobs = sequencer.numJobs();

        if (numJobs == 0)
            return (false, bytes("GelatoMakerJob: No jobs listed"));
        if (_startIndex >= numJobs) {
            bytes memory msg1 = bytes.concat(
                "GelatoMakerJob: Only jobs available up to index ",
                _toBytes(numJobs - 1)
            );

            bytes memory msg2 = bytes.concat(
                ", inputted startIndex is ",
                _toBytes(_startIndex)
            );
            return (false, bytes.concat(msg1, msg2));
        }

        uint256 endIndex = _endIndex > numJobs ? numJobs : _endIndex;

        ISequencer.WorkableJob[] memory jobs = ISequencer(_sequencer)
            .getNextJobs(_network, _startIndex, endIndex);

        uint256 numWorkable;
        for (uint256 i; i < jobs.length; i++) {
            if (jobs[i].canWork) numWorkable++;
        }

        if (numWorkable == 0)
            return (false, bytes("GelatoMakerJob: No workable jobs"));

        ISequencer.WorkableJob[]
            memory workableJobs = new ISequencer.WorkableJob[](numWorkable);

        uint256 wIndex;
        for (uint256 i; i < jobs.length; i++) {
            if (jobs[i].canWork) {
                workableJobs[wIndex] = jobs[i];
                wIndex++;
            }
        }

        bytes memory execPayload = abi.encodeWithSelector(
            this.doJobs.selector,
            workableJobs
        );

        return (true, execPayload);
    }

    function doJobs(ISequencer.WorkableJob[] calldata _jobs) external {
        require(msg.sender == pokeMe, "GelatoMakerJob: Only PokeMe");

        for (uint256 i; i < _jobs.length; i++) {
            _doJob(_jobs[i].job, _jobs[i].args);
        }
    }

    function _doJob(address _job, bytes memory _args) internal {
        (bool success, bytes memory returnData) = _job.call(_args);
        if (!success) returnData.revertWithError("GelatoMakerJob: ");
    }

    function _toBytes(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
}
